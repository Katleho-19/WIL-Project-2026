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

namespace PhehelloEnrollmentSchool.Controllers
{
    /// <summary>Financial Clerk: payment information only (NFR6).</summary>
    [Authorize(Policy = Policies.FinancialClerk)]
    public class ClerkController : StaffControllerBase
    {
        // Number of payments shown per page on the Verified Payments / Payment Details lists.
        private const int PageSize = 10;

        // Dependencies supplied by dependency injection:
        // _payments      - reads and updates payment records
        // _notifications - sends in-app messages to parents
        // _files         - downloads proof-of-payment files from Supabase Storage
        // _school        - school settings (academic year, admissions open/closed)
        private readonly IPaymentRepository _payments;
        private readonly INotificationRepository _notifications;
        private readonly IFileRepository _files;
        private readonly SchoolOptions _school;

        /// <summary>Constructor. Stores the injected repositories and the school settings (IOptions gives the bound SchoolOptions object).</summary>
        public ClerkController(IPaymentRepository payments, INotificationRepository notifications,
            IFileRepository files, IOptions<SchoolOptions> school)
        {
            _payments = payments; _notifications = notifications; _files = files; _school = school.Value;
        }

        /// <summary>
        /// If payments come back without their application, the database (Row Level Security) is hiding the
        /// application / parent rows from the Financial Clerk. Say so instead of showing empty cells.
        /// </summary>
        /// 
        /// <summary>A payment is a resubmission when the same application already had an earlier payment.</summary>
        private static void MarkResubmissions(List<PaymentRow> all)
        {
            foreach (var g in all.GroupBy(p => p.ApplicationId))
            {
                var first = g.OrderBy(p => p.CreatedAt).First();
                foreach (var p in g) p.IsResubmission = p.PaymentId != first.PaymentId;
            }
        }
        private void WarnIfApplicationsHidden(IEnumerable<PaymentRow> payments)
        {
            if (payments.Any(p => p.Application == null))
                ViewData["AccessWarning"] =
                    "Application ID and Parent Name cannot be loaded: the database is not letting the Financial Clerk " +
                    "read the linked application. Run supabase/clerk_payment_access.sql in the Supabase SQL Editor.";
        }

        /// <summary>GET /Clerk/Dashboard - summary cards, weekly payment chart and the five most recent payments.</summary>
        public async Task<IActionResult> Dashboard(CancellationToken ct)
        {
            // Load every payment the clerk is allowed to see.
            var all = await _payments.ListAsync(ct);
            MarkResubmissions(all);
            WarnIfApplicationsHidden(all);
            // Only verified payments count towards the "Total Verified Amount" card.
            var verified = all.Where(p => p.VerificationStatus == PayStatus.Verified).ToList();
            // Build the dashboard model: counts per status, the verified total, distinct applications, the latest five payments and the chart data.
            return View(new ClerkDashboardViewModel
            {
                Awaiting = all.Count(p => p.VerificationStatus == PayStatus.Pending),
                Verified = verified.Count,
                VerifiedAmount = verified.Sum(p => p.Amount ?? 0),
                ApplicationsWithPayments = all.Select(p => p.ApplicationId).Distinct().Count(),
                Recent = all.Take(5).ToList(),
                Weeks = AdminController.WeeklyTrend(all.Select(p => (p.CreatedAt?.LocalDateTime ?? DateTime.Today)), "Payments submitted"),
                YearLabel = $"{_school.EffectiveYear} Enrolment",
                Open = _school.AdmissionsOpen
            });
        }

        /// <summary>GET /Clerk/PaymentVerification - all payments, with a Verify/View button so the clerk can check proof against school records.</summary>
        public Task<IActionResult> PaymentVerification(ListFilter f, CancellationToken ct) =>
            List("Payment Verification", "Check and verify proof of payment against school records.",
                "PaymentVerification", "verification", null, f, ct);

