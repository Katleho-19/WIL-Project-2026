namespace PhehelloEnrollmentSchool.Models
{
    /// <summary>Thrown when Supabase Auth rejects a request (bad credentials, expired token, ...).</summary>
    public sealed class SupabaseAuthException : Exception
    {
        public int StatusCode { get; }

        /// <summary>Supabase error_code, e.g. invalid_credentials, email_not_confirmed.</summary>
        public string? ErrorCode { get; }

        public SupabaseAuthException(int statusCode, string? errorCode = null)
            : base("Supabase authentication request failed.")
        {
            StatusCode = statusCode;
            ErrorCode = errorCode;
        }
    }

    /// <summary>Thrown when the Supabase REST / Storage API rejects a data request.</summary>
    public sealed class SupabaseApiException : Exception
    {
        public int StatusCode { get; }
        public string? Code { get; }

        /// <summary>A message that is safe and useful to show to staff.</summary>
        public string UserMessage { get; }

        public SupabaseApiException(int statusCode, string? code, string detail)
            : base($"Supabase request failed ({statusCode} {code}): {detail}")
        {
            StatusCode = statusCode;
            Code = code;
            UserMessage = statusCode switch
            {
                401 => "Your session has expired. Please sign in again.",
                403 => PermissionMessage,
                _ when code == "42501" => PermissionMessage,
                _ when code == "23505" => "That record already exists.",
                _ when code is "23514" or "23502" or "23503" =>
                    "The database rejected this change (a rule or required value was not met).",
                404 => "The requested file or record could not be found.",
                _ => "The database could not complete the request. Please try again."
            };
        }

        public const string PermissionMessage =
            "The database did not allow this action for your role. " +
            "If it should be allowed, run supabase/staff_access_patch.sql in the Supabase SQL Editor.";
    }
}
