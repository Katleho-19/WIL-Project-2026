using System.ComponentModel.DataAnnotations;
using static PhehelloEnrollmentSchool.Models.WeekBar;

namespace PhehelloEnrollmentSchool.Models
{
    public sealed class LoginViewModel
    {
        [Required(ErrorMessage = "Enter your staff email address.")]
        [EmailAddress(ErrorMessage = "Enter the email address of your staff account.")]
        public string Email { get; set; } = "";

        [Required(ErrorMessage = "Enter your password.")]
        [DataType(DataType.Password)]
        public string Password { get; set; } = "";

        public bool RememberMe { get; set; }

        /// <summary>The tab chosen on the login screen: Administrator or Financial Clerk.</summary>
        public string Portal { get; set; } = "Administrator";

        public string? ReturnUrl { get; set; }
    }

    public sealed class ForgotPasswordViewModel
    {
        [Required(ErrorMessage = "Enter your staff email address.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address.")]
        public string Email { get; set; } = "";
    }

    public sealed class WeekBar
    {
        /// <summary>One bar of the weekly chart: a single day (Mon..Sun).</summary>
        public sealed class DayBar
        {
            public string Label { get; set; } = "";    // "Mon"
            public string Tooltip { get; set; } = "";  // "Mon 13 Oct: 3"
            public int Count { get; set; }
        }

        /// <summary>Bar chart with a labelled X axis (days of the week) and Y axis (counts).</summary>
        public sealed class BarChartViewModel
        {
            public List<DayBar> Bars { get; set; } = new();
            public string XTitle { get; set; } = "Day of the week";
            public string YTitle { get; set; } = "Count";
            public string Range { get; set; } = "";
            public int YMax { get; set; } = 4;
            public int YStep { get; set; } = 1;
        }
    }

    public sealed class ListFilter
    {
        public string? Search { get; set; }
        public string? Status { get; set; }
        public int Year { get; set; }
        public int Page { get; set; } = 1;
    }

    public sealed class FilterBar
    {
        public ListFilter Filter { get; set; } = new();
        public List<string> StatusOptions { get; set; } = new();
        public bool StatusLocked { get; set; }
        public List<int> Years { get; set; } = new();
        public string SearchPlaceholder { get; set; } = "Search application or learner";
        public string Action { get; set; } = "";
        public string Controller { get; set; } = "";
    }

    public sealed class Pager
    {
        public int Page { get; set; } = 1;
        public int PageCount { get; set; } = 1;
        public string Action { get; set; } = "";
        public string Controller { get; set; } = "";
        public ListFilter Filter { get; set; } = new();
    }

    // ---------------------------------------------------------------- Administrator

    public sealed class AdminDashboardViewModel
    {
        public int Total { get; set; }
        public int Approved { get; set; }
        public int Rejected { get; set; }
        public int Pending { get; set; }
        public BarChartViewModel Weeks { get; set; } = new();
        public List<ApplicationRow> Recent { get; set; } = new();
        public string YearLabel { get; set; } = "";
        public bool Open { get; set; }
    }

    public sealed class ApplicationListViewModel
    {
        public string Title { get; set; } = "";
        public string Subtitle { get; set; } = "Review and manage submitted enrolment applications.";
        public string Action { get; set; } = "Applications";
        public List<ApplicationRow> Items { get; set; } = new();
        public FilterBar Filters { get; set; } = new();
    }

    public sealed class DocumentLine
    {
        public string Name { get; set; } = "";
        public string Status { get; set; } = "Received";
        public string Chip { get; set; } = "approved";
        public string? ViewUrl { get; set; }
    }

    public sealed class ReviewViewModel
    {
        public ApplicationRow? Application { get; set; }
        public List<DocumentLine> Documents { get; set; } = new();
        public int ProgressStep { get; set; }
        public string ProgressText { get; set; } = "";
        public bool CanApprove { get; set; }
        public bool CanDecide { get; set; }
        public string? ApproveBlockedReason { get; set; }
        public List<ApplicationRow> Choices { get; set; } = new();
    }

    public sealed class ApplicationPickerViewModel
    {
        public Guid? SelectedId { get; set; }
        public ApplicationRow? Selected { get; set; }
        public List<ApplicationRow> Choices { get; set; } = new();
    }

    public sealed class NotesViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public List<NoteRow> Notes { get; set; } = new();
    }

    public sealed class MessagingViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public List<NotificationRow> Recent { get; set; } = new();
        public string? Draft { get; set; }
    }

    public sealed class ReminderViewModel
    {
        public List<ApplicationRow> Choices { get; set; } = new();
        public string Type { get; set; } = "Application deadline";
        public string Message { get; set; } = "";
        public string Target { get; set; } = "";
    }

    public sealed class LetterViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public string? StudentNumber { get; set; }
        public ConfirmationLetterRow? Existing { get; set; }
        public string SchoolName { get; set; } = "";
        public string IdNumber { get; set; } = "";
    }

    // ---------------------------------------------------------------- Financial Clerk

    public sealed class ClerkDashboardViewModel
    {
        public int Awaiting { get; set; }
        public int Verified { get; set; }
        public decimal VerifiedAmount { get; set; }
        public int ApplicationsWithPayments { get; set; }
        public BarChartViewModel Weeks { get; set; } = new();
        public List<PaymentRow> Recent { get; set; } = new();
        public string YearLabel { get; set; } = "";
        public bool Open { get; set; }
    }

    public sealed class PaymentListViewModel
    {
        public string Title { get; set; } = "";
        public string Subtitle { get; set; } = "";
        public string Action { get; set; } = "";
        public string Mode { get; set; } = "verification"; // verification | details | verified
        public List<PaymentRow> Items { get; set; } = new();
        public FilterBar Filters { get; set; } = new();
        public Pager? Pager { get; set; }
    }

    public sealed class ProofViewModel
    {
        public PaymentRow Payment { get; set; } = new();
        public SchoolPaymentRecordRow? SchoolRecord { get; set; }
        public bool IsImage { get; set; }
        public bool IsPdf { get; set; }
        public bool CanDecide { get; set; }
    }
}

namespace PhehelloEnrollmentSchool.Models
{
    public class ErrorViewModel
    {
        public string? RequestId { get; set; }
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
    }
}
