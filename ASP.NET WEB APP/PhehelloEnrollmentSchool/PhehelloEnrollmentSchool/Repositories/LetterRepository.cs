using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
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
        private readonly SupabaseClient _db;

        public LetterRepository(SupabaseClient db) => _db = db;

        public async Task<ConfirmationLetterRow?> GetAsync(Guid applicationId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ConfirmationLetterRow>(
                "confirmation_letters",
                $"select=*&{SupabaseClient.Eq("application_id", applicationId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

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

        public Task UploadAsync(string storagePath, byte[] pdf, CancellationToken ct = default) =>
            _db.UploadAsync(storagePath, pdf, "application/pdf", upsert: true, ct);
    }
}
