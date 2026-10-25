//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: StaffSignIn.cs builds the login cookie identity for a verified staff member and keeps the
// Supabase access token fresh by refreshing it in the background, so staff are not signed out in the middle of a task.

using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using PhehelloEnrollmentSchool.Models;
using PhehelloEnrollmentSchool.Services;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>
    /// StaffPrincipal (class) - helpers that create the cookie identity.
    /// </summary>
    public static class StaffPrincipal
    {
        // Create() - builds the identity stored in the login cookie: id, display name (the profile name, or the email if the name is empty), email, role,
        // and the three Supabase token claims.
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

        /// <summary>
        /// TokenClaims() - produces the three claims that carry the Supabase session: access token, refresh token and expiry time.
        /// </summary>
        public static IEnumerable<Claim> TokenClaims(AuthSession session)
        {
            yield return new Claim(SessionClaims.AccessToken, session.AccessToken);
            yield return new Claim(SessionClaims.RefreshToken, session.RefreshToken);
            yield return new Claim(SessionClaims.ExpiresAt, session.ExpiresAtUnix.ToString());
        }

        /// <summary>
        /// HomeFor() - returns the home page of a role: /Admin/Dashboard, /Clerk/Dashboard, or the login page for anyone else.
        /// </summary>
        public static string HomeFor(string? role) => role switch
        {
            StaffRoles.Administrator => "/Admin/Dashboard",
            StaffRoles.FinancialClerk => "/Clerk/Dashboard",
            _ => "/Account/Login"
        };
    }

    // SupabaseCookieEvents (class) - cookie events that run on every request to keep the Supabase token valid.
    /// <summary>
    /// Keeps the Supabase access token fresh. Access tokens last about an hour; this refreshes
    /// them in the background (using the refresh token) so staff are not signed out mid-task.
    /// </summary>
    public sealed class SupabaseCookieEvents : CookieAuthenticationEvents
    {
        /// <summary>
        /// _auth - the service used to refresh the token.
        /// </summary>
        private readonly SupabaseAuthService _auth;
        /// <summary>
        /// _logger - writes log messages.
        /// </summary>
        private readonly ILogger<SupabaseCookieEvents> _logger;

        /// <summary>
        /// Constructor - receives the auth service and the logger from dependency injection.
        /// </summary>
        public SupabaseCookieEvents(SupabaseAuthService auth, ILogger<SupabaseCookieEvents> logger)
        {
            _auth = auth;
            _logger = logger;
        }

        /// <summary>
        /// ValidatePrincipal() - runs when the cookie is checked. It reads the expiry time and refresh token from the claims; if either is missing the user is signed out.
        /// If the token is still valid for more than 60 seconds nothing happens. Otherwise it asks Supabase for a new session with the refresh token, replaces the token claims in
        /// the cookie and asks for the cookie to be renewed. If the refresh fails the user is signed out.
        /// </summary>
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

        /// <summary>
        /// Reject() - invalidates the current cookie and signs the user out.
        /// </summary>
        private static async Task Reject(CookieValidatePrincipalContext context)
        {
            context.RejectPrincipal();
            await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        }
    }
}