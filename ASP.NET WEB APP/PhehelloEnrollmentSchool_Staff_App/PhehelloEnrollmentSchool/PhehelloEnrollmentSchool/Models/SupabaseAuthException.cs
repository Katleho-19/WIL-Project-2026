//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: SupabaseAuthException.cs defines the two custom exceptions used when talking to Supabase:
// one for sign-in/authentication failures and one for data (REST / Storage) failures with a friendly message for staff.

namespace PhehelloEnrollmentSchool.Models
{
    /// <summary>Thrown when Supabase Auth rejects a request (bad credentials, expired token, ...).</summary>
    public sealed class SupabaseAuthException : Exception
    {
        /// <summary>
        /// StatusCode - the HTTP status code returned by Supabase.
        /// </summary>
        public int StatusCode { get; }

        /// <summary>Supabase error_code, e.g. invalid_credentials, email_not_confirmed.</summary>
        public string? ErrorCode { get; }

        /// <summary>
        /// Constructor - stores the HTTP status code and the optional Supabase error code and sets a fixed general error message.
        /// </summary>
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
        /// <summary>
        /// StatusCode - the HTTP status code returned by Supabase.
        /// </summary>
        public int StatusCode { get; }
        /// <summary>
        /// Code - the database/PostgREST error code (for example 42501 or 23505), if any.
        /// </summary>
        public string? Code { get; }

        /// <summary>A message that is safe and useful to show to staff.</summary>
        public string UserMessage { get; }

        /// <summary>
        /// Constructor - stores the status and error code, builds the technical message for the logs and chooses the friendly UserMessage:
        /// 401 = session expired; 403 or code 42501 = the role is not allowed (run the SQL patch); 23505 = record already exists;
        /// 23514, 23502 or 23503 = a database rule was not met; 404 = not found; anything else = a general "try again" message.
        /// </summary>
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

        /// <summary>
        /// PermissionMessage - the standard message shown when the database refuses an action for the user's role.
        /// </summary>
        public const string PermissionMessage =
            "The database did not allow this action for your role. " +
            "If it should be allowed, run supabase/staff_access_patch.sql in the Supabase SQL Editor.";
    }
}