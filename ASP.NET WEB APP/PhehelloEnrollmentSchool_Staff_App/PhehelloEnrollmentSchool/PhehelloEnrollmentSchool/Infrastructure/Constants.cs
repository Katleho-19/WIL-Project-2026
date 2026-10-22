namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>Role names exactly as stored in profiles.role (SRS ERD).</summary>
    public static class StaffRoles
    {
        public const string Administrator = "Administrator";
        public const string FinancialClerk = "Financial Clerk";

        public static bool IsStaff(string? role) =>
            role == Administrator || role == FinancialClerk;
    }

    public static class Policies
    {
        public const string Administrator = "AdministratorOnly";
        public const string FinancialClerk = "FinancialClerkOnly";
    }

    /// <summary>Custom claim names used to carry the Supabase session inside the auth cookie.</summary>
    public static class SessionClaims
    {
        public const string AccessToken = "sb_access_token";
        public const string RefreshToken = "sb_refresh_token";
        public const string ExpiresAt = "sb_expires_at";
    }

    /// <summary>applications.status vocabulary (live schema CHECK constraint + Flutter app).</summary>
    public static class AppStatus
    {
        public const string Draft = "Draft";
        public const string PendingPayment = "Pending Payment Verification";
        public const string Pending = "Pending Admin Review";
        public const string Corrections = "Corrections Requested";
        public const string Approved = "Approved";
        public const string Rejected = "Rejected";

        /// <summary>Not yet decided (shown on the Pending page).</summary>
        public static bool IsOpen(string? s) =>
            s == Pending || s == PendingPayment || s == Corrections;

        public static bool IsDecided(string? s) => s == Approved || s == Rejected;
    }

    /// <summary>payments.verification_status / applications.payment_verification_status.</summary>
    public static class PayStatus
    {
        public const string Pending = "Pending";
        public const string Verified = "Verified";
        public const string Rejected = "Rejected";
    }

    /// <summary>notifications.notification_type values the Flutter app understands.</summary>
    public static class NotificationTypes
    {
        public const string Message = "message";
        public const string Reminder = "reminder";
        public const string StatusUpdate = "status_update";
    }
}
