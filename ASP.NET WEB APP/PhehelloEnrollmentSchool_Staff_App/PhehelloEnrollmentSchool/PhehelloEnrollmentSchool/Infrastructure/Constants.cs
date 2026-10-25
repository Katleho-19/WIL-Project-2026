//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: Constants.cs holds the fixed text values shared across the web app: role names, authorization
// policy names, the names of the claims stored in the login cookie, and the status and notification vocabularies
// (these must match the database and the Flutter app exactly).

namespace PhehelloEnrollmentSchool.Infrastructure
{
    // StaffRoles (class) - the two staff role names exactly as stored in profiles.role.
    /// <summary>Role names exactly as stored in profiles.role (SRS ERD).</summary>
    public static class StaffRoles
    {
        /// <summary>
        /// Administrator - the role of the school administrator.
        /// </summary>
        public const string Administrator = "Administrator";
        /// <summary>
        /// FinancialClerk - the role of the financial clerk.
        /// </summary>
        public const string FinancialClerk = "Financial Clerk";

        /// <summary>
        /// IsStaff() - returns true if the given role is Administrator or Financial Clerk (parents and unknown roles return false).
        /// </summary>
        public static bool IsStaff(string? role) =>
            role == Administrator || role == FinancialClerk;
    }

    /// <summary>
    /// Policies (class) - the names of the authorization policies registered in Program.cs.
    /// </summary>
    public static class Policies
    {
        /// <summary>
        /// Administrator - the policy that allows only the Administrator role.
        /// </summary>
        public const string Administrator = "AdministratorOnly";
        /// <summary>
        /// FinancialClerk - the policy that allows only the Financial Clerk role.
        /// </summary>
        public const string FinancialClerk = "FinancialClerkOnly";
    }

    // SessionClaims (class) - the custom claim names used to keep the Supabase session inside the login cookie.
    /// <summary>Custom claim names used to carry the Supabase session inside the auth cookie.</summary>
    public static class SessionClaims
    {
        /// <summary>
        /// AccessToken - claim holding the Supabase access token (about one hour).
        /// </summary>
        public const string AccessToken = "sb_access_token";
        /// <summary>
        /// RefreshToken - claim holding the refresh token used to get a new access token.
        /// </summary>
        public const string RefreshToken = "sb_refresh_token";
        /// <summary>
        /// ExpiresAt - claim holding the access token's expiry time (Unix seconds).
        /// </summary>
        public const string ExpiresAt = "sb_expires_at";
    }

    // AppStatus (class) - the possible values of applications.status.
    /// <summary>applications.status vocabulary (live schema CHECK constraint + Flutter app).</summary>
    public static class AppStatus
    {
        /// <summary>
        /// Draft - saved but not submitted.
        /// </summary>
        public const string Draft = "Draft";
        /// <summary>
        /// PendingPayment - waiting for the Financial Clerk to verify the payment.
        /// </summary>
        public const string PendingPayment = "Pending Payment Verification";
        /// <summary>
        /// Pending - waiting for the Administrator's review.
        /// </summary>
        public const string Pending = "Pending Admin Review";
        /// <summary>
        /// Corrections - the school asked the parent to correct something.
        /// </summary>
        public const string Corrections = "Corrections Requested";
        /// <summary>
        /// Approved - the application was accepted.
        /// </summary>
        public const string Approved = "Approved";
        /// <summary>
        /// Rejected - the application was declined.
        /// </summary>
        public const string Rejected = "Rejected";

        // IsOpen() - true while the application is still undecided (pending review, pending payment or corrections requested).
        /// <summary>Not yet decided (shown on the Pending page).</summary>
        public static bool IsOpen(string? s) =>
            s == Pending || s == PendingPayment || s == Corrections;

        /// <summary>
        /// IsDecided() - true once the application is approved or rejected.
        /// </summary>
        public static bool IsDecided(string? s) => s == Approved || s == Rejected;
    }

    // PayStatus (class) - the possible values of a payment's verification status.
    /// <summary>payments.verification_status / applications.payment_verification_status.</summary>
    public static class PayStatus
    {
        /// <summary>
        /// Pending - not checked yet.
        /// </summary>
        public const string Pending = "Pending";
        /// <summary>
        /// Verified - the Financial Clerk confirmed the payment.
        /// </summary>
        public const string Verified = "Verified";
        /// <summary>
        /// Rejected - the proof of payment was refused.
        /// </summary>
        public const string Rejected = "Rejected";
    }

    // NotificationTypes (class) - the notification types the Flutter app understands.
    /// <summary>notifications.notification_type values the Flutter app understands.</summary>
    public static class NotificationTypes
    {
        /// <summary>
        /// Message - a direct message from staff.
        /// </summary>
        public const string Message = "message";
        /// <summary>
        /// Reminder - a reminder to the parent.
        /// </summary>
        public const string Reminder = "reminder";
        /// <summary>
        /// StatusUpdate - a change in the application's status.
        /// </summary>
        public const string StatusUpdate = "status_update";
    }
}