using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Services
{
    public sealed record AuthSession(
        string AccessToken,
        string RefreshToken,
        long ExpiresAtUnix,
        Guid UserId,
        string Email);

    /// <summary>Supabase Auth (GoTrue) calls: sign in, refresh, sign out, password recovery.</summary>
    public sealed class SupabaseAuthService
    {
        private readonly HttpClient _http;
        private readonly SupabaseOptions _options;

        public SupabaseAuthService(HttpClient http, IOptions<SupabaseOptions> options)
        {
            _http = http;
            _options = options.Value;
        }

        public async Task<AuthSession> LoginAsync(string email, string password, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/token?grant_type=password", new { email, password }, null, ct);
            return ReadSession(doc.RootElement, email);
        }

        public async Task<AuthSession> RefreshAsync(string refreshToken, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/token?grant_type=refresh_token",
                new { refresh_token = refreshToken }, null, ct);
            return ReadSession(doc.RootElement, "");
        }

        public async Task LogoutAsync(string accessToken, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/logout", new { }, accessToken, ct);
        }

        public async Task RecoverAsync(string email, CancellationToken ct = default)
        {
            using var doc = await PostAsync("auth/v1/recover", new { email }, null, ct);
        }

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
