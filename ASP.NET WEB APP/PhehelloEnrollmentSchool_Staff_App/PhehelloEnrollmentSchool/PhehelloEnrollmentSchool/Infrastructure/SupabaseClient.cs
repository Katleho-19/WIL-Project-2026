//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: SupabaseClient.cs is the low-level client for the Supabase REST (PostgREST) and Storage APIs.
// All repositories use it. It attaches the signed-in staff member's own access token to each request so the database's
// Row Level Security decides what that person may see or change.

using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    // SupabaseClient (class) - sends HTTP requests to Supabase; see the notes above.
    /// <summary>
    /// Thin client for the Supabase REST (PostgREST) and Storage APIs.
    /// Every request is sent with the signed-in staff member's own access token, so the
    /// database's Row Level Security decides what that user may read or change
    /// (Financial Clerk vs Administrator - SRS NFR1 / NFR6). No service-role key is used.
    /// </summary>
    public sealed class SupabaseClient
    {
        /// <summary>
        /// _http - the HTTP client used to send requests.
        /// </summary>
        private readonly HttpClient _http;
        /// <summary>
        /// _options - the Supabase settings (URL, key, bucket).
        /// </summary>
        private readonly SupabaseOptions _options;
        /// <summary>
        /// _context - gives access to the current web request so the user's access token can be read.
        /// </summary>
        private readonly IHttpContextAccessor _context;
        /// <summary>
        /// _logger - writes log messages.
        /// </summary>
        private readonly ILogger<SupabaseClient> _logger;

        /// <summary>Reads snake_case JSON into PascalCase C# properties.</summary>
        public static readonly JsonSerializerOptions ReadJson = new()
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
            PropertyNameCaseInsensitive = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString
        };

        /// <summary>
        /// WriteJson - the default settings used when turning C# objects into JSON to send.
        /// </summary>
        private static readonly JsonSerializerOptions WriteJson = new();

        /// <summary>
        /// Constructor - receives the HTTP client, settings, request accessor and logger from dependency injection.
        /// </summary>
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

        /// <summary>
        /// Bucket - the storage bucket name from the settings.
        /// </summary>
        public string Bucket => _options.Bucket;

        // ------------------------------------------------------------------ REST

        // SelectAsync() - reads rows from a table (GET). It builds the request with the user's token, checks the response and converts the returned JSON into a list of T.
        // An optional accessToken can be supplied instead of the one from the current request.
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

        // DownloadAsync() - downloads a private file from Storage using the user's token. Returns its bytes and content type, or null (and a log warning) if the file does not exist.
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

        /// <summary>
        /// UploadAsync() - uploads a file to the storage bucket at the given path. 'upsert' says whether an existing file may be overwritten. Throws if the upload fails.
        /// </summary>
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

        /// <summary>
        /// Eq() - builds a filter text such as "column=eq.value" with the value URL-encoded; used in query strings.
        /// </summary>
        public static string Eq(string column, object value) =>
            $"{column}=eq.{Uri.EscapeDataString(Convert.ToString(value, System.Globalization.CultureInfo.InvariantCulture) ?? "")}";

        /// <summary>
        /// EncodePath() - URL-encodes each part of a storage path while keeping the slashes.
        /// </summary>
        private static string EncodePath(string path) =>
            string.Join('/', path.Split('/', StringSplitOptions.RemoveEmptyEntries).Select(Uri.EscapeDataString));

        /// <summary>
        /// JsonBody() - turns an object into a JSON request body (UTF-8, application/json).
        /// </summary>
        private static StringContent JsonBody(object body) =>
            new(JsonSerializer.Serialize(body, WriteJson), Encoding.UTF8, "application/json");

        /// <summary>
        /// Build() - creates a request with the public API key and the user's bearer token (taken from the parameter or from the current request's claims).
        /// If there is no token it throws a 401 SupabaseApiException.
        /// </summary>
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

        /// <summary>
        /// EnsureSuccessAsync() - does nothing for a successful response. Otherwise it reads the error body, extracts the error code and message when it is JSON (or keeps the raw text),
        /// logs a warning and throws a SupabaseApiException with the status code, code and detail.
        /// </summary>
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