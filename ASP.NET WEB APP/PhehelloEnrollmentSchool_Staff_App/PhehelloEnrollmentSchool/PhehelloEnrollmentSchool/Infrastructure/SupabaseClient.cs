using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>
    /// Thin client for the Supabase REST (PostgREST) and Storage APIs.
    /// Every request is sent with the signed-in staff member's own access token, so the
    /// database's Row Level Security decides what that user may read or change
    /// (Financial Clerk vs Administrator - SRS NFR1 / NFR6). No service-role key is used.
    /// </summary>
    public sealed class SupabaseClient
    {
        private readonly HttpClient _http;
        private readonly SupabaseOptions _options;
        private readonly IHttpContextAccessor _context;
        private readonly ILogger<SupabaseClient> _logger;

        /// <summary>Reads snake_case JSON into PascalCase C# properties.</summary>
        public static readonly JsonSerializerOptions ReadJson = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
            PropertyNameCaseInsensitive = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString
        };

        private static readonly JsonSerializerOptions WriteJson = new();

        public SupabaseClient(
            HttpClient http,
            IOptions<SupabaseOptions> options,
            IHttpContextAccessor context,
            ILogger<SupabaseClient> logger)
        {
            _http = http;
            _options = options.Value;
            _context = context;
            _logger = logger;
        }

        public string Bucket => _options.Bucket;

        // ------------------------------------------------------------------ REST

        /// <summary>GET /rest/v1/{table}?{query}. <paramref name="query"/> must already be URL-encoded.</summary>
        public async Task<List<T>> SelectAsync<T>(string table, string query, CancellationToken ct = default, string? accessToken = null)
        {
            using var request = Build(HttpMethod.Get, $"{_options.BaseUrl}/rest/v1/{table}?{query}", accessToken);
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            using var response = await _http.SendAsync(request, ct);
            await EnsureSuccessAsync(response, table);

            var json = await response.Content.ReadAsStringAsync(ct);
            return JsonSerializer.Deserialize<List<T>>(json, ReadJson) ?? new List<T>();
        }

        /// <summary>
        /// Inserts one row (or an array of rows). Uses return=minimal on purpose: asking PostgREST to
        /// return the inserted row makes Row Level Security also check the SELECT policy, which would
        /// wrongly fail when staff insert rows they are not allowed to read back (e.g. a parent's
        /// notification). Pass <paramref name="onConflict"/> to upsert on a unique column.
        /// </summary>
        public async Task InsertAsync(string table, object body, string? onConflict = null, CancellationToken ct = default)
        {
            var url = $"{_options.BaseUrl}/rest/v1/{table}";
            if (onConflict != null) url += $"?on_conflict={Uri.EscapeDataString(onConflict)}";

            using var request = Build(HttpMethod.Post, url);
            request.Headers.Add("Prefer", onConflict != null
                ? "return=minimal,resolution=merge-duplicates"
                : "return=minimal");
            request.Content = JsonBody(body);

            using var response = await _http.SendAsync(request, ct);
            await EnsureSuccessAsync(response, table);
        }

        /// <summary>
        /// PATCH rows matching <paramref name="filter"/> (already encoded, e.g. "application_id=eq.123").
        /// Returns the updated rows. NOTE: when Row Level Security hides the row, PostgREST answers
        /// 200 with an empty list instead of an error, so callers must check the result.
        /// </summary>
        public async Task<List<T>> UpdateAsync<T>(string table, string filter, object body, CancellationToken ct = default)
        {
            using var request = Build(new HttpMethod("PATCH"), $"{_options.BaseUrl}/rest/v1/{table}?{filter}");
            request.Headers.Add("Prefer", "return=representation");
            request.Content = JsonBody(body);

            using var response = await _http.SendAsync(request, ct);
            await EnsureSuccessAsync(response, table);

            var json = await response.Content.ReadAsStringAsync(ct);
            return JsonSerializer.Deserialize<List<T>>(json, ReadJson) ?? new List<T>();
        }

        // --------------------------------------------------------------- Storage

        /// <summary>Downloads a private file. Returns null when it does not exist.</summary>
        public async Task<(byte[] Bytes, string ContentType)?> DownloadAsync(string objectPath, CancellationToken ct = default)
        {
            var url = $"{_options.BaseUrl}/storage/v1/object/authenticated/{_options.Bucket}/{EncodePath(objectPath)}";
            using var request = Build(HttpMethod.Get, url);
            using var response = await _http.SendAsync(request, ct);

            if (response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.BadRequest)
            {
                _logger.LogWarning("Storage object not found: {Path}", objectPath);
                return null;
            }

            await EnsureSuccessAsync(response, "storage");
            var bytes = await response.Content.ReadAsByteArrayAsync(ct);
            var type = response.Content.Headers.ContentType?.MediaType ?? "application/octet-stream";
            return (bytes, type);
        }

        public async Task UploadAsync(string objectPath, byte[] bytes, string contentType, bool upsert, CancellationToken ct = default)
        {
            var url = $"{_options.BaseUrl}/storage/v1/object/{_options.Bucket}/{EncodePath(objectPath)}";
            using var request = Build(HttpMethod.Post, url);
            request.Headers.Add("x-upsert", upsert ? "true" : "false");
            request.Content = new ByteArrayContent(bytes);
            request.Content.Headers.ContentType = new MediaTypeHeaderValue(contentType);

            using var response = await _http.SendAsync(request, ct);
            await EnsureSuccessAsync(response, "storage");
        }

        // --------------------------------------------------------------- helpers

        public static string Eq(string column, object value) =>
            $"{column}=eq.{Uri.EscapeDataString(Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture) ?? "")}";

        private static string EncodePath(string path) =>
            string.Join('/', path.Split('/', StringSplitOptions.RemoveEmptyEntries).Select(Uri.EscapeDataString));

        private static StringContent JsonBody(object body) =>
            new(JsonSerializer.Serialize(body, WriteJson), Encoding.UTF8, "application/json");

        private HttpRequestMessage Build(HttpMethod method, string url, string? accessToken = null)
        {
            var token = accessToken ?? _context.HttpContext?.User.FindFirst(SessionClaims.AccessToken)?.Value;
            if (string.IsNullOrWhiteSpace(token))
                throw new SupabaseApiException(401, null, "No access token on the current request.");

            var request = new HttpRequestMessage(method, url);
            request.Headers.Add("apikey", _options.PublishableKey);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return request;
        }

        private async Task EnsureSuccessAsync(HttpResponseMessage response, string what)
        {
            if (response.IsSuccessStatusCode) return;

            var body = await response.Content.ReadAsStringAsync();
            string? code = null;
            string detail = body;
            try
            {
                using var doc = JsonDocument.Parse(body);
                var root = doc.RootElement;
                if (root.TryGetProperty("code", out var c)) code = c.ToString();
                else if (root.TryGetProperty("statusCode", out var sc)) code = sc.ToString();
                if (root.TryGetProperty("message", out var m)) detail = m.ToString();
                else if (root.TryGetProperty("error", out var e)) detail = e.ToString();
            }
            catch (JsonException) { /* body was not JSON; keep raw text */ }

            // PostgREST reports an expired token as 401 / PGRST303.
            var status = (int)response.StatusCode;
            var ex = new SupabaseApiException(status, code, detail);
            _logger.LogWarning("Supabase {What} request failed: {Message}", what, ex.Message);
            throw ex;
        }
    }
}
