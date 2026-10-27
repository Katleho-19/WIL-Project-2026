//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: ApplicationRepository.cs is the data-access class for applications (FR7, FR8, FR9, FR13): it lists
// and loads applications and documents, changes an application's status, records the status history and handles the
// administrators' internal notes. It talks to Supabase through SupabaseClient.

using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    /// <summary>
    /// IApplicationRepository (interface) - the contract the controllers depend on; ApplicationRepository is the real implementation (registered in Program.cs).
    /// </summary>
    public interface IApplicationRepository
    {
        Task AddDocumentRequestsAsync(Guid applicationId, Guid requestedBy, IEnumerable<string> types, string? message, CancellationToken ct = default);
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
        /// <summary>
        /// ListSelect - the PostgREST column list for the application tables: all application columns plus the learner's names and student number and the submitting parent's full name.
        /// </summary>
        // Light list: only what the tables show.
        private const string ListSelect =
            "*,learners(first_name,surname,student_number),submitter:profiles!applications_submitted_by_fkey(full_name)";

        /// <summary>
        /// DetailSelect - the PostgREST column list for the review page: the application with its full learner and parent profile, payments and documents.
        /// </summary>
        // Full detail for the review page.
        private const string DetailSelect =
            "*,learners(*),submitter:profiles!applications_submitted_by_fkey(*),payments(*),application_documents(*), document_requests(*)";

        /// <summary>
        /// _db - the Supabase client used for every request.
        /// </summary>
        private readonly SupabaseClient _db;

        /// <summary>
        /// Constructor - receives the Supabase client from dependency injection.
        /// </summary>
        public ApplicationRepository(SupabaseClient db) => _db = db;

        public Task AddDocumentRequestsAsync(Guid applicationId, Guid requestedBy, IEnumerable<string> types, string? message, CancellationToken ct = default)
        {
            var rows = types.Distinct().Select(t => new
            {
                application_id = applicationId,
                document_type = t,
                routed_to = t == "Proof of Payment" ? "Financial Clerk" : "Administrator",
                message,
                requested_by = requestedBy
            }).ToList();
            return rows.Count == 0 ? Task.CompletedTask : _db.InsertAsync("document_requests", rows, null, ct);
        }

        /// <summary>
        /// ListAsync() - loads up to 1000 applications, newest first, using the light column list, and removes drafts (a draft has not been submitted yet).
        /// </summary>
        public async Task<List<ApplicationRow>> ListAsync(CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ApplicationRow>(
                "applications", $"select={ListSelect}&order=created_at.desc&limit=1000", ct);
            return rows.Where(a => a.Status != AppStatus.Draft).ToList();
        }

        /// <summary>
        /// GetAsync() - loads one application by id with all its related data; returns null if it does not exist or the user may not see it.
        /// </summary>
        public async Task<ApplicationRow?> GetAsync(Guid applicationId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<ApplicationRow>(
                "applications",
                $"select={DetailSelect}&{SupabaseClient.Eq("application_id", applicationId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        /// <summary>
        /// GetDocumentAsync() - loads one uploaded document record by id; returns null if not found.
        /// </summary>
        public async Task<DocumentRow?> GetDocumentAsync(Guid documentId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<DocumentRow>(
                "application_documents", $"select=*&{SupabaseClient.Eq("document_id", documentId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        /// <summary>
        /// SetStatusAsync() - sets a new status, the reviewer and the review time, but only if the application is still in the expected status
        /// (so two administrators cannot decide the same application). Returns true if a row was updated, false if nothing changed.
        /// </summary>
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

        /// <summary>
        /// AddHistoryAsync() - inserts a row in application_status_history recording who changed the status, from what, to what and why.
        /// </summary>
        public Task AddHistoryAsync(Guid applicationId, Guid changedBy, string? oldStatus, string newStatus, string? reason, CancellationToken ct = default) =>
            _db.InsertAsync("application_status_history", new
            {
                application_id = applicationId,
                changed_by = changedBy,
                old_status = oldStatus,
                new_status = newStatus,
                change_reason = reason
            }, null, ct);

        /// <summary>
        /// NotesAsync() - loads the internal notes of an application, newest first, including each author's name.
        /// </summary>
        public Task<List<NoteRow>> NotesAsync(Guid applicationId, CancellationToken ct = default) =>
            _db.SelectAsync<NoteRow>(
                "application_notes",
                $"select=*,author:profiles!application_notes_created_by_fkey(full_name)&{SupabaseClient.Eq("application_id", applicationId)}&order=created_at.desc",
                ct);

        /// <summary>
        /// AddNoteAsync() - inserts a new internal note for an application, written by the given administrator.
        /// </summary>
        public Task AddNoteAsync(Guid applicationId, Guid createdBy, string text, CancellationToken ct = default) =>
            _db.InsertAsync("application_notes", new
            {
                application_id = applicationId,
                created_by = createdBy,
                note_text = text
            }, null, ct);
    }
}