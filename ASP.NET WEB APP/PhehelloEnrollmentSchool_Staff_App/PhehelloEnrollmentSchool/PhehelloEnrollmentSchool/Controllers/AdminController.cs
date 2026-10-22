using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;
using PhehelloEnrollmentSchool.Repositories;
using PhehelloEnrollmentSchool.Services;
using System.Globalization;
using static PhehelloEnrollmentSchool.Models.WeekBar;

namespace PhehelloEnrollmentSchool.Controllers
{
    [Authorize(Policy = Policies.Administrator)]
    public class AdminController : StaffControllerBase
    {
        private static readonly string[] RequiredDocs =
            { "Birth Certificate", "Previous School Progress Report", "Immunisation Record" };

        private readonly IApplicationRepository _apps;
        private readonly INotificationRepository _notifications;
        private readonly ILetterRepository _letters;
        private readonly IFileRepository _files;
        private readonly ConfirmationLetterPdf _pdf;
        private readonly SchoolOptions _school;
        private readonly ILogger<AdminController> _logger;

        public AdminController(IApplicationRepository apps, INotificationRepository notifications, ILetterRepository letters,
            IFileRepository files, ConfirmationLetterPdf pdf, IOptions<SchoolOptions> school, ILogger<AdminController> logger)
        {
            _apps = apps; _notifications = notifications; _letters = letters; _files = files; _pdf = pdf;
            _school = school.Value; _logger = logger;
        }

        // ------------------------------------------------------------ Dashboard (FR13)

        public async Task<IActionResult> Dashboard(CancellationToken ct)
        {
            var all = await _apps.ListAsync(ct);
            var vm = new AdminDashboardViewModel
            {
                Total = all.Count,
                Approved = all.Count(a => a.Status == AppStatus.Approved),
                Rejected = all.Count(a => a.Status == AppStatus.Rejected),
                Pending = all.Count(a => AppStatus.IsOpen(a.Status)),
                Recent = all.OrderByDescending(a => a.CreatedAt).Take(5).ToList(),
                Weeks = WeeklyTrend(all.Select(a => a.DisplayDate), "Applications submitted"),
                YearLabel = $"{_school.EffectiveYear} Enrolment",
                Open = _school.AdmissionsOpen
            };
            return View(vm);
        }

        /// <summary>Counts per day (Monday..Sunday) of the current week for the dashboard bar chart.</summary>
        internal static BarChartViewModel WeeklyTrend(IEnumerable<DateTime> dates, string yTitle)
        {
            var list = dates.Select(d => d.Date).ToList();
            var monday = StartOfWeek(DateTime.Today);

            var bars = Enumerable.Range(0, 7).Select(i =>
            {
                var day = monday.AddDays(i);
                var count = list.Count(d => d == day);
                return new DayBar
                {
                    Label = day.ToString("ddd", CultureInfo.InvariantCulture),
                    Tooltip = $"{day.ToString("ddd d MMM", CultureInfo.InvariantCulture)}: {count}",
                    Count = count
                };
            }).ToList();

            // Pick a tidy Y-axis step so there are at most ~5 gridlines.
            var max = Math.Max(1, bars.Max(b => b.Count));
            var step = new[] { 1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 5000 }
                .FirstOrDefault(s => max / (double)s <= 5);
            if (step == 0) step = 10000;

            return new BarChartViewModel
            {
                Bars = bars,
                YTitle = yTitle,
                XTitle = "Day of the week",
                Range = $"{monday.ToString("d MMM", CultureInfo.InvariantCulture)} – {monday.AddDays(6).ToString("d MMM yyyy", CultureInfo.InvariantCulture)}",
                YStep = step,
                YMax = (int)Math.Ceiling(max / (double)step) * step
            };
        }

        private static DateTime StartOfWeek(DateTime d)
        {
            var diff = (7 + (int)d.DayOfWeek - (int)DayOfWeek.Monday) % 7;
            return d.Date.AddDays(-diff);
        }

        // ------------------------------------------------------------ Lists (FR7)

        public Task<IActionResult> Applications(ListFilter f, CancellationToken ct) =>
            List("Applications", "Applications", null, new[] { AppStatus.Pending, AppStatus.Corrections, AppStatus.Approved, AppStatus.Rejected }, f, ct);

