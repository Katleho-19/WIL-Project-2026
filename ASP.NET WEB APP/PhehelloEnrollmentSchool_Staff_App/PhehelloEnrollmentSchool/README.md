# Phehello Secondary School – Staff Web App (ASP.NET Core 8)

Administrator and Financial Clerk portal for the Phehello Online Enrolment System (ITC327W, group Ctrl-Alt-Defeat).
It shares one Supabase backend with the Flutter parent app, as described in the SRS.

## Run it (3 steps)

1. **Run the SQL once** – Supabase → *SQL Editor*, paste and run `supabase/staff_access_patch.sql`.
   (Assumes the Flutter app's `schema.sql` was already run. It is safe to run again.)
2. **Create the two staff accounts** – follow the comments in `supabase/create_staff_accounts.sql`.
3. **Start the app** – install the **.NET 8 SDK**, then:

   ```
   cd PhehelloEnrollmentSchool
   dotnet run --launch-profile http
   ```
   Open <http://localhost:5008>. (In Visual Studio just press F5 – either profile works.)

There is **nothing to configure and no NuGet package to restore**: `appsettings.json` already holds the
project URL and the public anon/publishable key.

## What was wrong with the first version (why it would not run)

| Problem | Effect | Fix |
|---|---|---|
| `AddAuthentication().AddCookie()` was registered **twice** in `Program.cs` | App crashed on start: *"Scheme already exists: Cookies"* | One registration |
| Cookie named `__Host-…` with `SecurePolicy = Always` | On `http://localhost` the browser drops the cookie → login loop | `SameAsRequest` (Secure automatically on HTTPS) |
| `UseAuthentication()` missing; login redirected to a `DashboardController` that did not exist | Nobody could ever be "logged in" | Added; real Admin/Clerk controllers |
| Role claim never set from the database, so the `admin` policy could never pass | Every staff page forbidden | Role is read from `profiles.role` after sign-in |
| Connection string in `postgresql://` URI form + EF Core/Npgsql, plus EF tool packages for a different .NET version | Database access fails; package-version conflicts | Replaced by Supabase REST/Auth/Storage over HTTPS – no EF Core, no DB password |
| Database password stored in `appsettings.json` | Secret committed to Git | Removed. **Rotate that database password in Supabase now** (Project Settings → Database). |

## How it works

* **Sign-in**: Supabase Auth (email + password). The `profiles.role` value (`Administrator` / `Financial Clerk`) decides the
  portal; the tab chosen on the login screen must match it. Parents cannot sign in here.
* **Data access**: every request carries the signed-in user's own token, so Postgres **Row Level Security** is the real
  gatekeeper (SRS NFR1/NFR6). No service-role key exists anywhere in this project. Tokens refresh automatically.
* **Separation**: Financial Clerk → payments, proof files and school payment records only.
  Administrator → applications, documents, notes, messages, reminders, letters.
* **Rules enforced on the server**: an application can only be **approved after the Clerk has verified the payment**;
  corrections need a message to the parent; a payment/application can only be decided once; rejecting a payment needs a note.
* **Parents are notified** through the `notifications` table (the Flutter *Messages* / *Notifications* tabs): decisions,
  correction requests, messages, reminders, payment verified/rejected, letter issued.
* **Student numbers** (`PH2026/001`, `PH2026/002` …) are assigned on approval (or when the letter is generated).
* **Confirmation letters** are generated as PDF (crest, learner name, ID number, student number), stored in
  `enrolment-documents/confirmation-letters/<application id>.pdf` and recorded in `confirmation_letters`.

## Project layout

```
Controllers/   Account, Home, Admin, Clerk
Repositories/  Application, Payment, Notification, Letter, File   (all Supabase access)
Services/      SupabaseAuthService, ConfirmationLetterPdf
Infrastructure SupabaseClient (REST + Storage), cookie/session handling, options, constants
Models/        DbRows (table shapes), ViewModels
Views/         Account, Admin, Clerk, Shared   (screens from the SRS wireframes)
supabase/      staff_access_patch.sql, create_staff_accounts.sql
```

## Settings (`appsettings.json`)

`Supabase:Url`, `Supabase:PublishableKey`, `Supabase:Bucket`; `School:*` (name, address, telephone, `AcademicYear`
– 0 means the current year – and `AdmissionsOpen`, which drives the "System status" card).

## Notes

* "Forgot Password?" sends Supabase's reset email; set Supabase → Authentication → URL Configuration → *Site URL* so the
  link lands somewhere that can handle it.
* Lists show the application year chosen in the *Academic Year* filter (default: current year).
