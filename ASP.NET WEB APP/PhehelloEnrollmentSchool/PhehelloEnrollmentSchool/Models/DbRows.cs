using System.Text.Json.Serialization;
using PhehelloEnrollmentSchool.Infrastructure;

namespace PhehelloEnrollmentSchool.Models
{
    // Row shapes returned by Supabase (PostgREST). Property names are mapped from
    // snake_case automatically (see SupabaseClient). Every column that might not exist in
    // an older copy of the shared database is nullable so a missing column never breaks
    // the page.

    public sealed class ProfileRow
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Role { get; set; }
        public string? RelationshipToLearner { get; set; }
    }

    public sealed class LearnerRow
    {
        public Guid LearnerId { get; set; }
        public Guid? ParentId { get; set; }
        public string? FirstName { get; set; }
        public string? MiddleName { get; set; }
        public string? Surname { get; set; }
        public string? IdNumber { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? StudentNumber { get; set; }

        public string FullName =>
            string.Join(' ', new[] { FirstName, MiddleName, Surname }.Where(s => !string.IsNullOrWhiteSpace(s)));

        public string NameWithoutMiddle =>
            string.Join(' ', new[] { FirstName, Surname }.Where(s => !string.IsNullOrWhiteSpace(s)));

        /// <summary>"Thando M." - how the wireframes list learners.</summary>
        public string ShortName
        {
            get
            {
                var first = FirstName?.Trim() ?? "";
                var initial = string.IsNullOrWhiteSpace(Surname) ? "" : $" {char.ToUpperInvariant(Surname.Trim()[0])}.";
                var s = (first + initial).Trim();
                return s.Length == 0 ? "Learner" : s;
            }
        }
    }

    public sealed class DocumentRow
    {
        public Guid DocumentId { get; set; }
        public Guid ApplicationId { get; set; }
        public string? DocumentType { get; set; }
        public string? FileName { get; set; }
        public string? StoragePath { get; set; }
        public DateTimeOffset? UploadedAt { get; set; }
        public string? VerificationStatus { get; set; }
    }

    public sealed class PaymentRow
    {
        public Guid PaymentId { get; set; }
        public Guid ApplicationId { get; set; }
        public Guid? SchoolPaymentRecordId { get; set; }
        public string? PaymentReference { get; set; }
        public decimal? Amount { get; set; }
        public string? ProofFileName { get; set; }
        public string? ProofStoragePath { get; set; }
        public string VerificationStatus { get; set; } = PayStatus.Pending;
        public Guid? VerifiedBy { get; set; }
        public DateTimeOffset? VerifiedAt { get; set; }
        public string? VerificationNotes { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        /// <summary>Embedded parent application (payments?select=*,applications(*...)).</summary>
        [JsonPropertyName("applications")]
        public ApplicationRow? Application { get; set; }
    }

    public sealed class ApplicationRow
    {
        public Guid ApplicationId { get; set; }
        public string? ReferenceNumber { get; set; }
        public Guid LearnerId { get; set; }
        public Guid SubmittedBy { get; set; }
        public Guid? ReviewedBy { get; set; }
        public string? GradeAppliedFor { get; set; }
        public DateOnly? ApplicationDate { get; set; }
        public string Status { get; set; } = AppStatus.Pending;
        public string PaymentVerificationStatus { get; set; } = PayStatus.Pending;
        public DateTimeOffset? SubmittedAt { get; set; }
        public DateTimeOffset? ReviewedAt { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        [JsonPropertyName("learners")]
        public LearnerRow? Learner { get; set; }

        [JsonPropertyName("submitter")]
        public ProfileRow? Submitter { get; set; }

        [JsonPropertyName("payments")]
        public List<PaymentRow>? Payments { get; set; }

        [JsonPropertyName("application_documents")]
        public List<DocumentRow>? Documents { get; set; }

        /// <summary>The date shown to staff: application_date, else the day it was created.</summary>
        public DateTime DisplayDate =>
            ApplicationDate?.ToDateTime(TimeOnly.MinValue)
            ?? SubmittedAt?.LocalDateTime.Date
            ?? CreatedAt?.LocalDateTime.Date
            ?? DateTime.Today;

        /// <summary>PH2026-001 style id (reference_number) with a safe fallback.</summary>
        public string DisplayId =>
            !string.IsNullOrWhiteSpace(ReferenceNumber)
                ? ReferenceNumber!
                : $"PH{DisplayDate.Year}-{ApplicationId.ToString("N")[..5].ToUpperInvariant()}";

        public string ParentName =>
            string.IsNullOrWhiteSpace(Submitter?.FullName) ? "Parent / Guardian" : Submitter!.FullName!;
    }

    public sealed class SchoolPaymentRecordRow
    {
        public Guid SchoolPaymentRecordId { get; set; }
        public string? PaymentReference { get; set; }
        public string? LearnerName { get; set; }
        public string? LearnerIdNumber { get; set; }
        public decimal? Amount { get; set; }
        public DateOnly? PaymentDate { get; set; }
        public string? PaymentMethod { get; set; }
    }

    public sealed class NoteRow
    {
        public Guid NoteId { get; set; }
        public Guid ApplicationId { get; set; }
        public Guid? CreatedBy { get; set; }
        public string? NoteText { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }

        [JsonPropertyName("author")]
        public ProfileRow? Author { get; set; }
    }

    public sealed class NotificationRow
    {
        public Guid NotificationId { get; set; }
        public Guid? ApplicationId { get; set; }
        public Guid RecipientId { get; set; }
        public string? NotificationType { get; set; }
        public string? Title { get; set; }
        public string? Message { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
    }

    public sealed class ConfirmationLetterRow
    {
        public Guid ConfirmationLetterId { get; set; }
        public Guid ApplicationId { get; set; }
        public Guid LearnerId { get; set; }
        public string? LearnerName { get; set; }
        public string? LearnerIdNumber { get; set; }
        public string? StudentNumber { get; set; }
        public string? FileName { get; set; }
        public string? StoragePath { get; set; }
        public DateTimeOffset? GeneratedAt { get; set; }
    }
}