        /// <summary>GET /Clerk/PaymentDetails - read-only list showing each payment's proof file and submission date.</summary>
        public Task<IActionResult> PaymentDetails(ListFilter f, CancellationToken ct) =>
            List("Payment Details", "View detailed information about a specific payment.",
                "PaymentDetails", "details", null, f, ct);

        /// <summary>GET /Clerk/VerifiedPayments - only payments that have been verified (the status filter is locked).</summary>
        public Task<IActionResult> VerifiedPayments(ListFilter f, CancellationToken ct) =>
            List("Verified Payments", "Review and manage submitted enrolment payments.",
                "VerifiedPayments", "verified", PayStatus.Verified, f, ct);

        /// <summary>
        /// Shared implementation behind the three list pages.
        /// title/subtitle = page headings; action = action name used by the filter bar and pager;
        /// mode = "verification", "details" or "verified" (controls which columns the view shows);
        /// fixedStatus = a status the user cannot change (null for no lock); f = search/status/year/page filter.
        /// </summary>
        private async Task<IActionResult> List(string title, string subtitle, string action, string mode,
            string? fixedStatus, ListFilter f, CancellationToken ct)
        {
            var all = await _payments.ListAsync(ct);
            MarkResubmissions(all);
            WarnIfApplicationsHidden(all);
            // Use the chosen academic year, or the school's current year when none was picked.
            var year = f.Year > 0 ? f.Year : _school.EffectiveYear;
            var status = fixedStatus ?? f.Status;

            // Apply the filters: academic year, status, and the search text (application id, parent name or payment reference).
            var items = all
                .Where(p => (p.CreatedAt?.LocalDateTime.Year ?? year) == year)
                .Where(p => string.IsNullOrWhiteSpace(status) || p.VerificationStatus == status)
                .Where(p => ListFiltering.Matches(f.Search, p.Application?.DisplayId, p.Application?.ParentName, p.PaymentReference))
                .ToList();

            // Work out how many pages there are and keep the requested page number within range.
            var pages = Math.Max(1, (int)Math.Ceiling(items.Count / (double)PageSize));
            var page = Math.Clamp(f.Page, 1, pages);
            f.Year = year; f.Status = status; f.Page = page;

            // The verification list shows everything on one page; the other lists are cut into pages of PageSize.
            var paged = mode == "verification" ? items : items.Skip((page - 1) * PageSize).Take(PageSize).ToList();

            // Render the shared List view with the rows, filter bar and pager.
            return View("List", new PaymentListViewModel
            {
                Title = title,
                Subtitle = subtitle,
                Action = action,
                Mode = mode,
                Items = paged,
                Filters = new FilterBar
                {
                    Filter = f,
                    StatusOptions = new() { PayStatus.Pending, PayStatus.Verified, PayStatus.Rejected },
                    StatusLocked = fixedStatus != null,
                    Years = ListFiltering.Years(all.Select(p => p.CreatedAt?.LocalDateTime.Year ?? year), _school.EffectiveYear),
                    SearchPlaceholder = "Search by application ID or parent name...",
                    Action = action,
                    Controller = "Clerk"
                },
                Pager = mode == "verification" || pages <= 1 ? null
                    : new Pager { Page = page, PageCount = pages, Action = action, Controller = "Clerk", Filter = f }
            });
        }

        /// <summary>GET /Clerk/Proof/{id} - shows one payment: the uploaded proof (image or PDF), its details and the matching school record, if any.</summary>
        public async Task<IActionResult> Proof(Guid id, CancellationToken ct)
        {
            var payment = await _payments.GetAsync(id, ct);
            // Unknown payment id: return the 404 page.
            if (payment == null) return NotFound();

            WarnIfApplicationsHidden(new[] { payment });

            // File name in lower case, used to decide whether the proof is an image or a PDF.
            var name = (payment.ProofFileName ?? payment.ProofStoragePath ?? "").ToLowerInvariant();
            return View(new ProofViewModel
            {
                Payment = payment,
                // Look for a school payment record with the same reference so the clerk can compare them.
                SchoolRecord = await _payments.FindSchoolRecordAsync(payment.PaymentReference, ct),
                IsImage = new[] { ".png", ".jpg", ".jpeg", ".webp", ".gif" }.Any(name.EndsWith),
                IsPdf = name.EndsWith(".pdf"),
                CanDecide = payment.VerificationStatus == PayStatus.Pending
            });
        }

