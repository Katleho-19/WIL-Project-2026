namespace PhehelloEnrollmentSchool.Infrastructure
{
    public sealed class SupabaseOptions
    {
        public const string SectionName = "Supabase";

        /// <summary>Project URL, e.g. https://xxxx.supabase.co</summary>
        public string Url { get; set; } = "";

        /// <summary>
        /// The public "anon" / publishable key. It is safe to ship (it is the same key
        /// the Flutter app uses); data access is protected by Row Level Security and by
        /// the signed-in user's own token. NEVER put the service_role key here.
        /// </summary>
        public string PublishableKey { get; set; } = "";

        public string Bucket { get; set; } = "enrolment-documents";

        public string BaseUrl => Url.TrimEnd('/');
    }

    public sealed class SchoolOptions
    {
        public const string SectionName = "School";

        public string Name { get; set; } = "Phehello Secondary School";
        public string Motto { get; set; } = "Perseverance is the Mother of Success";
        public string Telephone { get; set; } = "";
        public string Address { get; set; } = "";

        /// <summary>0 = use the current calendar year.</summary>
        public int AcademicYear { get; set; }

        public bool AdmissionsOpen { get; set; } = true;

        public int EffectiveYear => AcademicYear > 0 ? AcademicYear : DateTime.Now.Year;
    }
}
