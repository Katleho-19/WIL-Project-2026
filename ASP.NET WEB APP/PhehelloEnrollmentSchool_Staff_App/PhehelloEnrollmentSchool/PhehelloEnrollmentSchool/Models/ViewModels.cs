//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: ViewModels.cs defines the classes that carry data from the controllers to the Razor pages (and form
// data back): login and password forms, list filters and paging, chart data, and one view model for each Administrator
// and Financial Clerk page. They hold data only; the logic lives in the controllers.

using System.ComponentModel.DataAnnotations;
using static PhehelloEnrollmentSchool.Models.WeekBar;

namespace PhehelloEnrollmentSchool.Models
{
    /// <summary>
    /// LoginViewModel (class) - the login form: email and password (both required, email checked for format), the remember-me tick box, the portal tab chosen (Administrator or Financial Clerk) and the page to return to after login.
    /// </summary>
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

    /// <summary>
    /// ForgotPasswordViewModel (class) - the forgot-password form: the staff email address (required and checked for format).
    /// </summary>
    public sealed class ForgotPasswordViewModel
    {
        [Required(ErrorMessage = "Enter your staff email address.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address.")]
        public string Email { get; set; } = "";
    }

    /// <summary>
    /// WeekBar (class) - a container for the classes that describe the weekly bar chart on the dashboards.
    /// </summary>
    public sealed class WeekBar
    {
        // DayBar (class) - one bar of the weekly chart (Monday to Sunday): the short label, the tooltip text and the count.
        /// <summary>One bar of the weekly chart: a single day (Mon..Sun).</summary>
        public sealed class DayBar
        {
            public string Label { get; set; } = "";    // "Mon"
            public string Tooltip { get; set; } = "";  // "Mon 13 Oct: 3"
            public int Count { get; set; }
        }

        // BarChartViewModel (class) - a whole bar chart: its bars, the X-axis and Y-axis titles, the date range text and the Y-axis maximum and step size.
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

    /// <summary>
    /// ListFilter (class) - the search text, status, year and page number chosen on a list page.
    /// </summary>
    public sealed class ListFilter
    {
        public string? Search { get; set; }
        public string? Status { get; set; }
        public int Year { get; set; }
        public int Page { get; set; } = 1;
    }

    /// <summary>
    /// FilterBar (class) - everything the filter bar partial needs: the current filter, the status options (and whether the status is locked), the year options, the search placeholder and the action/controller it submits to.
    /// </summary>
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

    /// <summary>
    /// Pager (class) - everything the paging partial needs: current page, page count, the action/controller to link to and the filter to keep in the links.
    /// </summary>
    public sealed class Pager
    {
        public int Page { get; set; } = 1;
        public int PageCount { get; set; } = 1;
        public string Action { get; set; } = "";
        public string Controller { get; set; } = "";
        public ListFilter Filter { get; set; } = new();
    }

    // ---------------------------------------------------------------- Administrator

    /// <summary>
    /// AdminDashboardViewModel (class) - the Administrator dashboard: counts of total, approved, rejected and pending applications, the weekly chart, the most recent applications, the year label and whether admissions are open.
    /// </summary>
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

    /// <summary>
    /// ApplicationListViewModel (class) - an Administrator list page: title, subtitle, action name, the applications to show and the filter bar.
    /// </summary>
    public sealed class ApplicationListViewModel
    {
        public string Title { get; set; } = "";
        public string Subtitle { get; set; } = "Review and manage submitted enrolment applications.";
        public string Action { get; set; } = "Applications";
        public List<ApplicationRow> Items { get; set; } = new();
        public FilterBar Filters { get; set; } = new();
    }

    /// <summary>
    /// DocumentLine (class) - one document row on the review page: its name, status text, chip colour and the link to view the file.
    /// </summary>
    public sealed class DocumentLine
    {
        public string Name { get; set; } = "";
        public string Status { get; set; } = "Received";
        public string Chip { get; set; } = "approved";
        public string? ViewUrl { get; set; }
        public bool Resubmitted { get; set; }
    }

    /// <summary>
    /// ReviewViewModel (class) - the application review page: the application, its documents, the progress step and text, whether it can be approved or decided on, the reason approval is blocked (if any) and the applications offered in the picker.
    /// </summary>
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

    /// <summary>
    /// ApplicationPickerViewModel (class) - the application drop-down used on several pages: the selected id, the selected application and all the choices.
    /// </summary>
    public sealed class ApplicationPickerViewModel
    {
        public Guid? SelectedId { get; set; }
        public ApplicationRow? Selected { get; set; }
        public List<ApplicationRow> Choices { get; set; } = new();
    }

    /// <summary>
    /// NotesViewModel (class) - the notes page: the application picker and the notes of the selected application.
    /// </summary>
    public sealed class NotesViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public List<NoteRow> Notes { get; set; } = new();
    }

    /// <summary>
    /// MessagingViewModel (class) - the messaging page: the application picker, the recent messages sent and an optional message draft.
    /// </summary>
    public sealed class MessagingViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public List<NotificationRow> Recent { get; set; } = new();
        public string? Draft { get; set; }
    }

    /// <summary>
    /// ReminderViewModel (class) - the reminders page: the application choices, the reminder type (default "Application deadline"), the message text and the target.
    /// </summary>
    public sealed class ReminderViewModel
    {
        public List<ApplicationRow> Choices { get; set; } = new();
        public string Type { get; set; } = "Application deadline";
        public string Message { get; set; } = "";
        public string Target { get; set; } = "";
    }

    /// <summary>
    /// LetterViewModel (class) - the confirmation letters page: the application picker, the student number, any letter that already exists, the school name and the learner's ID number.
    /// </summary>
    public sealed class LetterViewModel
    {
        public ApplicationPickerViewModel Picker { get; set; } = new();
        public string? StudentNumber { get; set; }
        public ConfirmationLetterRow? Existing { get; set; }
        public string SchoolName { get; set; } = "";
        public string IdNumber { get; set; } = "";
    }

    // ---------------------------------------------------------------- Financial Clerk

    /// <summary>
    /// ClerkDashboardViewModel (class) - the Financial Clerk dashboard: payments awaiting verification, payments verified, the verified total amount, how many applications have payments, the weekly chart, recent payments, the year label and whether admissions are open.
    /// </summary>
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

    /// <summary>
    /// PaymentListViewModel (class) - a Financial Clerk list page: title, subtitle, action, the mode (verification, details or verified), the payments to show, the filter bar and the pager.
    /// </summary>
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

    /// <summary>
    /// ProofViewModel (class) - the proof-of-payment page: the payment, the matching school payment record, whether the proof is an image or a PDF and whether the clerk can still decide.
    /// </summary>
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
    /// <summary>
    /// ErrorViewModel (class) - data for the generic error page: the request id to quote when reporting a problem.
    /// </summary>
    public class ErrorViewModel
    {
        public string? RequestId { get; set; }
        /// <summary>
        /// ShowRequestId - true when there is a request id to show.
        /// </summary>
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
    }
}