        public Task<IActionResult> Approved(ListFilter f, CancellationToken ct) =>
            List("Approved Applications", "Approved", AppStatus.Approved, new[] { AppStatus.Approved }, f, ct);

        public Task<IActionResult> Rejected(ListFilter f, CancellationToken ct) =>
            List("Rejected Applications", "Rejected", AppStatus.Rejected, new[] { AppStatus.Rejected }, f, ct);

        public Task<IActionResult> Pending(ListFilter f, CancellationToken ct) =>
            List("Pending Applications", "Pending", null, new[] { AppStatus.Pending, AppStatus.Corrections }, f, ct,
                open: true);

        private async Task<IActionResult> List(string title, string action, string? fixedStatus, string[] options,
            ListFilter f, CancellationToken ct, bool open = false)
        {
            var all = await _apps.ListAsync(ct);
            var year = f.Year > 0 ? f.Year : _school.EffectiveYear;
            var status = fixedStatus ?? f.Status;

            var items = all.Where(a => a.DisplayDate.Year == year)
                .Where(a => open ? AppStatus.IsOpen(a.Status) : fixedStatus == null || a.Status == fixedStatus)
                .Where(a => string.IsNullOrWhiteSpace(status) || a.Status == status)
                .Where(a => ListFiltering.Matches(f.Search, a.DisplayId, a.Learner?.FullName, a.Learner?.NameWithoutMiddle, a.ParentName))
                .ToList();

            f.Year = year; f.Status = status;
            return View("List", new ApplicationListViewModel
            {
                Title = title,
                Action = action,
                Items = items,
                Filters = new FilterBar
                {
                    Filter = f,
                    StatusOptions = options.ToList(),
                    StatusLocked = fixedStatus != null,
                    Years = ListFiltering.Years(all.Select(a => a.DisplayDate.Year), _school.EffectiveYear),
                    Action = action,
                    Controller = "Admin"
                }
            });
        }

        // ------------------------------------------------------------ Review (FR7, FR8)

        public async Task<IActionResult> Review(Guid? id, CancellationToken ct)
        {
            // No application chosen (e.g. sidebar click) -> show the "none selected" state
            if (id == null)
                return View(new ReviewViewModel());

            var app = await _apps.GetAsync(id.Value, ct);
            if (app == null) return NotFound();
            return View(BuildReview(app));
        }

        private static ReviewViewModel BuildReview(ApplicationRow app)
        {
            var docs = app.Documents ?? new();
            var lines = new List<DocumentLine>();

            foreach (var type in RequiredDocs)
            {
                var doc = docs.FirstOrDefault(d => string.Equals(d.DocumentType, type, StringComparison.OrdinalIgnoreCase));
                lines.Add(DocLine(type, doc));
            }
            foreach (var extra in docs.Where(d => !RequiredDocs.Contains(d.DocumentType ?? "", StringComparer.OrdinalIgnoreCase)))
                lines.Add(DocLine(extra.DocumentType ?? "Other Document", extra));

            var payment = (app.Payments ?? new()).OrderByDescending(p => p.CreatedAt).FirstOrDefault();
            lines.Add(new DocumentLine
            {
                Name = "Proof of Payment",
                Status = payment?.VerificationStatus ?? "Missing",
                Chip = payment == null ? "pending" : Fmt.ChipClass(payment.VerificationStatus),
                ViewUrl = null
            });

            var paymentVerified = app.PaymentVerificationStatus == PayStatus.Verified;
            var docsComplete = lines.Where(l => RequiredDocs.Select(Pretty).Contains(l.Name)).All(l => l.Status == "Received");
            var decided = AppStatus.IsDecided(app.Status);

            var step = 1;
            if (paymentVerified) step = 2;
            if (paymentVerified && docsComplete) step = 3;
            if (decided) step = 4;

            var text = app.Status switch
            {
                AppStatus.Approved => "Application approved. A confirmation letter can now be generated.",
                AppStatus.Rejected => "Application rejected. A confirmation letter can still be generated for the parent.",
                AppStatus.Corrections => "Corrections requested. Waiting for the parent to resubmit.",
                _ when app.PaymentVerificationStatus == PayStatus.Rejected => "Payment proof was rejected. Waiting for the parent to upload a new proof.",
                _ when !paymentVerified => "Waiting for the Financial Clerk to verify the proof of payment.",
                _ => "Payment verified. Application is ready for administrator decision."
            };

            return new ReviewViewModel
            {
                Application = app,
                Documents = lines,
                ProgressStep = step,
                ProgressText = text,
                CanDecide = AppStatus.IsOpen(app.Status),
                CanApprove = AppStatus.IsOpen(app.Status) && paymentVerified,
                ApproveBlockedReason = paymentVerified ? null : "Approval is only possible once the Financial Clerk has verified the payment."
            };
        }

