using System.Diagnostics;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Models;

namespace PhehelloEnrollmentSchool.Controllers
{
    public class HomeController : Controller
    {
        [AllowAnonymous]
        public IActionResult Index()
        {
            if (User.Identity?.IsAuthenticated != true) return RedirectToAction("Login", "Account");
            return Redirect(StaffPrincipal.HomeFor(User.FindFirstValue(ClaimTypes.Role)));
        }

        [AllowAnonymous, ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error() =>
            View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });

        [AllowAnonymous]
        public IActionResult StatusPage(int code) => View("StatusPage", code);
    }
}
