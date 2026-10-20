using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using PhehelloEnrollmentSchool.Models;
using PhehelloEnrollmentSchool.Services;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    public static class StaffPrincipal
    {
        /// <summary>Builds the cookie identity for a verified staff member.</summary>
        public static ClaimsPrincipal Create(AuthSession session, ProfileRow profile)
        {
            var name = string.IsNullOrWhiteSpace(profile.FullName) ? session.Email : profile.FullName!;
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, session.UserId.ToString()),
                new(ClaimTypes.Name, name),
                new(ClaimTypes.Email, session.Email),
                new(ClaimTypes.Role, profile.Role ?? ""),
            };
            claims.AddRange(TokenClaims(session));

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            return new ClaimsPrincipal(identity);
        }

        public static IEnumerable<Claim> TokenClaims(AuthSession session)
        {
            yield return new Claim(SessionClaims.AccessToken, session.AccessToken);
            yield return new Claim(SessionClaims.RefreshToken, session.RefreshToken);
            yield return new Claim(SessionClaims.ExpiresAt, session.ExpiresAtUnix.ToString());
        }

        public static string HomeFor(string? role) => role switch
        {
            StaffRoles.Administrator => "/Admin/Dashboard",
            StaffRoles.FinancialClerk => "/Clerk/Dashboard",
            _ => "/Account/Login"
        };
    }

    /// <summary>
    /// Keeps the Supabase access token fresh. Access tokens last about an hour; this refreshes
    /// them in the background (using the refresh token) so staff are not signed out mid-task.
    /// </summary>
    public sealed class SupabaseCookieEvents : CookieAuthenticationEvents
    {
        private readonly SupabaseAuthService _auth;
        private readonly ILogger<SupabaseCookieEvents> _logger;

        public SupabaseCookieEvents(SupabaseAuthService auth, ILogger<SupabaseCookieEvents> logger)
        {
            _auth = auth;
            _logger = logger;
        }

        public override async Task ValidatePrincipal(CookieValidatePrincipalContext context)
        {
            var principal = context.Principal;
            var expires = principal?.FindFirstValue(SessionClaims.ExpiresAt);
            var refresh = principal?.FindFirstValue(SessionClaims.RefreshToken);

            if (principal == null || !long.TryParse(expires, out var expiresAt) || string.IsNullOrEmpty(refresh))
            {
                await Reject(context);
                return;
            }

            // Still comfortably valid.
            if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() < expiresAt - 60) return;

            try
            {
                var session = await _auth.RefreshAsync(refresh, context.HttpContext.RequestAborted);

                var identity = new ClaimsIdentity(
                    principal.Claims.Where(c =>
                        c.Type != SessionClaims.AccessToken &&
                        c.Type != SessionClaims.RefreshToken &&
                        c.Type != SessionClaims.ExpiresAt),
                    principal.Identity?.AuthenticationType);
                identity.AddClaims(StaffPrincipal.TokenClaims(session));

                context.ReplacePrincipal(new ClaimsPrincipal(identity));
                context.ShouldRenew = true;
            }
            catch (Exception ex) when (ex is SupabaseAuthException or HttpRequestException)
            {
                _logger.LogInformation("Session refresh failed; signing the user out ({Type}).", ex.GetType().Name);
                await Reject(context);
            }
        }

        private static async Task Reject(CookieValidatePrincipalContext context)
        {
            context.RejectPrincipal();
            await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        }
    }
}