        private static string Pretty(string type) => type == "Previous School Progress Report" ? "Progress Report" : type;

        private static DocumentLine DocLine(string type, DocumentRow? doc) => new()
        {
            Name = Pretty(type),
            Status = doc == null ? "Missing" : "Received",
            Chip = doc == null ? "pending" : "approved",
            ViewUrl = doc == null ? null : $"/Admin/DocumentFile/{doc.DocumentId}"
        };

        [HttpPost]
        public async Task<IActionResult> Decide(Guid id, string decision, string? message, string? internalNote, CancellationToken ct)
        {
            try
            {
                var app = await _apps.GetAsync(id, ct);
                if (app == null) return NotFound();

                message = message?.Trim();
                string newStatus;
                switch (decision)
                {
                    case "approve":
                        if (!AppStatus.IsOpen(app.Status)) { Failure("This application has already been decided."); break; }
                        if (app.PaymentVerificationStatus != PayStatus.Verified)
                        { Failure("The payment must be verified by the Financial Clerk before approval."); break; }
                        newStatus = AppStatus.Approved;
                        await ApplyDecision(app, newStatus, message, internalNote, ct);
                        Success("Application approved.");
                        break;

                    case "corrections":
                        if (app.Status is not (AppStatus.Pending or AppStatus.PendingPayment))
                        { Failure("Corrections can only be requested on an application that is waiting for review."); break; }
                        if (string.IsNullOrWhiteSpace(message))
                        { Failure("Tell the parent what needs to be corrected."); break; }
                        await ApplyDecision(app, AppStatus.Corrections, message, internalNote, ct);
                        Success("Corrections requested. The parent has been notified.");
                        break;

                    case "reject":
                        if (!AppStatus.IsOpen(app.Status)) { Failure("This application has already been decided."); break; }
                        await ApplyDecision(app, AppStatus.Rejected, message, internalNote, ct);
                        Success("Application rejected.");
                        break;

                    default:
                        Failure("Unknown action.");
                        break;
                }
            }
            catch (SupabaseApiException ex) when (ex.StatusCode != 401)
            {
                Failure(ex.UserMessage);
            }
            return RedirectToAction(nameof(Review), new { id });
        }

        private async Task ApplyDecision(ApplicationRow app, string newStatus, string? message, string? internalNote, CancellationToken ct)
        {
            var changed = await _apps.SetStatusAsync(app.ApplicationId, app.Status, newStatus, UserId, ct);
            if (!changed)
                throw new SupabaseApiException(409, null, "Application changed or database refused the update.");

            await _apps.AddHistoryAsync(app.ApplicationId, UserId, app.Status, newStatus,
                string.IsNullOrWhiteSpace(message) ? $"Decision by administrator: {newStatus}" : message, ct);

            if (!string.IsNullOrWhiteSpace(internalNote))
                await _apps.AddNoteAsync(app.ApplicationId, UserId, internalNote.Trim(), ct);

            // The database trigger tells the parent the status changed; the reason goes as a message.
            if (!string.IsNullOrWhiteSpace(message))
            {
                await _notifications.SendAsync(new[]
                {
                    new NewNotification(app.SubmittedBy, app.ApplicationId, NotificationTypes.Message,
                        newStatus == AppStatus.Corrections ? "Corrections Requested" : "Application Update",
                        $"{app.DisplayId}: {message}")
                }, ct);
            }

            if (newStatus == AppStatus.Approved)
            {
                try { await _letters.EnsureStudentNumberAsync(app.LearnerId, _school.EffectiveYear, ct); }
                catch (SupabaseApiException ex)
                {
                    _logger.LogWarning("Student number not assigned at approval ({Code}); it will be retried when the letter is generated.", ex.Code);
                }
            }
        }

        // ------------------------------------------------------------ Notes (FR9)

