using System.Globalization;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>Formatting helpers shared by controllers and views.</summary>
    public static class Fmt
    {
        private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;

        public static string Date(DateTime d) => d.ToString("d MMM yyyy", Inv);
        public static string LongDate(DateTime d) => d.ToString("d MMMM yyyy", Inv);
        public static string DateTimeNote(DateTimeOffset? d) =>
            d == null ? "" : d.Value.LocalDateTime.ToString("d MMM yyyy • HH:mm", Inv);

        public static string Money(decimal? v) =>
            v == null ? "—" : "R" + (v.Value % 1 == 0 ? v.Value.ToString("0", Inv) : v.Value.ToString("0.00", Inv));

        public static string MoneyBig(decimal v) =>
            "R " + v.ToString("#,##0", Inv).Replace(",", " ");

        public static string Money2(decimal? v) => v == null ? "—" : "R" + v.Value.ToString("0.00", Inv);

        /// <summary>CSS modifier for the status chips.</summary>
        public static string ChipClass(string? status) => status switch
        {
            AppStatus.Approved or PayStatus.Verified => "approved",
            AppStatus.Rejected or PayStatus.Rejected => "rejected",
            AppStatus.Corrections => "corrections",
            _ => "pending"
        };

        public static string Mask(string? value) =>
            string.IsNullOrEmpty(value) ? "—" : new string('•', Math.Max(value.Length, 8));

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