        /// <summary>
        /// POST /Clerk/Decide - the clerk approves or rejects a payment.
        /// Rejecting requires a note. The parent is notified of the outcome.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Decide(Guid id, string decision, string? note, CancellationToken ct)
        {
            // Remove stray spaces from the clerk's note.
            note = note?.Trim();
            try
            {
                var payment = await _payments.GetAsync(id, ct);
                if (payment == null) return NotFound();

                // true = approve, false = reject. Any other value is treated as an invalid request.
                var approve = decision == "approve";
                if (!approve && decision != "reject") { Failure("Unknown action."); return RedirectToAction(nameof(Proof), new { id }); }
                // A rejection must explain why, because the parent sees this note.
                if (!approve && string.IsNullOrWhiteSpace(note))
                {
                    Failure("Enter a decision note explaining why the payment is rejected.");
                    return RedirectToAction(nameof(Proof), new { id });
                }

                // When approving, link the payment to the matching school payment record (null if none is found).
                var record = approve ? await _payments.FindSchoolRecordAsync(payment.PaymentReference, ct) : null;
                // Save the decision. Returns false when the payment was already decided or the database refused the update.
                var changed = await _payments.DecideAsync(id, approve ? PayStatus.Verified : PayStatus.Rejected,
                    note, UserId, record?.SchoolPaymentRecordId, ct);

                if (!changed)
                {
                    Failure("This payment was already decided or you are not allowed to change it.");
                    return RedirectToAction(nameof(Proof), new { id });
                }

                // Notify the parent who submitted the application (only possible when the application row is readable).
                var app = payment.Application;
                if (app != null)
                {
                    await _notifications.SendAsync(new[]
                    {
                        new NewNotification(app.SubmittedBy, app.ApplicationId, NotificationTypes.Message,
                            approve ? "Payment Verified" : "Payment Rejected",
                            approve
                                ? $"Your payment for application {app.DisplayId} has been verified."
                                : $"Your payment for application {app.DisplayId} was rejected: {note} Please upload a new proof of payment.")
                    }, ct);
                }

                Success(approve ? "Payment verified." : "Payment rejected. The parent has been notified.");
                return RedirectToAction(nameof(PaymentVerification));
            }
            // Show database errors to the clerk as a message; a 401 (session expired) is left to the global handler so the user is sent to log in again.
            catch (SupabaseApiException ex) when (ex.StatusCode != 401)
            {
                Failure(ex.UserMessage);
                return RedirectToAction(nameof(Proof), new { id });
            }
        }

        /// <summary>GET /Clerk/ProofFile/{id} - streams the proof-of-payment file so it can be shown inline in the page or opened in a new tab.</summary>
        public async Task<IActionResult> ProofFile(Guid id, CancellationToken ct)
        {
            var payment = await _payments.GetAsync(id, ct);
            if (payment?.ProofStoragePath == null) return NotFound();

            // Download the file bytes and content type from Supabase Storage.
            var file = await _files.DownloadAsync(payment.ProofStoragePath, ct);
            if (file == null) return NotFound();
            // inline = display in the browser rather than force a download.
            Response.Headers.ContentDisposition = $"inline; filename=\"{Uri.EscapeDataString(payment.ProofFileName ?? "proof")}\"";
            return File(file.Value.Bytes, file.Value.ContentType);
        }
    }
}