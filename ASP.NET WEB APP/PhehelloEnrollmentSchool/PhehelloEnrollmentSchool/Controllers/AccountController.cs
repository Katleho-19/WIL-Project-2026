using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;
using PhehelloEnrollmentSchool.Services;

namespace PhehelloEnrollmentSchool.Controllers
{
    public class AccountController : Controller
    {
        private readonly SupabaseAuthService _auth;
        private readonly SupabaseClient _db;
        private readonly ILogger<AccountController> _logger;

        public AccountController(SupabaseAuthService auth, SupabaseClient db, ILogger<AccountController> logger)
        {
            _auth = auth;
            _db = db;
            _logger = logger;
        }

        [AllowAnonymous, HttpGet]
        public IActionResult Login(string? returnUrl = null, string? portal = null)
        {
            if (User.Identity?.IsAuthenticated == true)
                return Redirect(StaffPrincipal.HomeFor(User.FindFirstValue(ClaimTypes.Role)));

            return View(new LoginViewModel
            {
                ReturnUrl = returnUrl,
                Portal = portal == StaffRoles.FinancialClerk ? StaffRoles.FinancialClerk : StaffRoles.Administrator
            });
        }

        [AllowAnonymous, HttpPost]
        public async Task<IActionResult> Login(LoginViewModel model, CancellationToken ct)
        {
            model.Portal = model.Portal == StaffRoles.FinancialClerk ? StaffRoles.FinancialClerk : StaffRoles.Administrator;
            if (!ModelState.IsValid) return View(model);

            AuthSession session;
            try
            {
                session = await _auth.LoginAsync(model.Email.Trim(), model.Password, ct);
            }
            catch (SupabaseAuthException ex)
            {
                _logger.LogInformation("Staff sign-in rejected by Supabase ({Status} {Code}).", ex.StatusCode, ex.ErrorCode);
                ModelState.AddModelError(string.Empty, ex.ErrorCode == "email_not_confirmed"
                    ? "Your email address has not been confirmed yet."
                    : "Incorrect email or password.");
                return View(model);
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Could not reach Supabase Auth.");
                ModelState.AddModelError(string.Empty, "The sign-in service is unavailable. Check your internet connection and try again.");
                return View(model);
            }

            // The role comes from the database (profiles.role), never from what the user clicked.
            ProfileRow? profile;
            try
            {
                var rows = await _db.SelectAsync<ProfileRow>("profiles",
                    $"select=*&{SupabaseClient.Eq("id", session.UserId)}&limit=1", ct, session.AccessToken);
                profile = rows.FirstOrDefault();
            }
            catch (SupabaseApiException ex)
            {
                _logger.LogError(ex, "Could not read the staff profile.");
                ModelState.AddModelError(string.Empty, "Signed in, but your staff profile could not be read. Please contact the system administrator.");
                return View(model);
            }

            if (profile == null || !StaffRoles.IsStaff(profile.Role))
            {
                ModelState.AddModelError(string.Empty, "This account is not authorised for the staff portal.");
                return View(model);
            }
            if (profile.Role != model.Portal)
            {
                ModelState.AddModelError(string.Empty, $"This account is not a {model.Portal} account. Choose the \"{profile.Role}\" tab.");
                return View(model);
            }

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                StaffPrincipal.Create(session, profile),
                new AuthenticationProperties { IsPersistent = model.RememberMe });

            if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
                return LocalRedirect(model.ReturnUrl);
            return Redirect(StaffPrincipal.HomeFor(profile.Role));
        }

        /// <summary>The "Are you sure you want to log out?" screen.</summary>
        [Authorize, HttpGet]
        public IActionResult Logout() => View();

        [Authorize, HttpPost]
        public async Task<IActionResult> LogoutConfirmed(CancellationToken ct)
        {
            var token = User.FindFirstValue(SessionClaims.AccessToken);
            try
            {
                if (!string.IsNullOrWhiteSpace(token)) await _auth.LogoutAsync(token, ct);
            }
            catch (Exception ex) when (ex is SupabaseAuthException or HttpRequestException)
            {
                // Never block a local sign-out because the remote call failed.
                _logger.LogInformation("Remote sign-out failed ({Type}); signing out locally.", ex.GetType().Name);
            }

            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction(nameof(Login));
        }

        [AllowAnonymous, HttpGet]
        public IActionResult ForgotPassword() => View(new ForgotPasswordViewModel());

        [AllowAnonymous, HttpPost]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model, CancellationToken ct)
        {
            if (!ModelState.IsValid) return View(model);
            try { await _auth.RecoverAsync(model.Email.Trim(), ct); }
            catch (Exception ex) when (ex is SupabaseAuthException or HttpRequestException)
            {
                _logger.LogInformation("Password recovery request failed ({Type}).", ex.GetType().Name);
            }
            // Same answer whether or not the address exists.
            TempData["Success"] = "If that email belongs to a staff account, a password reset link has been sent.";
            return RedirectToAction(nameof(Login));
        }

        [AllowAnonymous, HttpGet]
        public IActionResult AccessDenied() => View();
    }
}
