//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: Program.cs is the entry point of the ASP.NET Core 8 staff web app (Administrator and Financial
// Clerk portal). It reads the settings, registers all services (Supabase access, repositories, the PDF letter service,
// MVC, cookie login and role policies) and then builds the request pipeline that every web request passes through.

using Microsoft.AspNetCore.Authentication.Cookies;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Repositories;
using PhehelloEnrollmentSchool.Services;

// Program (top-level statements) - the code below runs once when the web app starts.
// WebApplication.CreateBuilder() creates the builder that collects settings and services before the app is built.
var builder = WebApplication.CreateBuilder(args);

// Configuration: binds the "Supabase" section of appsettings.json to SupabaseOptions and checks, when the app starts,
// that the project URL and the public key are filled in (the app refuses to start otherwise).
// ---- Configuration (appsettings.json / user-secrets / environment variables) ----
builder.Services.AddOptions<SupabaseOptions>()
    .Bind(builder.Configuration.GetSection(SupabaseOptions.SectionName))
    .Validate(o => !string.IsNullOrWhiteSpace(o.Url) && !string.IsNullOrWhiteSpace(o.PublishableKey),
        "Supabase:Url and Supabase:PublishableKey must be set in appsettings.json.")
    .ValidateOnStart();
// Configuration: binds the "School" section (name, motto, phone, address, academic year, admissions open) to SchoolOptions.
builder.Services.Configure<SchoolOptions>(builder.Configuration.GetSection(SchoolOptions.SectionName));

// Supabase access: lets services read the current web request (to find the signed-in staff member's access token), and registers
// two HTTP clients - SupabaseAuthService (sign-in) and SupabaseClient (database and file storage).
// ---- Supabase access (REST + Auth + Storage over HTTPS) ----
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient<SupabaseAuthService>();
builder.Services.AddHttpClient<SupabaseClient>();
// Repositories: one instance per web request for the applications, payments, notifications, letters and files data classes.
// ConfirmationLetterPdf is a singleton (one shared instance) because it holds no per-request data.
builder.Services.AddScoped<IApplicationRepository, ApplicationRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<ILetterRepository, LetterRepository>();
builder.Services.AddScoped<IFileRepository, FileRepository>();
builder.Services.AddSingleton<ConfirmationLetterPdf>();

// MVC: turns on controllers and Razor views. Every POST form must carry an anti-forgery token (AutoValidateAntiforgeryToken), and
// SupabaseExceptionFilter converts database/permission errors into a friendly page or sends the user back to the login screen.
// ---- MVC ----
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add(new Microsoft.AspNetCore.Mvc.AutoValidateAntiforgeryTokenAttribute());
    options.Filters.Add<SupabaseExceptionFilter>();
});

// Authentication: ONE cookie scheme. Staff sign in with Supabase and their session is kept in the "Phehello.Staff" cookie
// (HTTP-only, valid for 8 hours, no sliding renewal). SupabaseCookieEvents refreshes the Supabase token in the background. Login and
// access-denied pages are /Account/Login and /Account/AccessDenied.
// ---- Authentication: ONE cookie scheme (registering it twice crashes the app at startup) ----
builder.Services.AddScoped<SupabaseCookieEvents>();
builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.Cookie.Name = "Phehello.Staff";
        options.Cookie.HttpOnly = true;
        // SameAsRequest keeps http://localhost working while developing; it is Secure automatically on HTTPS.
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.SlidingExpiration = false;
        options.EventsType = typeof(SupabaseCookieEvents);
    });

// Authorization: two policies that keep the roles strictly separate - AdministratorOnly and FinancialClerkOnly (NFR1, NFR6).
// Each one requires a signed-in user with the matching role.
// ---- Authorization: strict role separation (NFR1, NFR6) ----
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(Policies.Administrator, p => p.RequireAuthenticatedUser().RequireRole(StaffRoles.Administrator));
    options.AddPolicy(Policies.FinancialClerk, p => p.RequireAuthenticatedUser().RequireRole(StaffRoles.FinancialClerk));
});

// The app is built here; everything below configures the request pipeline in the order requests pass through it.
var app = builder.Build();

// Outside development (production): show /Home/Error for unhandled errors, send the HSTS header and redirect HTTP to HTTPS.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
    app.UseHttpsRedirection();
}

// Small custom middleware that adds security headers to every response: no content-type sniffing, framing only by the same site, and a same-origin referrer policy.
app.Use(async (context, next) =>
{
    var h = context.Response.Headers;
    h["X-Content-Type-Options"] = "nosniff";
    h["X-Frame-Options"] = "SAMEORIGIN";
    h["Referrer-Policy"] = "same-origin";
    await next();
});

// Pipeline: error status codes (404, 403 and so on) are shown through /Home/StatusPage; static files (css, js, images) are served;
// routing is turned on; then authentication (who is this user?) runs before authorization (is this user allowed?).
app.UseStatusCodePagesWithReExecute("/Home/StatusPage", "?code={0}");
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

// Routing: the default URL pattern is {controller}/{action}/{id?}, starting at the Home controller.
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// Starts the web server and waits for requests.
app.Run();