//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: Options.cs defines the two settings classes that are filled from appsettings.json:
// SupabaseOptions (connection to the Supabase backend) and SchoolOptions (school details and the admissions year).

namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>
    /// SupabaseOptions (class) - the "Supabase" section of appsettings.json.
    /// </summary>
    public sealed class SupabaseOptions
    {
        /// <summary>
        /// SectionName - the name of the settings section ("Supabase").
        /// </summary>
        public const string SectionName = "Supabase";

        /// <summary>Project URL, e.g. https://xxxx.supabase.co</summary>
        public string Url { get; set; } = "";

        /// <summary>
        /// The public "anon" / publishable key. It is safe to ship (it is the same key
        /// the Flutter app uses); data access is protected by Row Level Security and by
        /// the signed-in user's own token. NEVER put the service_role key here.
        /// </summary>
        public string PublishableKey { get; set; } = "";

        /// <summary>
        /// Bucket - the name of the Supabase Storage bucket that holds the uploaded documents (default "enrolment-documents").
        /// </summary>
        public string Bucket { get; set; } = "enrolment-documents";

        /// <summary>
        /// BaseUrl - the project URL without a trailing slash, ready to build request addresses.
        /// </summary>
        public string BaseUrl => Url.TrimEnd('/');
    }

    /// <summary>
    /// SchoolOptions (class) - the "School" section of appsettings.json.
    /// </summary>
    public sealed class SchoolOptions
    {
        /// <summary>
        /// SectionName - the name of the settings section ("School").
        /// </summary>
        public const string SectionName = "School";

        /// <summary>
        /// Name - the school's name (default "Phehello Secondary School").
        /// </summary>
        public string Name { get; set; } = "Phehello Secondary School";
        /// <summary>
        /// Motto - the school's motto.
        /// </summary>
        public string Motto { get; set; } = "Perseverance is the Mother of Success";
        /// <summary>
        /// Telephone - the school's phone number.
        /// </summary>
        public string Telephone { get; set; } = "";
        /// <summary>
        /// Address - the school's postal/physical address.
        /// </summary>
        public string Address { get; set; } = "";

        /// <summary>0 = use the current calendar year.</summary>
        public int AcademicYear { get; set; }

        /// <summary>
        /// AdmissionsOpen - true while the school is accepting applications.
        /// </summary>
        public bool AdmissionsOpen { get; set; } = true;

        /// <summary>
        /// EffectiveYear - the academic year actually used: AcademicYear if it is set, otherwise the current calendar year.
        /// </summary>
        public int EffectiveYear => AcademicYear > 0 ? AcademicYear : DateTime.Now.Year;
    }
}