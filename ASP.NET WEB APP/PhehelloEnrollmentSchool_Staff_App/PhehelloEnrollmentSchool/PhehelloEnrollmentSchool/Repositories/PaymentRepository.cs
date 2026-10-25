//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: PaymentRepository.cs is the data-access class for payments (FR6): listing and loading proofs of payment,
// finding the matching record in the school's own payment records and recording the Financial Clerk's decision.

using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
    /// <summary>
    /// IPaymentRepository (interface) - the contract for payment data access.
    /// </summary>
    public interface IPaymentRepository
    {
        Task<List<PaymentRow>> ListAsync(CancellationToken ct = default);
        Task<PaymentRow?> GetAsync(Guid paymentId, CancellationToken ct = default);
        Task<SchoolPaymentRecordRow?> FindSchoolRecordAsync(string? reference, CancellationToken ct = default);

        /// <summary>Verifies or rejects a payment that is still Pending. Returns false if it was already decided.</summary>
        Task<bool> DecideAsync(Guid paymentId, string newStatus, string? notes, Guid clerkId, Guid? schoolRecordId, CancellationToken ct = default);
    }

    /// <summary>FR6 - proof of payment, checked against the school's payment records.</summary>
    public sealed class PaymentRepository : IPaymentRepository
    {
        /// <summary>
        /// Select - the PostgREST column list: all payment columns plus the related application with the learner's names and student number and the parent's full name.
        /// </summary>
        private const string Select =
            "*,applications(*,learners(first_name,surname,student_number),submitter:profiles!applications_submitted_by_fkey(full_name))";

        /// <summary>
        /// _db - the Supabase client used for every request.
        /// </summary>
        private readonly SupabaseClient _db;

        /// <summary>
        /// Constructor - receives the Supabase client from dependency injection.
        /// </summary>
        public PaymentRepository(SupabaseClient db) => _db = db;

        /// <summary>
        /// ListAsync() - loads up to 1000 payments, newest first, with their application details.
        /// </summary>
        public Task<List<PaymentRow>> ListAsync(CancellationToken ct = default) =>
            _db.SelectAsync<PaymentRow>("payments", $"select={Select}&order=created_at.desc&limit=1000", ct);

        /// <summary>
        /// GetAsync() - loads one payment by id; returns null if not found.
        /// </summary>
        public async Task<PaymentRow?> GetAsync(Guid paymentId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<PaymentRow>(
                "payments", $"select={Select}&{SupabaseClient.Eq("payment_id", paymentId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        /// <summary>
        /// FindSchoolRecordAsync() - looks up the school's payment record with the same payment reference (trimmed). Returns null if the reference is empty or no record matches.
        /// </summary>
        public async Task<SchoolPaymentRecordRow?> FindSchoolRecordAsync(string? reference, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(reference)) return null;

            var rows = await _db.SelectAsync<SchoolPaymentRecordRow>(
                "school_payment_records",
                $"select=*&{SupabaseClient.Eq("payment_reference", reference.Trim())}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        /// <summary>
        /// DecideAsync() - saves the clerk's decision (new status, clerk, time, notes and the matching school record) but only while the payment is still Pending.
        /// Empty notes are saved as null. Returns true if a row was updated, false if the payment had already been decided.
        /// </summary>
        public async Task<bool> DecideAsync(Guid paymentId, string newStatus, string? notes, Guid clerkId, Guid? schoolRecordId, CancellationToken ct = default)
        {
            var now = DateTimeOffset.UtcNow;
            var filter = $"{SupabaseClient.Eq("payment_id", paymentId)}&{SupabaseClient.Eq("verification_status", PayStatus.Pending)}";
            var updated = await _db.UpdateAsync<PaymentRow>("payments", filter, new
            {
                verification_status = newStatus,
                verified_by = clerkId,
                verified_at = now,
                verification_notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim(),
                school_payment_record_id = schoolRecordId,
                updated_at = now
            }, ct);
            return updated.Count > 0;
        }
    }
}