# Implementation matrix (SRS requirement -> screen -> data -> backend)

Status legend: **Done** = implemented in code; **Needs Supabase** = works only after `supabase/schema.sql` is run and `assets/env/app.env` is filled in. Nothing here has been executed against a live Supabase project (see README "Verification").

## Parent app requirements (Flutter)

| SRS requirement | Flutter screen | UI component | Data | Backend action | Status |
|---|---|---|---|---|---|
| FR1 register | Register (Create Parent/Guardian Account) | 4 validated fields, Register button | Auth user + `profiles` (trigger `handle_new_user`) | `auth.signUp` | Done / Needs Supabase |
| FR1 sign in / out / session | Welcome / Login, Profile > Log Out | Email, password, forgot password, logout dialog | Auth session | `signInWithPassword`, `signOut`, `resetPasswordForEmail`, `onAuthStateChange` (AuthGate) | Done / Needs Supabase |
| FR2 submit application | Application wizard steps 1-4 (Learner, Academic, Medical, Guardian), review sheet, Success screen | TextFormFields, dropdowns, date picker, stepper, validation | `learners`, `learner_medical_info`, `applications`, `profiles` | Storage upload then RPC `submit_enrolment` (single transaction) | Done / Needs Supabase |
| FR3 supporting documents | Wizard step 4 (Parent/Guardian & Documents) | 4 upload tiles (select / replace / remove, image preview) | `application_documents` | Storage `enrolment-documents/<uid>/<app>/documents/...` + RPC | Done / Needs Supabase |
| FR15 fee, bank details, reference | Wizard step 5 (Payment Information) | Fee card, banking card, reference field, instruction boxes | `payments.payment_reference` | Saved with submission; no gateway | Done / Needs Supabase |
| FR4 proof of payment | Wizard step 6 (Proof of Payment) | Reference, amount, drop-zone, selected-file card, Replace/Remove, Submit | `payments`, Storage `.../payment/...` | Storage + RPC `submit_enrolment`; re-upload via RPC `resubmit_payment_proof` | Done / Needs Supabase |
| FR5 application + payment status | Home, My Applications (filters), Application Details, Full Details | Status banner, chips, document rows, payment row | `applications.status`, `payment_verification_status`, `payments.verification_status` | `select` with embedded relations; refreshed on open, pull-to-refresh and app resume | Done / Needs Supabase |
| FR10 staff messages | Messages & Notifications (Messages tab) | Cards, unread dot, badge | `notifications` | `select`, `update is_read` | Done / Needs Supabase |
| FR11 deadline reminders | Messages & Notifications | same | `notifications` (`reminder`) | same | Done / Needs Supabase |
| IR3 status reflected | Application Details + Notifications tab | Banner, chips | status columns; trigger creates `status_update` notification | refetch | Done / Needs Supabase |
| Corrections requested (SD2) | Application Details | Replace buttons, Resubmit for Review | `application_documents`, `applications.status` | RPC `replace_document`, `resubmit_for_review` | Done / Needs Supabase |
| NFR2 secure storage | - | - | private bucket, RLS | policies in `schema.sql` | Done (SQL) / Needs Supabase |
| NFR3 test data | README test accounts | - | fictional only | `seed_test_data.sql` | Done |
| NFR4 clear errors | all forms | `Validators`, `AppError` | - | - | Done |
| NFR5 Android layout | all | SafeArea, scroll views | - | - | Done (not run on device) |

## Screens in the supplied design

| # | Design screen | File | Notes |
|---|---|---|---|
| 1 | Welcome / Login | `views/auth/login_screen.dart` | Gradient background; school photo not supplied |
| 2 | Create Parent/Guardian Account | `views/auth/register_screen.dart` | |
| 3 | Home | `views/home/home_screen.dart` | Real applications from Supabase |
| 4 | Learner Personal Information (1/6) | `views/enrolment/learner_step.dart` | |
| 5 | Academic & School History (2/6) | `.../academic_step.dart` | |
| 6 | Medical & Family (3/6) | `.../medical_step.dart` | |
| 7 | Parent / Guardian & documents (4/6) | `.../guardian_documents_step.dart` | |
| 8 | Payment Information (5/6) | `.../payment_info_step.dart` | Reference field added here per FR15 |
| 9 | Proof of Payment (6/6) | `.../proof_of_payment_step.dart` | Submit + review sheet |
| 10 | My Applications | `views/applications/applications_screen.dart` | |
| 11 | Application Details | `views/applications/application_details_screen.dart` | + `views/applications/full_details_screen.dart` |
| 12 | Messages & Notifications | `views/notifications/notifications_screen.dart` | |
| 13 | Profile | `views/profile/profile_screen.dart` | + personal details, change password |
| 14 | Help & Support | `views/profile/help_support_screen.dart` | 5 content pages |

Staff requirements (FR6-FR9, FR12, FR13, NFR1, NFR6) belong to the ASP.NET app and are out of scope for this project; `schema.sql` includes starter staff RLS policies for that team.
