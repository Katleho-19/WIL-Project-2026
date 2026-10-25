using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Infrastructure
{
    public abstract class StaffControllerBase : Controller
    {
        protected Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        protected void Success(string message) => TempData["Success"] = message;
        protected void Failure(string message) => TempData["Error"] = message;
    }

    /// <summary>
    /// Turns database/permission failures into a friendly message instead of a crash page.
    /// An expired session sends the user back to the login screen.
    /// </summary>
    public sealed class SupabaseExceptionFilter : IAsyncExceptionFilter
    {
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
                        context.ModelState) { Model = ex.UserMessage },
                    StatusCode = 502
                };
            }
            context.ExceptionHandled = true;
        }
    }

    public static class ListFiltering
    {
        public static List<int> Years(IEnumerable<int> seen, int current)
        {
            var years = seen.Append(current).Distinct().OrderByDescending(y => y).ToList();
            return years;
        }

        public static bool Matches(string? search, params string?[] fields)
        {
            if (string.IsNullOrWhiteSpace(search)) return true;
            var s = search.Trim();
            return fields.Any(f => f != null && f.Contains(s, StringComparison.OrdinalIgnoreCase));
        }
    }
}
