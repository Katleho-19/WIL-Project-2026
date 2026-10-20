using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Repositories
{
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
        private const string Select =
            "*,applications(*,learners(first_name,surname,student_number),submitter:profiles!applications_submitted_by_fkey(full_name))";

        private readonly SupabaseClient _db;

        public PaymentRepository(SupabaseClient db) => _db = db;

        public Task<List<PaymentRow>> ListAsync(CancellationToken ct = default) =>
            _db.SelectAsync<PaymentRow>("payments", $"select={Select}&order=created_at.desc&limit=1000", ct);

        public async Task<PaymentRow?> GetAsync(Guid paymentId, CancellationToken ct = default)
        {
            var rows = await _db.SelectAsync<PaymentRow>(
                "payments", $"select={Select}&{SupabaseClient.Eq("payment_id", paymentId)}&limit=1", ct);
            return rows.FirstOrDefault();
        }

        public async Task<SchoolPaymentRecordRow?> FindSchoolRecordAsync(string? reference, CancellationToken ct = default)
        {
            if (string.IsNullOrWhiteSpace(reference)) return null;

            var rows = await _db.SelectAsync<SchoolPaymentRecordRow>(
                "school_payment_records",
                $"select=*&{SupabaseClient.Eq("payment_reference", reference.Trim())}&limit=1", ct);
            return rows.FirstOrDefault();
        }

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
