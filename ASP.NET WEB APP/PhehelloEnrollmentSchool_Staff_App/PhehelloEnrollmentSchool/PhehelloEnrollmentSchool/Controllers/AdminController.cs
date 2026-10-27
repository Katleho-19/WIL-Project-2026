/*
    Group Members

    Katleho Makhoali 224131387
    Paballo Lebusa 221000537
    Lerato Mahlatsi 220049867
    David Adegbola 220042034
    Mpho Motaung 224074632
    Mamello Lepitla 222018199
*/

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
    /// <summary>
    /// Administrator area: dashboard, application lists, review and decisions, notes, messages, reminders and confirmation letters.
    /// Only users who satisfy the Administrator policy can reach any action here.
    /// </summary>
    [Authorize(Policy = Policies.Administrator)]
    public class AdminController : StaffControllerBase
    {
        // The documents every application must include before it counts as complete.
        private static readonly string[] RequiredDocs =
            { "Birth Certificate", "Previous School Progress Report", "Immunisation Record" };

        // Dependencies supplied by dependency injection:
        // _apps          - applications, documents, notes and status history
        // _notifications - in-app messages and reminders sent to parents
        // _letters       - confirmation letters and student numbers
        // _files         - file downloads from Supabase Storage
        // _pdf           - builds the confirmation letter PDF
        // _school        - school settings (name, address, academic year, admissions open)
        // _logger        - application log
        private readonly IApplicationRepository _apps;
        private readonly INotificationRepository _notifications;
        private readonly ILetterRepository _letters;
        private readonly IFileRepository _files;
        private readonly ConfirmationLetterPdf _pdf;
        private readonly SchoolOptions _school;
        private readonly ILogger<AdminController> _logger;

        /// <summary>Constructor. Stores every injected service so the actions below can use them.</summary>
        public AdminController(IApplicationRepository apps, INotificationRepository notifications, ILetterRepository letters,
            IFileRepository files, ConfirmationLetterPdf pdf, IOptions<SchoolOptions> school, ILogger<AdminController> logger)
        {
            _apps = apps; _notifications = notifications; _letters = letters; _files = files; _pdf = pdf;
            _school = school.Value; _logger = logger;
        }

        // ------------------------------------------------------------ Dashboard (FR13)

        /// <summary>GET /Admin/Dashboard - totals for all, approved, rejected and pending applications, the weekly chart and the five newest applications.</summary>
        public async Task<IActionResult> Dashboard(CancellationToken ct)
        {
            // Load all applications, then count them by status in the model below.
            var all = await _apps.ListAsync(ct);
            var vm = new AdminDashboardViewModel
            {
                Total = all.Count,
                Approved = all.Count(a => a.Status == AppStatus.Approved),
                Rejected = all.Count(a => a.Status == AppStatus.Rejected),
                // "Pending" means still open: waiting for review, payment or corrections.
                Pending = all.Count(a => AppStatus.IsOpen(a.Status)),
                Recent = all.OrderByDescending(a => a.CreatedAt).Take(5).ToList(),
                // Data for the bar chart: applications submitted on each day of this week.
                Weeks = WeeklyTrend(all.Select(a => a.DisplayDate), "Applications submitted"),
                YearLabel = $"{_school.EffectiveYear} Enrolment",
                Open = _school.AdmissionsOpen
            };
            return View(vm);
        }

        /// <summary>Counts per day (Monday..Sunday) of the current week for the dashboard bar chart.</summary>
        internal static BarChartViewModel WeeklyTrend(IEnumerable<DateTime> dates, string yTitle)
        {
            // Strip the time part so dates can be compared day by day.
            var list = dates.Select(d => d.Date).ToList();
            // The chart always covers Monday to Sunday of the current week.
            var monday = StartOfWeek(DateTime.Today);

            // Build one bar for each of the 7 days: its label (Mon, Tue...), tooltip text and the number of items on that day.
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
            // Highest bar (at least 1) - used to choose the Y-axis step and maximum.
            var max = Math.Max(1, bars.Max(b => b.Count));
            var step = new[] { 1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 5000 }
                .FirstOrDefault(s => max / (double)s <= 5);
            if (step == 0) step = 10000;

            // Return everything the _WeekBars partial needs to draw the chart.
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

        /// <summary>Returns the Monday of the week that contains the given date (the .NET week starts on Sunday, so the difference is adjusted).</summary>
        private static DateTime StartOfWeek(DateTime d)
        {
            var diff = (7 + (int)d.DayOfWeek - (int)DayOfWeek.Monday) % 7;
            return d.Date.AddDays(-diff);
        }

        // ------------------------------------------------------------ Lists (FR7)

        /// <summary>GET /Admin/Applications - every application; the status can be filtered freely.</summary>
        public Task<IActionResult> Applications(ListFilter f, CancellationToken ct) =>
            List("Applications", "Applications", null, new[] { AppStatus.Pending, AppStatus.Corrections, AppStatus.Approved, AppStatus.Rejected }, f, ct);

        /// <summary>GET /Admin/Approved - approved applications only (status filter locked).</summary>
        public Task<IActionResult> Approved(ListFilter f, CancellationToken ct) =>
            List("Approved Applications", "Approved", AppStatus.Approved, new[] { AppStatus.Approved }, f, ct);

        /// <summary>GET /Admin/Rejected - rejected applications only (status filter locked).</summary>
        public Task<IActionResult> Rejected(ListFilter f, CancellationToken ct) =>
            List("Rejected Applications", "Rejected", AppStatus.Rejected, new[] { AppStatus.Rejected }, f, ct);

        /// <summary>GET /Admin/Pending - open applications (pending or corrections requested).</summary>
        public Task<IActionResult> Pending(ListFilter f, CancellationToken ct) =>
            List("Pending Applications", "Pending", null, new[] { AppStatus.Pending, AppStatus.Corrections }, f, ct,
                open: true);

        /// <summary>
        /// Shared implementation behind the four list pages.
        /// title = page heading; action = action name used for the filter bar and sidebar highlight;
        /// fixedStatus = status the user cannot change (null for none); options = statuses offered in the drop-down;
        /// f = search/status/year filter; open = true to show all open applications.
        /// </summary>
        private async Task<IActionResult> List(string title, string action, string? fixedStatus, string[] options,
            ListFilter f, CancellationToken ct, bool open = false)
        {
            var all = await _apps.ListAsync(ct);
            // Use the chosen academic year, or the school's current year when none was picked.
            var year = f.Year > 0 ? f.Year : _school.EffectiveYear;
            var status = fixedStatus ?? f.Status;

            // Apply the filters: academic year, list type/status, and the search text (application id, learner name or parent name).
            var items = all.Where(a => a.DisplayDate.Year == year)
                .Where(a => open ? AppStatus.IsOpen(a.Status) : fixedStatus == null || a.Status == fixedStatus)
                .Where(a => string.IsNullOrWhiteSpace(status) || a.Status == status)
                .Where(a => ListFiltering.Matches(f.Search, a.DisplayId, a.Learner?.FullName, a.Learner?.NameWithoutMiddle, a.ParentName))
                .ToList();

            f.Year = year; f.Status = status;
            // Render the shared List view with the filtered rows and the filter bar settings.
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

        /// <summary>
        /// GET /Admin/Review/{id} - the full review page for one application.
        /// With no id (sidebar click) it shows the "No application selected" state.
        /// </summary>
        public async Task<IActionResult> Review(Guid? id, CancellationToken ct)
        {
            // No application chosen (e.g. sidebar click) -> show the "none selected" state
            if (id == null)
                return View(new ReviewViewModel());

            var app = await _apps.GetAsync(id.Value, ct);
            // Unknown application id: return the 404 page.
            if (app == null) return NotFound();
            return View(BuildReview(app));
        }

        /// <summary>
        /// Builds the review model from an application: the document checklist, the 4-step progress bar, the status message
        /// and whether the administrator may approve or otherwise decide.
        /// </summary>
        private static ReviewViewModel BuildReview(ApplicationRow app)
        {
            var docs = app.Documents ?? new();
            var lines = new List<DocumentLine>();

            // First list each required document, marked Received or Missing.
            foreach (var type in RequiredDocs)
            {
                var doc = docs.FirstOrDefault(d => string.Equals(d.DocumentType, type, StringComparison.OrdinalIgnoreCase));
                lines.Add(DocLine(type, doc));
            }
            // Then add any extra documents the parent uploaded that are not on the required list.
            foreach (var extra in docs.Where(d => !RequiredDocs.Contains(d.DocumentType ?? "", StringComparer.OrdinalIgnoreCase)))
                lines.Add(DocLine(extra.DocumentType ?? "Other Document", extra));

            // Use the most recent payment as the "Proof of Payment" line.
            var payment = (app.Payments ?? new()).OrderByDescending(p => p.CreatedAt).FirstOrDefault();
            lines.Add(new DocumentLine
            {
                Name = "Proof of Payment",
                Status = payment?.VerificationStatus ?? "Missing",
                Chip = payment == null ? "pending" : Fmt.ChipClass(payment.VerificationStatus),
                ViewUrl = null
            });
            foreach (var l in lines)
                l.Resubmitted = app.Requests?.Any(r => r.Status == "Submitted" &&
                    string.Equals(Pretty(r.DocumentType), l.Name, StringComparison.OrdinalIgnoreCase)) == true;
            if ((app.Payments?.Count ?? 0) > 1)
                lines.First(l => l.Name == "Proof of Payment").Resubmitted = true;

            // Has the Financial Clerk verified the payment? Approval depends on this.
            var paymentVerified = app.PaymentVerificationStatus == PayStatus.Verified;
            // True when all three required documents have been received.
            var docsComplete = lines.Where(l => RequiredDocs.Select(Pretty).Contains(l.Name)).All(l => l.Status == "Received");
            var decided = AppStatus.IsDecided(app.Status);

            // Progress: 1 = submitted, 2 = payment verified, 3 = documents complete, 4 = decision made.
            var step = 1;
            if (paymentVerified) step = 2;
            if (paymentVerified && docsComplete) step = 3;
            if (decided) step = 4;

            // The message under the progress bar, chosen from the application and payment status.
            var text = app.Status switch
            {
                AppStatus.Approved => "Application approved. A confirmation letter can now be generated.",
                AppStatus.Rejected => "Application rejected. A confirmation letter can still be generated for the parent.",
                AppStatus.Corrections => "Corrections requested. Waiting for the parent to resubmit.",
                _ when app.PaymentVerificationStatus == PayStatus.Rejected => "Payment proof was rejected. Waiting for the parent to upload a new proof.",
                _ when !paymentVerified => "Waiting for the Financial Clerk to verify the proof of payment.",
                _ => "Payment verified. Application is ready for administrator decision."
            };

            // CanDecide = application is still open; CanApprove = open AND payment verified.
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

        /// <summary>Shortens the long document name "Previous School Progress Report" to "Progress Report" for display.</summary>
        private static string Pretty(string type) => type == "Previous School Progress Report" ? "Progress Report" : type;

        /// <summary>Builds one row of the document checklist: name, Received/Missing status, chip colour and a View link when a file exists.</summary>
        private static DocumentLine DocLine(string type, DocumentRow? doc) => new()
        {
            Name = Pretty(type),
            Status = doc == null ? "Missing" : "Received",
            Chip = doc == null ? "pending" : "approved",
            ViewUrl = doc == null ? null : $"/Admin/DocumentFile/{doc.DocumentId}"
        };

        /// <summary>
        /// POST /Admin/Decide - the administrator approves, requests corrections or rejects an application.
        /// message = text for the parent; internalNote = private note saved against the application.
        /// </summary>
        [HttpPost]
        [HttpPost]
        public async Task<IActionResult> Decide(Guid id, string decision, string? message, string? internalNote,string[]? requestedDocs, CancellationToken ct)
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
                        // Allow corrections for applications still open for review,
                        // including applications whose proof of payment was rejected.
                        if (!AppStatus.IsOpen(app.Status))
                        {
                            Failure("Corrections can only be requested on an open application.");
                            break;
                        }

                        if (requestedDocs == null || requestedDocs.Length == 0)
                        {
                            Failure("Tick at least one document the parent must resubmit.");
                            break;
                        }

                        if (string.IsNullOrWhiteSpace(message))
                        {
                            Failure("Tell the parent what needs to be corrected.");
                            break;
                        }

                        message += $"\n\nPlease resubmit: {string.Join(", ", requestedDocs)}.";

                        await ApplyDecision(app, AppStatus.Corrections, message, internalNote, ct);
                        await _apps.AddDocumentRequestsAsync(
                            app.ApplicationId, UserId, requestedDocs, message, ct);

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

        /// <summary>
        /// Carries out a decision: updates the status, records the history, saves the internal note, notifies the parent
        /// and, on approval, assigns the learner a student number.
        /// </summary>
        private async Task ApplyDecision(ApplicationRow app, string newStatus, string? message, string? internalNote, CancellationToken ct)
        {
            // Change the status only if it is still what we loaded (guards against two people deciding at once).
            var changed = await _apps.SetStatusAsync(app.ApplicationId, app.Status, newStatus, UserId, ct);
            if (!changed)
                throw new SupabaseApiException(409, null, "Application changed or database refused the update.");

            // Write an audit entry: who changed the status from what to what, and why.
            await _apps.AddHistoryAsync(app.ApplicationId, UserId, app.Status, newStatus,
                string.IsNullOrWhiteSpace(message) ? $"Decision by administrator: {newStatus}" : message, ct);

            // Save the private administrator note, if one was typed.
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

            // Approved learners receive a unique student number. If it fails here it is retried when the letter is generated.
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

        /// <summary>GET /Admin/Notes - internal notes for the selected application.</summary>
        public async Task<IActionResult> Notes(Guid? id, CancellationToken ct)
        {
            // Build the application drop-down; by default it selects the first pending application.
            var picker = await Picker(id, a => true, a => a.Status == AppStatus.Pending, ct);
            var vm = new NotesViewModel { Picker = picker };
            if (picker.SelectedId != null) vm.Notes = await _apps.NotesAsync(picker.SelectedId.Value, ct);
            return View(vm);
        }

        /// <summary>POST /Admin/AddNote - saves a new internal note against an application.</summary>
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

        /// <summary>GET /Admin/Messaging - form to message a parent, plus the eight most recently sent messages.</summary>
        public async Task<IActionResult> Messaging(Guid? id, CancellationToken ct)
        {
            var picker = await Picker(id, a => true, a => a.Status is AppStatus.Corrections or AppStatus.Pending, ct);
            return View(new MessagingViewModel
            {
                Picker = picker,
                Recent = await _notifications.RecentSentAsync(8, ct)
            });
        }

        /// <summary>POST /Admin/SendMessage - sends an in-app message to the parent who submitted the selected application.</summary>
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

        /// <summary>GET /Admin/Reminders - form for sending a deadline reminder; lists all open applications to choose from.</summary>
        public async Task<IActionResult> Reminders(CancellationToken ct)
        {
            var open = (await _apps.ListAsync(ct)).Where(a => AppStatus.IsOpen(a.Status)).ToList();
            return View(new ReminderViewModel { Choices = open });
        }

        /// <summary>POST /Admin/SendReminder - sends a reminder to one application's parent, or to every parent with an open application.</summary>
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
                // Work out who receives it: "all" = one reminder per parent (duplicates removed); otherwise only the chosen application.
                var targets = target == "all"
                    ? open.GroupBy(a => a.SubmittedBy).Select(g => g.First()).ToList()
                    : open.Where(a => a.ApplicationId.ToString() == target).ToList();

                if (targets.Count == 0) { Failure("No matching open applications."); return RedirectToAction(nameof(Reminders)); }

                // The reminder type (e.g. "Missing documents") becomes the notification title.
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

        /// <summary>GET /Admin/ConfirmationLetters - lists decided (approved or rejected) applications and shows a preview of the letter.</summary>
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

        /// <summary>POST /Admin/GenerateLetter - builds the confirmation (or outcome) letter as a PDF, stores it, records it and notifies the parent.</summary>
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

                // Approved learners get a "confirmation of enrolment" letter with a student number; rejected ones get an "outcome" letter.
                var approved = app.Status == AppStatus.Approved;
                string? studentNumber = null;
                if (approved)
                {
                    // Get the learner's existing student number or create one for the academic year.
                    studentNumber = await _letters.EnsureStudentNumberAsync(app.LearnerId, _school.EffectiveYear, ct);
                    if (string.IsNullOrWhiteSpace(studentNumber))
                    {
                        Failure("A student number could not be assigned. Run supabase/staff_access_patch.sql, then try again.");
                        return RedirectToAction(nameof(ConfirmationLetters), new { id });
                    }
                }

                var learnerName = app.Learner.NameWithoutMiddle;
                // Create the PDF in memory from the school and learner details.
                var pdf = _pdf.Build(new LetterContent
                {
                    SchoolName = _school.Name,
                    Address = _school.Address,
                    Telephone = _school.Telephone,
                    Approved = approved,
                    LearnerName = learnerName,
                    IdNumber = app.Learner.IdNumber ?? "",
                    StudentNumber = studentNumber,
                    Grade = app.GradeAppliedFor,
                    ApplicationRef = app.DisplayId,
                    IssuedOn = DateTime.Today
                });

                // Storage location of the PDF; each application has one letter, so regenerating replaces it.
                var path = $"confirmation-letters/{app.ApplicationId}.pdf";
                // Upload the PDF to Supabase Storage.
                await _letters.UploadAsync(path, pdf, ct);
                // Save the letter record (learner, ID number, student number, file name, path) in the database.
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

        /// <summary>GET /Admin/LetterFile/{id} - opens the generated letter PDF.</summary>
        public async Task<IActionResult> LetterFile(Guid id, CancellationToken ct)
        {
            var letter = await _letters.GetAsync(id, ct);
            if (letter?.StoragePath == null) return NotFound();
            return await Stream(letter.StoragePath, letter.FileName ?? "letter.pdf", ct);
        }

        // ------------------------------------------------------------ Files

        /// <summary>GET /Admin/DocumentFile/{id} - opens a document the parent uploaded (birth certificate, progress report, ...).</summary>
        public async Task<IActionResult> DocumentFile(Guid id, CancellationToken ct)
        {
            var doc = await _apps.GetDocumentAsync(id, ct);
            if (doc?.StoragePath == null) return NotFound();
            return await Stream(doc.StoragePath, doc.FileName ?? "document", ct);
        }



        /// <summary>Downloads a file from storage and returns it for inline display in the browser. Returns 404 if it cannot be found.</summary>
        private async Task<IActionResult> Stream(string path, string fileName, CancellationToken ct)
        {
            var file = await _files.DownloadAsync(path, ct);
            if (file == null) return NotFound();
            Response.Headers.ContentDisposition = $"inline; filename=\"{Uri.EscapeDataString(fileName)}\"";
            return File(file.Value.Bytes, file.Value.ContentType);
        }

        // ------------------------------------------------------------ helpers

        /// <summary>
        /// Builds the application drop-down used on the Notes, Messaging and Letters pages.
        /// eligible = which applications may be listed; preferred = which one to select when nothing was chosen.
        /// </summary>
        private async Task<ApplicationPickerViewModel> Picker(Guid? id, Func<ApplicationRow, bool> eligible,
            Func<ApplicationRow, bool> preferred, CancellationToken ct)
        {
            // All applications that qualify for this page.
            var choices = (await _apps.ListAsync(ct)).Where(eligible).ToList();
            // Select the requested application, otherwise the preferred one, otherwise the first.
            var selected = id != null ? choices.FirstOrDefault(a => a.ApplicationId == id)
                : choices.FirstOrDefault(preferred) ?? choices.FirstOrDefault();
            selected ??= choices.FirstOrDefault();
            return new ApplicationPickerViewModel { Choices = choices, Selected = selected, SelectedId = selected?.ApplicationId };
        }
    }
}