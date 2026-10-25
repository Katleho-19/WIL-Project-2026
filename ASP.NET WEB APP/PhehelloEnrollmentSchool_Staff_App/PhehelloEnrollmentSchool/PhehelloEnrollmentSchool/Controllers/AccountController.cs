/*
    Group Members

    Katleho Makhoali 224131387
    Paballo Lebusa 221000537
    Lerato Mahlatsi 220049867
    David Adegbola 220042034
    Mpho Motaung 224074632
    Mamello Lepitla 222018199
*/

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
    /// <summary>
    /// Handles staff authentication for the web portal: sign-in, sign-out, password recovery and the access-denied page.
    /// Authentication is delegated to Supabase Auth; the user's role is read from the profiles table.
    /// </summary>
    public class AccountController : Controller
    {
        // Dependencies supplied by dependency injection:
        // _auth   - Supabase Auth service (login, logout, password recovery)
        // _db     - Supabase database client (used to read the staff profile)
        // _logger - writes diagnostic messages to the application log
        private readonly SupabaseAuthService _auth;
        private readonly SupabaseClient _db;
        private readonly ILogger<AccountController> _logger;

        /// <summary>Constructor. ASP.NET Core injects the services and the controller keeps them in the private fields above.</summary>
        public AccountController(SupabaseAuthService auth, SupabaseClient db, ILogger<AccountController> logger)
        {
            _auth = auth;
            _db = db;
            _logger = logger;
        }

        /// <summary>
        /// GET /Account/Login - shows the staff login form.
        /// returnUrl is the page to return to after signing in; portal pre-selects the Administrator or Financial Clerk tab.
        /// </summary>
        [AllowAnonymous, HttpGet]
        public IActionResult Login(string? returnUrl = null, string? portal = null)
        {
            // Already signed in? Skip the form and go straight to the dashboard for this user's role.
            if (User.Identity?.IsAuthenticated == true)
                return Redirect(StaffPrincipal.HomeFor(User.FindFirstValue(ClaimTypes.Role)));

            // Show the login form. Any portal value other than "Financial Clerk" falls back to the Administrator tab.
            return View(new LoginViewModel
            {
                ReturnUrl = returnUrl,
                Portal = portal == StaffRoles.FinancialClerk ? StaffRoles.FinancialClerk : StaffRoles.Administrator
            });
        }

        /// <summary>
        /// POST /Account/Login - validates the form, signs in through Supabase Auth, loads the staff profile,
        /// checks the role matches the chosen tab, then issues the authentication cookie.
        /// </summary>
        [AllowAnonymous, HttpPost]
        public async Task<IActionResult> Login(LoginViewModel model, CancellationToken ct)
        {
            // Sanitise the posted portal tab so only the two valid values are ever used.
            model.Portal = model.Portal == StaffRoles.FinancialClerk ? StaffRoles.FinancialClerk : StaffRoles.Administrator;
            // Validation failed (e.g. empty email or password): redisplay the form with the error messages.
            if (!ModelState.IsValid) return View(model);

            // Will hold the Supabase session (user id and access token) returned by a successful login.
            AuthSession session;
            try
            {
                // Ask Supabase Auth to verify the email and password.
                session = await _auth.LoginAsync(model.Email.Trim(), model.Password, ct);
            }
            // Supabase refused the login (wrong password, unconfirmed email, ...). Log it and show a friendly message instead of the raw error.
            catch (SupabaseAuthException ex)
            {
                _logger.LogInformation("Staff sign-in rejected by Supabase ({Status} {Code}).", ex.StatusCode, ex.ErrorCode);
                ModelState.AddModelError(string.Empty, ex.ErrorCode == "email_not_confirmed"
                    ? "Your email address has not been confirmed yet."
                    : "Incorrect email or password.");
                return View(model);
            }
            // Network problem: Supabase could not be reached at all.
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Could not reach Supabase Auth.");
                ModelState.AddModelError(string.Empty, "The sign-in service is unavailable. Check your internet connection and try again.");
                return View(model);
            }

            // The role comes from the database (profiles.role), never from what the user clicked.
            // Load this user's row from the profiles table. Its Role column decides what the user may access.
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

            // Reject accounts with no profile or with a non-staff role (for example a parent account).
            if (profile == null || !StaffRoles.IsStaff(profile.Role))
            {
                ModelState.AddModelError(string.Empty, "This account is not authorised for the staff portal.");
                return View(model);
            }
            // Valid staff account, but the wrong tab was chosen (e.g. a clerk on the Administrator tab). Tell the user which tab to use.
            if (profile.Role != model.Portal)
            {
                ModelState.AddModelError(string.Empty, $"This account is not a {model.Portal} account. Choose the \"{profile.Role}\" tab.");
                return View(model);
            }

            // Create the authentication cookie containing the user's claims. "Remember me" makes the cookie persist after the browser closes.
            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                StaffPrincipal.Create(session, profile),
                new AuthenticationProperties { IsPersistent = model.RememberMe });

            // Return the user to the page they originally asked for. IsLocalUrl blocks open-redirect attacks to other websites.
            // Otherwise send them to the dashboard for their role.
            if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
                return LocalRedirect(model.ReturnUrl);
            return Redirect(StaffPrincipal.HomeFor(profile.Role));
        }

        /// <summary>The "Are you sure you want to log out?" screen.</summary>
        [Authorize, HttpGet]
        public IActionResult Logout() => View();

        /// <summary>POST /Account/LogoutConfirmed - ends the Supabase session, deletes the local cookie and returns to the login page.</summary>
        [Authorize, HttpPost]
        public async Task<IActionResult> LogoutConfirmed(CancellationToken ct)
        {
            // The Supabase access token that was stored as a claim when the user signed in.
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

            // Delete the authentication cookie - the user is now signed out of the portal.
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction(nameof(Login));
        }

        /// <summary>GET /Account/ForgotPassword - shows the form where staff enter their email to request a reset link.</summary>
        [AllowAnonymous, HttpGet]
        public IActionResult ForgotPassword() => View(new ForgotPasswordViewModel());

        /// <summary>
        /// POST /Account/ForgotPassword - asks Supabase to email a reset link.
        /// The reply is always the same so nobody can discover which emails are registered.
        /// </summary>
        [AllowAnonymous, HttpPost]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model, CancellationToken ct)
        {
            // Redisplay the form if the email is missing or badly formatted.
            if (!ModelState.IsValid) return View(model);
            // Request the reset email. Failures are logged but never revealed to the user.
            try { await _auth.RecoverAsync(model.Email.Trim(), ct); }
            catch (Exception ex) when (ex is SupabaseAuthException or HttpRequestException)
            {
                _logger.LogInformation("Password recovery request failed ({Type}).", ex.GetType().Name);
            }
            // Same answer whether or not the address exists.
            TempData["Success"] = "If that email belongs to a staff account, a password reset link has been sent.";
            return RedirectToAction(nameof(Login));
        }

        /// <summary>GET /Account/AccessDenied - shown when a signed-in user opens a page their role is not allowed to see.</summary>
        [AllowAnonymous, HttpGet]
        public IActionResult AccessDenied() => View();
    }
}