using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    public interface IApplicationRepository
    {
        Task<List<ApplicationRow>> ListAsync(CancellationToken ct = default);
        Task<ApplicationRow?> GetAsync(Guid applicationId, CancellationToken ct = default);
        Task<DocumentRow?> GetDocumentAsync(Guid documentId, CancellationToken ct = default);

        /// <summary>
        /// Changes the status only if it is still <paramref name="expectedStatus"/>
        /// (so two administrators cannot decide the same application twice).
        /// </summary>
        Task<bool> SetStatusAsync(Guid applicationId, string expectedStatus, string newStatus, Guid reviewerId, CancellationToken ct = default);

        Task AddHistoryAsync(Guid applicationId, Guid changedBy, string? oldStatus, string newStatus, string? reason, CancellationToken ct = default);
        Task<List<NoteRow>> NotesAsync(Guid applicationId, CancellationToken ct = default);
        Task AddNoteAsync(Guid applicationId, Guid createdBy, string text, CancellationToken ct = default);
    }

    /// <summary>FR7, FR8, FR9, FR13 - applications, review decisions and internal notes.</summary>
    public sealed class ApplicationRepository : IApplicationRepository
    {
        // Light list: only what the tables show.
        private const string ListSelect =
            "*,learners(first_name,surname,student_number),submitter:profiles!applications_submitted_by_fkey(full_name)";

        // Full detail for the review page.
        private const string DetailSelect =
            "*,learners(*),submitter:profiles!applications_submitted_by_fkey(*),payments(*),application_documents(*)";

        private readonly SupabaseClient _db;

        public ApplicationRepository(SupabaseClient db) => _db = db;

        public async Task<List<ApplicationRow>> ListAsync(CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ApplicationRow>(
                "applications", $"select={ListSelect}&order=created_at.desc&limit=1000", ct);
            return rows.Where(a => a.Status != AppStatus.Draft).ToList();
        }

        public async Task<ApplicationRow?> GetAsync(Guid applicationId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ApplicationRow>(
                "applications",
                $"select={DetailSelect}&{SupabaseClient.Eq("application_id", applicationId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        public async Task<DocumentRow?> GetDocumentAsync(Guid documentId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<DocumentRow>(
                "application_documents", $"select=*&{SupabaseClient.Eq("document_id", documentId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        public async Task<bool> SetStatusAsync(Guid applicationId, string expectedStatus, string newStatus, Guid reviewerId, CancellationToken ct = default)
        {
            var now = DateTimeOffset.UtcNow;
            var filter = $"{SupabaseClient.Eq("application_id", applicationId)}&{SupabaseClient.Eq("status", expectedStatus)}";
            var updated = await _db.UpdateAsync<ApplicationRow>("applications", filter, new
            {
                status = newStatus,
                reviewed_by = reviewerId,
                reviewed_at = now,
                updated_at = now
            }, ct);
            return updated.Count > 0;
        }

        public Task AddHistoryAsync(Guid applicationId, Guid changedBy, string? oldStatus, string newStatus, string? reason, CancellationToken ct = default) =>
            _db.InsertAsync("application_status_history", new
            {
                application_id = applicationId,
                changed_by = changedBy,
                old_status = oldStatus,
                new_status = newStatus,
                change_reason = reason
            }, null, ct);

        public Task<List<NoteRow>> NotesAsync(Guid applicationId, CancellationToken ct = default) =>
            _db.SelectAsync<NoteRow>(
                "application_notes",
                $"select=*,author:profiles!application_notes_created_by_fkey(full_name)&{SupabaseClient.Eq("application_id", applicationId)}&order=created_at.desc",
                ct);

        public Task AddNoteAsync(Guid applicationId, Guid createdBy, string text, CancellationToken ct = default) =>
            _db.InsertAsync("application_notes", new
            {
                application_id = applicationId,
                created_by = createdBy,
                note_text = text
            }, null, ct);
    }
}
