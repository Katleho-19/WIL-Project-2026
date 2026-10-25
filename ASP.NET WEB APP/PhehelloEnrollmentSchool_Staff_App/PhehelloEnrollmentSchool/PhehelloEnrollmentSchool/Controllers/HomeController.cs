/*
    Group Members

    Katleho Makhoali 224131387
    Paballo Lebusa 221000537
    Lerato Mahlatsi 220049867
    David Adegbola 220042034
    Mpho Motaung 224074632
    Mamello Lepitla 222018199
*/

using System.Diagnostics;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Controllers
{
    /// <summary>Entry-point controller: routes visitors to the right place and renders the shared error and status pages.</summary>
    public class HomeController : Controller
    {
        /// <summary>GET / - anonymous visitors are sent to the login page; signed-in staff go to the dashboard for their role.</summary>
        [AllowAnonymous]
        public IActionResult Index()
        {
            if (User.Identity?.IsAuthenticated != true) return RedirectToAction("Login", "Account");
            return Redirect(StaffPrincipal.HomeFor(User.FindFirstValue(ClaimTypes.Role)));
        }

        /// <summary>
        /// Shows the generic "Something went wrong" page. The request id lets a problem be traced in the logs.
        /// Caching is switched off so an error page is never served from a cache.
        /// </summary>
        [AllowAnonymous, ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error() =>
            View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });

        /// <summary>Shows a friendly page for HTTP status codes such as 404. The code is supplied by the status-code middleware in Program.cs.</summary>
        [AllowAnonymous]
        public IActionResult StatusPage(int code) => View("StatusPage", code);
    }
}