        public async Task<IActionResult> Notes(Guid? id, CancellationToken ct)
        {
            var picker = await Picker(id, a => true, a => a.Status == AppStatus.Pending, ct);
            var vm = new NotesViewModel { Picker = picker };
            if (picker.SelectedId != null) vm.Notes = await _apps.NotesAsync(picker.SelectedId.Value, ct);
            return View(vm);
        }

        [HttpPost]
        public async Task<IActionResult> AddNote(Guid id, string? note, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(note)) Failure("Type a note before saving.");
            else
            {
                try { await _apps.AddNoteAsync(id, UserId, note.Trim(), ct); Success("Note saved."); }
                catch (SupabaseApiException ex) when (ex.StatusCode != 401) { Failure(ex.UserMessage); }
            }
            return RedirectToAction(nameof(Notes), new { id });
        }

        // ------------------------------------------------------------ Messaging (FR10)

        public async Task<IActionResult> Messaging(Guid? id, CancellationToken ct)
        {
            var picker = await Picker(id, a => true, a => a.Status is AppStatus.Corrections or AppStatus.Pending, ct);
            return View(new MessagingViewModel
            {
                Picker = picker,
                Recent = await _notifications.RecentSentAsync(8, ct)
            });
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(Guid id, string? message, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(message)) { Failure("Type a message first."); return RedirectToAction(nameof(Messaging), new { id }); }
            try
            {
                var app = await _apps.GetAsync(id, ct);
                if (app == null) return NotFound();
                await _notifications.SendAsync(new[]
                {
                    new NewNotification(app.SubmittedBy, app.ApplicationId, NotificationTypes.Message,
                        "Message from School", message.Trim())
                }, ct);
                Success("Message sent to the parent.");
            }
            catch (SupabaseApiException ex) when (ex.StatusCode != 401) { Failure(ex.UserMessage); }
            return RedirectToAction(nameof(Messaging), new { id });
        }

        // ------------------------------------------------------------ Reminders (FR11)

        public async Task<IActionResult> Reminders(CancellationToken ct)
        {
            var open = (await _apps.ListAsync(ct)).Where(a => AppStatus.IsOpen(a.Status)).ToList();
            return View(new ReminderViewModel { Choices = open });
        }

