using Microsoft.AspNetCore.Authentication.Cookies;
using PhehelloEnrollmentSchool.Infrastructure;
using PhehelloEnrollmentSchool.Repositories;
using PhehelloEnrollmentSchool.Services;

var builder = WebApplication.CreateBuilder(args);

// ---- Configuration (appsettings.json / user-secrets / environment variables) ----
builder.Services.AddOptions<SupabaseOptions>()
    .Bind(builder.Configuration.GetSection(SupabaseOptions.SectionName))
    .Validate(o => !string.IsNullOrWhiteSpace(o.Url) && !string.IsNullOrWhiteSpace(o.PublishableKey),
        "Supabase:Url and Supabase:PublishableKey must be set in appsettings.json.")
    .ValidateOnStart();
builder.Services.Configure<SchoolOptions>(builder.Configuration.GetSection(SchoolOptions.SectionName));

// ---- Supabase access (REST + Auth + Storage over HTTPS) ----
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient<SupabaseAuthService>();
builder.Services.AddHttpClient<SupabaseClient>();
builder.Services.AddScoped<IApplicationRepository, ApplicationRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<ILetterRepository, LetterRepository>();
builder.Services.AddScoped<IFileRepository, FileRepository>();
builder.Services.AddSingleton<ConfirmationLetterPdf>();

// ---- MVC ----
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add(new Microsoft.AspNetCore.Mvc.AutoValidateAntiforgeryTokenAttribute());
    options.Filters.Add<SupabaseExceptionFilter>();
});

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

// ---- Authorization: strict role separation (NFR1, NFR6) ----
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(Policies.Administrator, p => p.RequireAuthenticatedUser().RequireRole(StaffRoles.Administrator));
    options.AddPolicy(Policies.FinancialClerk, p => p.RequireAuthenticatedUser().RequireRole(StaffRoles.FinancialClerk));
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.Use(async (context, next) =>
{
    var h = context.Response.Headers;
    h["X-Content-Type-Options"] = "nosniff";
    h["X-Frame-Options"] = "SAMEORIGIN";
    h["Referrer-Policy"] = "same-origin";
    await next();
});

app.UseStatusCodePagesWithReExecute("/Home/StatusPage", "?code={0}");
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
