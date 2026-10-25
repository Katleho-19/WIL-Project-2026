//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: SupabaseAuthService.cs talks to Supabase Auth (GoTrue) for staff sign-in: logging in with email and password,
// refreshing an expired access token, logging out and sending a password-recovery email.

using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Services
{
    /// <summary>
    /// AuthSession (record) - the result of a successful sign-in or refresh: access token, refresh token, expiry time (Unix seconds), user id and email.
    /// </summary>
    public sealed record AuthSession(
        string AccessToken,
        string RefreshToken,
        long ExpiresAtUnix,
        Guid UserId,
        string Email);

    /// <summary>Supabase Auth (GoTrue) calls: sign in, refresh, sign out, password recovery.</summary>
    public sealed class SupabaseAuthService
    {
        /// <summary>
        /// _http - the HTTP client used for the Auth requests.
        /// </summary>
        private readonly HttpClient _http;
        /// <summary>
        /// _options - the Supabase settings (URL and public key).
        /// </summary>
        private readonly SupabaseOptions _options;

        /// <summary>
        /// Constructor - receives the HTTP client and the Supabase settings from dependency injection.
        /// </summary>
        public SupabaseAuthService(HttpClient http, IOptions<SupabaseOptions> options)
        {
            _http = http;
            _options = options.Value;
        }

        /// <summary>
        /// LoginAsync() - signs in with email and password (password grant) and returns the new session. Throws SupabaseAuthException if Supabase rejects the login.
        /// </summary>
        public async Task<AuthSession> LoginAsync(string email, string password, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/token?grant_type=password", new { email, password }, null, ct);
            return ReadSession(doc.RootElement, email);
        }

        /// <summary>
        /// RefreshAsync() - exchanges a refresh token for a new session (used by the cookie events when the access token is about to expire).
        /// </summary>
        public async Task<AuthSession> RefreshAsync(string refreshToken, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/token?grant_type=refresh_token",
                new { refresh_token = refreshToken }, null, ct);
            return ReadSession(doc.RootElement, "");
        }

        /// <summary>
        /// LogoutAsync() - tells Supabase to end the session that belongs to the given access token.
        /// </summary>
        public async Task LogoutAsync(string accessToken, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/logout", new { }, accessToken, ct);
        }

        /// <summary>
        /// RecoverAsync() - asks Supabase to send a password-recovery email to the address.
        /// </summary>
        public async Task RecoverAsync(string email, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/recover", new { email }, null, ct);
        }

        /// <summary>
        /// ReadSession() - reads the JSON answer: it requires the access token, refresh token and user id (otherwise it throws an invalid_response error), works out the expiry time
        /// from expires_at or from expires_in plus the current time, and uses the email in the answer or the fallback email. Returns an AuthSession.
        /// </summary>
        private static AuthSession ReadSession(JsonElement root, string fallbackEmail)
        {
            if (!root.TryGetProperty("access_token", out var tokenEl) ||
                !root.TryGetProperty("refresh_token", out var refreshEl) ||
                !root.TryGetProperty("user", out var userEl) ||
                !userEl.TryGetProperty("id", out var idEl))
            {
                throw new SupabaseAuthException(500, "invalid_response");
            }

            var access = tokenEl.GetString();
            var refresh = refreshEl.GetString();
            if (string.IsNullOrWhiteSpace(access) || string.IsNullOrWhiteSpace(refresh) ||
                !Guid.TryParse(idEl.GetString(), out var userId))
            {
                throw new SupabaseAuthException(500, "invalid_response");
            }

            long expiresAt;
            if (root.TryGetProperty("expires_at", out var expAt) && expAt.TryGetInt64(out var e))
                expiresAt = e;
            else if (root.TryGetProperty("expires_in", out var expIn) && expIn.TryGetInt64(out var s))
                expiresAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds() + s;
            else
                throw new SupabaseAuthException(500, "invalid_response");

            var email = userEl.TryGetProperty("email", out var em) ? em.GetString() ?? fallbackEmail : fallbackEmail;
            return new AuthSession(access, refresh, expiresAt, userId, email);
        }

        /// <summary>
        /// PostAsync() - sends a JSON POST request to a Supabase Auth endpoint with the public key (and an optional bearer token). It throws if the settings are missing. If Supabase answers
        /// with an error status it reads the error_code from the body (when it is JSON) and throws SupabaseAuthException; otherwise it returns the parsed JSON (an empty object if the body is empty).
        /// </summary>
        private async Task<JsonDocument> PostAsync(string endpoint, object payload, string? bearer, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(_options.Url) || string.IsNullOrWhiteSpace(_options.PublishableKey))
                throw new InvalidOperationException("Supabase:Url / Supabase:PublishableKey are not configured.");

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_options.BaseUrl}/{endpoint}");
            request.Headers.Add("apikey", _options.PublishableKey);
            if (bearer != null)
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", bearer);
            request.Content = JsonContent.Create(payload);

            using var response = await _http.SendAsync(request, ct);
            var body = await response.Content.ReadAsStringAsync(ct);

            if (!response.IsSuccessStatusCode)
            {
                string? code = null;
                try
                {
                    using var err = JsonDocument.Parse(body);
                    if (err.RootElement.TryGetProperty("error_code", out var c)) code = c.GetString();
                }
                catch (JsonException) { }
                throw new SupabaseAuthException((int)response.StatusCode, code);
            }

            return JsonDocument.Parse(string.IsNullOrWhiteSpace(body) ? "{}" : body);
        }
    }
}