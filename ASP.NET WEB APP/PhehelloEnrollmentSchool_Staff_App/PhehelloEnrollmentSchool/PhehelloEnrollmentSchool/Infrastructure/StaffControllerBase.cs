//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: StaffControllerBase.cs contains shared building blocks for the staff controllers: a base
// controller (current user id and success/error messages), a filter that turns Supabase errors into friendly pages,
// and two small list-filtering helpers.

using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    /// <summary>
    /// StaffControllerBase (abstract class) - the common parent of the Administrator and Financial Clerk controllers.
    /// </summary>
    public abstract class StaffControllerBase : Controller
    {
        /// <summary>
        /// UserId - the signed-in staff member's id, read from the login cookie's name-identifier claim.
        /// </summary>
        protected Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        /// <summary>
        /// Success() - stores a success message that is shown once on the next page (TempData).
        /// </summary>
        protected void Success(string message) => TempData["Success"] = message;
        /// <summary>
        /// Failure() - stores an error message that is shown once on the next page (TempData).
        /// </summary>
        protected void Failure(string message) => TempData["Error"] = message;
    }

    // SupabaseExceptionFilter (class) - a filter that catches SupabaseApiException from any controller action.
    /// <summary>
    /// Turns database/permission failures into a friendly message instead of a crash page.
    /// An expired session sends the user back to the login screen.
    /// </summary>
    public sealed class SupabaseExceptionFilter : IAsyncExceptionFilter
    {
        /// <summary>
        /// OnExceptionAsync() - ignores other kinds of exceptions. If Supabase answered 401 (session expired) it signs the user out and redirects to the login page.
        /// For any other Supabase error it shows the DataError page with a user-friendly message (HTTP status 502). The exception is then marked as handled.
        /// </summary>
        public async Task OnExceptionAsync(ExceptionContext context)
        {
            if (context.Exception is not SupabaseApiException ex) return;

            if (ex.StatusCode == 401)
            {
                await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                context.Result = new RedirectToActionResult("Login", "Account", null);
            }
            else
            {
                context.Result = new ViewResult
                {
                    ViewName = "~/Views/Home/DataError.cshtml",
                    ViewData = new Microsoft.AspNetCore.Mvc.ViewFeatures.ViewDataDictionary(
                        new Microsoft.AspNetCore.Mvc.ModelBinding.EmptyModelMetadataProvider(),
                        context.ModelState)
                    { Model = ex.UserMessage },
                    StatusCode = 502
                };
            }
            context.ExceptionHandled = true;
        }
    }

    /// <summary>
    /// ListFiltering (class) - helpers used by the list pages.
    /// </summary>
    public static class ListFiltering
    {
        /// <summary>
        /// Years() - returns the distinct years seen in the data plus the current year, newest first (used for the year filter).
        /// </summary>
        public static List<int> Years(IEnumerable<int> seen, int current)
        {
            var years = seen.Append(current).Distinct().OrderByDescending(y => y).ToList();
            return years;
        }

        /// <summary>
        /// Matches() - the search test: returns true if the search box is empty, otherwise true if any of the given fields contains the search text
        /// (ignoring upper/lower case).
        /// </summary>
        public static bool Matches(string? search, params string?[] fields)
        {
            if (string.IsNullOrWhiteSpace(search)) return true;
            var s = search.Trim();
            return fields.Any(f => f != null && f.Contains(s, StringComparison.OrdinalIgnoreCase));
        }
    }
}