        [HttpPost]
        public async Task<IActionResult> SendReminder(string? target, string? type, string? message, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(target) || string.IsNullOrWhiteSpace(message))
            {
                Failure("Choose who the reminder is for and write a message.");
                return RedirectToAction(nameof(Reminders));
            }
            try
            {
                var open = (await _apps.ListAsync(ct)).Where(a => AppStatus.IsOpen(a.Status)).ToList();
                var targets = target == "all"
                    ? open.GroupBy(a => a.SubmittedBy).Select(g => g.First()).ToList()
                    : open.Where(a => a.ApplicationId.ToString() == target).ToList();

                if (targets.Count == 0) { Failure("No matching open applications."); return RedirectToAction(nameof(Reminders)); }

                var title = string.IsNullOrWhiteSpace(type) ? "Reminder" : type.Trim();
                await _notifications.SendAsync(targets.Select(a =>
                    new NewNotification(a.SubmittedBy, target == "all" ? null : a.ApplicationId,
                        NotificationTypes.Reminder, title, message.Trim())), ct);
                Success(targets.Count == 1 ? "Reminder sent." : $"Reminder sent to {targets.Count} parents.");
            }
            catch (SupabaseApiException ex) when (ex.StatusCode != 401) { Failure(ex.UserMessage); }
            return RedirectToAction(nameof(Reminders));
        }

        // ------------------------------------------------------------ Confirmation letters (FR12)

        public async Task<IActionResult> ConfirmationLetters(Guid? id, CancellationToken ct)
        {
            var picker = await Picker(id, a => AppStatus.IsDecided(a.Status), a => a.Status == AppStatus.Approved, ct);
            var vm = new LetterViewModel { Picker = picker, SchoolName = _school.Name };
            if (picker.SelectedId != null)
            {
                var full = await _apps.GetAsync(picker.SelectedId.Value, ct);
                picker.Selected = full;
                vm.StudentNumber = full?.Learner?.StudentNumber;
                vm.IdNumber = full?.Learner?.IdNumber ?? "";
                vm.Existing = await _letters.GetAsync(picker.SelectedId.Value, ct);
            }
            return View("Letters", vm);
        }

        [HttpPost]
        public async Task<IActionResult> GenerateLetter(Guid id, CancellationToken ct)
        {
            try
            {
                var app = await _apps.GetAsync(id, ct);
                if (app?.Learner == null) return NotFound();
                if (!AppStatus.IsDecided(app.Status))
                {
                    Failure("A letter can only be generated once the application is approved or rejected.");
                    return RedirectToAction(nameof(ConfirmationLetters), new { id });
                }

                var approved = app.Status == AppStatus.Approved;
                string? studentNumber = null;
                if (approved)
                {
                    studentNumber = await _letters.EnsureStudentNumberAsync(app.LearnerId, _school.EffectiveYear, ct);
                    if (string.IsNullOrWhiteSpace(studentNumber))
                    {
                        Failure("A student number could not be assigned. Run supabase/staff_access_patch.sql, then try again.");
                        return RedirectToAction(nameof(ConfirmationLetters), new { id });
                    }
                }

                var learnerName = app.Learner.NameWithoutMiddle;
                var pdf = _pdf.Build(new LetterContent
                {
                    SchoolName = _school.Name, Address = _school.Address, Telephone = _school.Telephone,
                    Approved = approved, LearnerName = learnerName, IdNumber = app.Learner.IdNumber ?? "",
                    StudentNumber = studentNumber, Grade = app.GradeAppliedFor, ApplicationRef = app.DisplayId,
                    IssuedOn = DateTime.Today
                });

                var path = $"confirmation-letters/{app.ApplicationId}.pdf";
                await _letters.UploadAsync(path, pdf, ct);
                await _letters.SaveAsync(app.ApplicationId, app.LearnerId, UserId, learnerName,
                    string.IsNullOrWhiteSpace(app.Learner.IdNumber) ? "Not provided" : app.Learner.IdNumber!,
                    studentNumber ?? "N/A", $"Confirmation-{app.DisplayId}.pdf", path, ct);

                await _notifications.SendAsync(new[]
                {
                    new NewNotification(app.SubmittedBy, app.ApplicationId, NotificationTypes.Message,
                        "Confirmation Letter",
                        $"The confirmation letter for application {app.DisplayId} has been issued by the school.")
                }, ct);

                Success("Confirmation letter generated.");
            }
            catch (SupabaseApiException ex) when (ex.StatusCode != 401) { Failure(ex.UserMessage); }
            return RedirectToAction(nameof(ConfirmationLetters), new { id });
        }

        public async Task<IActionResult> LetterFile(Guid id, CancellationToken ct)
        {
            var letter = await _letters.GetAsync(id, ct);
            if (letter?.StoragePath == null) return NotFound();
            return await Stream(letter.StoragePath, letter.FileName ?? "letter.pdf", ct);
        }

        // ------------------------------------------------------------ Files

        public async Task<IActionResult> DocumentFile(Guid id, CancellationToken ct)
        {
            var doc = await _apps.GetDocumentAsync(id, ct);
            if (doc?.StoragePath == null) return NotFound();
            return await Stream(doc.StoragePath, doc.FileName ?? "document", ct);
        }

       

        private async Task<IActionResult> Stream(string path, string fileName, CancellationToken ct)
        {
            var file = await _files.DownloadAsync(path, ct);
            if (file == null) return NotFound();
            Response.Headers.ContentDisposition = $"inline; filename=\"{Uri.EscapeDataString(fileName)}\"";
            return File(file.Value.Bytes, file.Value.ContentType);
        }

        // ------------------------------------------------------------ helpers

        private async Task<ApplicationPickerViewModel> Picker(Guid? id, Func<ApplicationRow, bool> eligible,
            Func<ApplicationRow, bool> preferred, CancellationToken ct)
        {
            var choices = (await _apps.ListAsync(ct)).Where(eligible).ToList();
            var selected = id != null ? choices.FirstOrDefault(a => a.ApplicationId == id)
                : choices.FirstOrDefault(preferred) ?? choices.FirstOrDefault();
            selected ??= choices.FirstOrDefault();
            return new ApplicationPickerViewModel { Choices = choices, Selected = selected, SelectedId = selected?.ApplicationId };
        }
    }
}
