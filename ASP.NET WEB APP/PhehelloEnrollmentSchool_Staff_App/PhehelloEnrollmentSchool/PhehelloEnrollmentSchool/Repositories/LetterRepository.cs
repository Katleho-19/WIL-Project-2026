//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: LetterRepository.cs handles confirmation letters (FR12): loading and saving the letter record, uploading the
// PDF file to storage and giving a learner a unique student number such as PH2026/001.

using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    /// <summary>
    /// ILetterRepository (interface) - the contract for letter-related data access.
    /// </summary>
    public interface ILetterRepository
    {
        Task<ConfirmationLetterRow?> GetAsync(Guid applicationId, CancellationToken ct = default);

        Task SaveAsync(Guid applicationId, Guid learnerId, Guid generatedBy, string learnerName, string learnerIdNumber,
            string studentNumber, string fileName, string storagePath, CancellationToken ct = default);

        /// <summary>
        /// Returns the learner's unique student number, creating the next one (PH2026/001, PH2026/002 ...)
        /// when the learner does not have one yet. Returns null if it could not be assigned.
        /// </summary>
        Task<string?> EnsureStudentNumberAsync(Guid learnerId, int year, CancellationToken ct = default);

        Task UploadAsync(string storagePath, byte[] pdf, CancellationToken ct = default);
    }

    /// <summary>FR12 - confirmation letters and the unique student numbers printed on them.</summary>
    public sealed class LetterRepository : ILetterRepository
    {
        /// <summary>
        /// _db - the Supabase client used for every request.
        /// </summary>
        private readonly SupabaseClient _db;

        /// <summary>
        /// Constructor - receives the Supabase client from dependency injection.
        /// </summary>
        public LetterRepository(SupabaseClient db) => _db = db;

        /// <summary>
        /// GetAsync() - loads the letter record of an application; returns null if no letter was generated yet.
        /// </summary>
        public async Task<ConfirmationLetterRow?> GetAsync(Guid applicationId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ConfirmationLetterRow>(
                "confirmation_letters",
                $"select=*&{SupabaseClient.Eq("application_id", applicationId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        /// <summary>
        /// SaveAsync() - saves the letter record (application, learner, who generated it, learner name and ID, student number, file name, storage path and time). If the application already has a letter, the record is updated instead (upsert on application_id).
        /// </summary>
        public Task SaveAsync(Guid applicationId, Guid learnerId, Guid generatedBy, string learnerName, string learnerIdNumber,
            string studentNumber, string fileName, string storagePath, CancellationToken ct = default) =>
            _db.InsertAsync("confirmation_letters", new
            {
                application_id = applicationId,
                learner_id = learnerId,
                generated_by = generatedBy,
                learner_name = learnerName,
                learner_id_number = learnerIdNumber,
                student_number = studentNumber,
                file_name = fileName,
                storage_path = storagePath,
                generated_at = DateTimeOffset.UtcNow
            }, onConflict: "application_id", ct: ct);

        /// <summary>
        /// EnsureStudentNumberAsync() - makes sure the learner has a student number. If one exists it is returned. Otherwise it finds the highest number of the year (prefix "PH&lt;year&gt;/"),
        /// adds one (and one more for each retry) and saves it only if the learner still has none. If another learner took that number first (unique violation), it tries the next one, up to 5 attempts.
        /// If the update changed nothing it re-reads the learner and returns whatever number is there. Returns null if no number could be assigned.
        /// </summary>
        public async Task<string?> EnsureStudentNumberAsync(Guid learnerId, int year, CancellationToken ct = default)
        {
            var current = await _db.SelectAsync<LearnerRow>(
                "learners", $"select=learner_id,student_number&{SupabaseClient.Eq("learner_id", learnerId)}&limit=1", ct);
            var existing = current.FirstOrDefault()?.StudentNumber;
            if (!string.IsNullOrWhiteSpace(existing)) return existing;

            var prefix = $"PH{year}/";

            for (var attempt = 0; attempt < 5; attempt++)
            {
                var latest = await _db.SelectAsync<LearnerRow>(
                    "learners",
                    $"select=learner_id,student_number&student_number=like.{Uri.EscapeDataString(prefix)}*&order=student_number.desc&limit=1", ct);

                var next = 1;
                var last = latest.FirstOrDefault()?.StudentNumber;
                if (last != null && int.TryParse(last[prefix.Length..], out var n)) next = n + 1;
                next += attempt; // step past a number another administrator just took

                var candidate = $"{prefix}{next:000}";
                try
                {
                    var updated = await _db.UpdateAsync<LearnerRow>(
                        "learners",
                        $"{SupabaseClient.Eq("learner_id", learnerId)}&student_number=is.null",
                        new { student_number = candidate, updated_at = DateTimeOffset.UtcNow }, ct);

                    if (updated.Count > 0) return candidate;

                    // Nothing updated: either someone else assigned one, or the database did not allow it.
                    var recheck = await _db.SelectAsync<LearnerRow>(
                        "learners", $"select=learner_id,student_number&{SupabaseClient.Eq("learner_id", learnerId)}&limit=1", ct);
                    return recheck.FirstOrDefault()?.StudentNumber;
                }
                catch (SupabaseApiException ex) when (ex.Code == "23505")
                {
                    // Unique violation - another learner got this number first. Try the next one.
                }
            }

            return null;
        }

        /// <summary>
        /// UploadAsync() - uploads the letter PDF to storage at the given path, replacing any existing file.
        /// </summary>
        public Task UploadAsync(string storagePath, byte[] pdf, CancellationToken ct = default) =>
            _db.UploadAsync(storagePath, pdf, "application/pdf", upsert: true, ct);
    }
}