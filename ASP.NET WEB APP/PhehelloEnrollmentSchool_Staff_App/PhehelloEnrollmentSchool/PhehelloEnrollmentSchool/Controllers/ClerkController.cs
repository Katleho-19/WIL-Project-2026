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
        private const int PageSize = 10;

        private readonly IPaymentRepository _payments;
        private readonly INotificationRepository _notifications;
        private readonly IFileRepository _files;
        private readonly SchoolOptions _school;

        public ClerkController(IPaymentRepository payments, INotificationRepository notifications,
            IFileRepository files, IOptions<SchoolOptions> school)
        {
            _payments = payments; _notifications = notifications; _files = files; _school = school.Value;
        }

        /// <summary>
        /// If payments come back without their application, the database (Row Level Security) is hiding the
        /// application / parent rows from the Financial Clerk. Say so instead of showing empty cells.
        /// </summary>
        private void WarnIfApplicationsHidden(IEnumerable<PaymentRow> payments)
        {
            if (payments.Any(p => p.Application == null))
                ViewData["AccessWarning"] =
                    "Application ID and Parent Name cannot be loaded: the database is not letting the Financial Clerk " +
                    "read the linked application. Run supabase/clerk_payment_access.sql in the Supabase SQL Editor.";
        }

        public async Task<IActionResult> Dashboard(CancellationToken ct)
        {
            var all = await _payments.ListAsync(ct);
            WarnIfApplicationsHidden(all);
            var verified = all.Where(p => p.VerificationStatus == PayStatus.Verified).ToList();
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

        public Task<IActionResult> PaymentVerification(ListFilter f, CancellationToken ct) =>
            List("Payment Verification", "Check and verify proof of payment against school records.",
                "PaymentVerification", "verification", null, f, ct);

        public Task<IActionResult> PaymentDetails(ListFilter f, CancellationToken ct) =>
            List("Payment Details", "View detailed information about a specific payment.",
                "PaymentDetails", "details", null, f, ct);

        public Task<IActionResult> VerifiedPayments(ListFilter f, CancellationToken ct) =>
            List("Verified Payments", "Review and manage submitted enrolment payments.",
                "VerifiedPayments", "verified", PayStatus.Verified, f, ct);

        private async Task<IActionResult> List(string title, string subtitle, string action, string mode,
            string? fixedStatus, ListFilter f, CancellationToken ct)
        {
            var all = await _payments.ListAsync(ct);
            WarnIfApplicationsHidden(all);
            var year = f.Year > 0 ? f.Year : _school.EffectiveYear;
            var status = fixedStatus ?? f.Status;

            var items = all
                .Where(p => (p.CreatedAt?.LocalDateTime.Year ?? year) == year)
                .Where(p => string.IsNullOrWhiteSpace(status) || p.VerificationStatus == status)
                .Where(p => ListFiltering.Matches(f.Search, p.Application?.DisplayId, p.Application?.ParentName, p.PaymentReference))
                .ToList();

            var pages = Math.Max(1, (int)Math.Ceiling(items.Count / (double)PageSize));
            var page = Math.Clamp(f.Page, 1, pages);
            f.Year = year; f.Status = status; f.Page = page;

            var paged = mode == "verification" ? items : items.Skip((page - 1) * PageSize).Take(PageSize).ToList();

            return View("List", new PaymentListViewModel
            {
                Title = title, Subtitle = subtitle, Action = action, Mode = mode, Items = paged,
                Filters = new FilterBar
                {
                    Filter = f,
                    StatusOptions = new() { PayStatus.Pending, PayStatus.Verified, PayStatus.Rejected },
                    StatusLocked = fixedStatus != null,
                    Years = ListFiltering.Years(all.Select(p => p.CreatedAt?.LocalDateTime.Year ?? year), _school.EffectiveYear),
                    SearchPlaceholder = "Search by application ID or parent name...",
                    Action = action, Controller = "Clerk"
                },
                Pager = mode == "verification" || pages <= 1 ? null
                    : new Pager { Page = page, PageCount = pages, Action = action, Controller = "Clerk", Filter = f }
            });
        }

        public async Task<IActionResult> Proof(Guid id, CancellationToken ct)
        {
            var payment = await _payments.GetAsync(id, ct);
            if (payment == null) return NotFound();

            WarnIfApplicationsHidden(new[] { payment });

            var name = (payment.ProofFileName ?? payment.ProofStoragePath ?? "").ToLowerInvariant();
            return View(new ProofViewModel
            {
                Payment = payment,
                SchoolRecord = await _payments.FindSchoolRecordAsync(payment.PaymentReference, ct),
                IsImage = new[] { ".png", ".jpg", ".jpeg", ".webp", ".gif" }.Any(name.EndsWith),
                IsPdf = name.EndsWith(".pdf"),
                CanDecide = payment.VerificationStatus == PayStatus.Pending
            });
        }

        [HttpPost]
        public async Task<IActionResult> Decide(Guid id, string decision, string? note, CancellationToken ct)
        {
            note = note?.Trim();
            try
            {
                var payment = await _payments.GetAsync(id, ct);
                if (payment == null) return NotFound();

                var approve = decision == "approve";
                if (!approve && decision != "reject") { Failure("Unknown action."); return RedirectToAction(nameof(Proof), new { id }); }
                if (!approve && string.IsNullOrWhiteSpace(note))
                {
                    Failure("Enter a decision note explaining why the payment is rejected.");
                    return RedirectToAction(nameof(Proof), new { id });
                }

                var record = approve ? await _payments.FindSchoolRecordAsync(payment.PaymentReference, ct) : null;
                var changed = await _payments.DecideAsync(id, approve ? PayStatus.Verified : PayStatus.Rejected,
                    note, UserId, record?.SchoolPaymentRecordId, ct);

                if (!changed)
                {
                    Failure("This payment was already decided or you are not allowed to change it.");
                    return RedirectToAction(nameof(Proof), new { id });
                }

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
            catch (SupabaseApiException ex) when (ex.StatusCode != 401)
            {
                Failure(ex.UserMessage);
                return RedirectToAction(nameof(Proof), new { id });
            }
        }

        public async Task<IActionResult> ProofFile(Guid id, CancellationToken ct)
        {
            var payment = await _payments.GetAsync(id, ct);
            if (payment?.ProofStoragePath == null) return NotFound();

            var file = await _files.DownloadAsync(payment.ProofStoragePath, ct);
            if (file == null) return NotFound();
            Response.Headers.ContentDisposition = $"inline; filename=\"{Uri.EscapeDataString(payment.ProofFileName ?? "proof")}\"";
            return File(file.Value.Bytes, file.Value.ContentType);
        }
    }
}
