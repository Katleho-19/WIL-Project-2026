//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: DbRows.cs defines the "row" classes - plain C# classes that mirror the tables of the shared Supabase
// database. The Supabase client turns the JSON it receives (snake_case column names) into these objects, so a column
// such as full_name becomes the property FullName. Nullable properties (with ?) may be missing in an older copy of the database.

using System.Text.Json.Serialization;
using PhehelloEnrollmentSchool.Infrastructure;

namespace PhehelloEnrollmentSchool.Models
{
    // Row shapes returned by Supabase (PostgREST). Property names are mapped from
    // snake_case automatically (see SupabaseClient). Every column that might not exist in
    // an older copy of the shared database is nullable so a missing column never breaks
    // the page.

    /// <summary>
    /// ProfileRow (class) - one row of the profiles table: a user's id, name, email, phone number, role (Parent, Administrator or Financial Clerk) and relationship to the learner.
    /// </summary>
    public sealed class ProfileRow
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Role { get; set; }
        public string? RelationshipToLearner { get; set; }
    }

    /// <summary>
    /// LearnerRow (class) - one row of the learners table: the learner's id, parent, names, ID number, date of birth, gender and student number.
    /// </summary>
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

        /// <summary>
        /// FullName - the first name, middle name and surname joined with spaces; empty parts are skipped.
        /// </summary>
        public string FullName =>
            string.Join(' ', new[] { FirstName, MiddleName, Surname }.Where(s => !string.IsNullOrWhiteSpace(s)));

        /// <summary>
        /// NameWithoutMiddle - the first name and surname only, joined with a space.
        /// </summary>
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

    /// <summary>
    /// DocumentRow (class) - one row of the application_documents table: an uploaded supporting document (type, file name, storage path, upload time and verification status).
    /// </summary>
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

    /// <summary>
    /// PaymentRow (class) - one row of the payments table: a proof-of-payment submission with its reference, amount, proof file, verification status
    /// (Pending by default), who verified it, when and any notes. It can also carry the parent application when the query embeds it.
    /// </summary>
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

    /// <summary>
    /// ApplicationRow (class) - one row of the applications table: reference number, learner, who submitted it, grade applied for, status (Pending by default),
    /// payment verification status and the key dates. A query can embed the related learner, submitter profile, payments and documents.
    /// </summary>
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

        /// <summary>
        /// ParentName - the submitting parent's full name, or "Parent / Guardian" if it is not available.
        /// </summary>
        public string ParentName =>
            string.IsNullOrWhiteSpace(Submitter?.FullName) ? "Parent / Guardian" : Submitter!.FullName!;
    }

    /// <summary>
    /// SchoolPaymentRecordRow (class) - one row of the school's own payment records (what the bank actually received): reference, learner name and ID, amount, date and method.
    /// The Financial Clerk compares these with the parent's proof of payment.
    /// </summary>
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

    /// <summary>
    /// NoteRow (class) - one row of the application notes table: an internal note an administrator wrote about an application, with its author when embedded.
    /// </summary>
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

    /// <summary>
    /// NotificationRow (class) - one row of the notifications table: a message or reminder sent to a parent (recipient, type, title, message, time).
    /// </summary>
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

    /// <summary>
    /// ConfirmationLetterRow (class) - one row of the confirmation letters table: a generated PDF letter for an application (learner details, file name, storage path and when it was generated).
    /// </summary>
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