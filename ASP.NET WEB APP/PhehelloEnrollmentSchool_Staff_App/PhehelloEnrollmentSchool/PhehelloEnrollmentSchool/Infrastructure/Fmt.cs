//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: Fmt.cs contains small formatting helpers (dates, money, status chip colours, masking and a
// greeting) used by the controllers and the Razor views so text is formatted the same way everywhere.

using System.Globalization;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    // Fmt (class) - static formatting helpers.
    /// <summary>Formatting helpers shared by controllers and views.</summary>
    public static class Fmt
    {
        /// <summary>
        /// Inv - the invariant culture, so numbers and dates look the same on every computer.
        /// </summary>
        private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        /// <summary>
        /// Date() - formats a date like "5 Oct 2026".
        /// </summary>
        public static string Date(DateTime d) => d.ToString("d MMM yyyy", Inv);
        /// <summary>
        /// LongDate() - formats a date like "5 October 2026".
        /// </summary>
        public static string LongDate(DateTime d) => d.ToString("d MMMM yyyy", Inv);
        /// <summary>
        /// DateTimeNote() - formats a date and time in local time like "5 Oct 2026 • 14:30"; returns empty text if there is no value.
        /// </summary>
        public static string DateTimeNote(DateTimeOffset? d) =>
            d == null ? "" : d.Value.LocalDateTime.ToString("d MMM yyyy • HH:mm", Inv);

        /// <summary>
        /// Money() - formats an amount as rand: "R200" for whole amounts, "R200.50" otherwise, or a dash if there is no value.
        /// </summary>
        public static string Money(decimal? v) =>
            v == null ? "—" : "R" + (v.Value % 1 == 0 ? v.Value.ToString("0", Inv) : v.Value.ToString("0.00", Inv));

        /// <summary>
        /// MoneyBig() - formats a whole amount with spaces as thousand separators, e.g. "R 12 500", for large dashboard figures.
        /// </summary>
        public static string MoneyBig(decimal v) =>
            "R " + v.ToString("#,##0", Inv).Replace(",", " ");

        /// <summary>
        /// Money2() - formats an amount with exactly two decimals, e.g. "R200.00", or a dash if there is no value.
        /// </summary>
        public static string Money2(decimal? v) => v == null ? "—" : "R" + v.Value.ToString("0.00", Inv);

        // ChipClass() - returns the CSS class of a status chip: "approved" (Approved or Verified), "rejected" (Rejected),
        // "corrections" (Corrections Requested), otherwise "pending".
        /// <summary>CSS modifier for the status chips.</summary>
        public static string ChipClass(string? status) => status switch
        {
            AppStatus.Approved or PayStatus.Verified => "approved",
            AppStatus.Rejected or PayStatus.Rejected => "rejected",
            AppStatus.Corrections => "corrections",
            _ => "pending"
        };

        /// <summary>
        /// Mask() - hides a sensitive value (such as an ID number) behind bullet characters (at least 8); returns a dash if the value is empty.
        /// </summary>
        public static string Mask(string? value) =>
            string.IsNullOrEmpty(value) ? "—" : new string('•', Math.Max(value.Length, 8));

        /// <summary>
        /// Greeting() - returns "Good morning", "Good afternoon" or "Good evening" using South African time. It tries the Linux time zone name first,
        /// then the Windows name, and falls back to the server's local time if neither exists.
        /// </summary>
        public static string Greeting()
        {
            DateTime now;
            try { now = TimeZoneInfo.ConvertTime(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("Africa/Johannesburg")); }
            catch (TimeZoneNotFoundException)
            {
                try { now = TimeZoneInfo.ConvertTime(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("South Africa Standard Time")); }
                catch (TimeZoneNotFoundException) { now = DateTime.Now; }
            }
            return now.Hour < 12 ? "Good morning" : now.Hour < 18 ? "Good afternoon" : "Good evening";
        }
    }
}