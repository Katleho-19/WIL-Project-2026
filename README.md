# Phehello Secondary Online Enrolment System

**ITC327W – Work-Integrated Learning (WIL) Project 2026**
**Group:** Ctrl-Alt-Defeat

An integrated prototype that lets parents/guardians apply for their child's enrolment at Phehello Secondary School from a mobile phone, and lets school staff review and process those applications digitally.

---

## 1. Project Description

Phehello Secondary School is a public secondary school whose enrolment process is currently entirely manual and paper-based. This project delivers a prototype online enrolment system made up of:

- a **Flutter mobile application** for parents/guardians,
- an **ASP.NET web application** for school staff (Financial Clerk and Administrator), and
- a shared **Supabase** backend (authentication, database and file storage).

The stakeholder is the Principal of Phehello Secondary School. The current process, problems and requirements were confirmed in a stakeholder needs-assessment interview held on Microsoft Teams on 24 August 2026.

## 2. Problem Statement

Phehello Secondary School enrols new learners using paper forms. Parents collect and complete the form by hand, then deliver it in person together with the required documents (copy of immunisation records, copy of birth certificate, progress report and transfer letter from the previous school). An enrolment fee is paid to the Financial Clerk, who issues a payment slip, and the Administrator then reviews the application.

This causes:

- **Repeated trips to the school** when documents are incomplete or incorrect, costing parents time and transport money (especially young and working parents, some of whom travel on foot).
- **Slow manual processing** split between a Financial Clerk and an Administrator, with long queues and a lot of one-on-one interaction that limits staff time for other duties.
- **Paper records that can be lost, damaged or incompletely filled in**, making applications hard to manage and retrieve.
- **No status tracking**, so parents cannot see the progress of their application or payment without contacting or visiting the school.

## 3. Purpose and Aim

To improve how Phehello Secondary School receives, verifies and manages learner enrolment applications by allowing parents to apply and upload documents remotely, and allowing staff to review and process applications digitally instead of on paper.

**Main objectives**

- Allow parents to complete and submit an online enrolment application.
- Allow parents to upload the required documents and proof of payment.
- Allow parents to track application and payment status.
- Allow staff to verify payments and approve/reject applications.
- Provide a secure digital record of applications and documents.

## 4. Proposed System

| Component | Used by | What it does |
|---|---|---|
| **Flutter mobile app** | Parent/Guardian | Register/sign in, complete and submit the enrolment application, upload supporting documents, view the enrolment fee and school banking details, enter a payment reference, upload proof of payment, track application/payment status, receive messages and reminders. |
| **ASP.NET web app – Financial Clerk** | Financial Clerk | Sign in, view submitted proof of payment, verify it against the school's payment records, update payment verification status. |
| **ASP.NET web app – Administrator** | Administrator | Sign in, view and review applications and documents, approve/reject/request corrections, leave notes, message parents about incorrect documents, send deadline reminders, generate confirmation letters, view a running application count. |
| **Supabase backend** | Both apps | Authentication with role-based access, PostgreSQL database, and secure storage for documents and proof of payment. |

Because both apps read from and write to the same Supabase backend, an application submitted on the mobile app is visible to staff on the web app, and status updates made by staff are reflected back to the parent.

### Key features

**Parent/Guardian (Flutter)**
- Register and sign in
- Multi-step enrolment form (learner details, academic history, medical and family information, parent/guardian details)
- Upload birth certificate, immunisation record, progress report and transfer letter
- View enrolment fee and banking details, enter a payment reference, upload proof of payment
- Track application and payment status; receive notifications

**Financial Clerk (ASP.NET)**
- Payment verification dashboard
- View proof of payment next to the matching school payment record
- Mark payments as Verified or Rejected

**Administrator (ASP.NET)**
- Dashboard with application counts and recent applications
- Filter applications by status (all / pending / approved / rejected)
- Review learner details and documents; approve, reject or request corrections
- Internal notes, parent messaging and deadline reminders
- Preview and generate confirmation letters (school logo, learner name, ID number, student number)

## 5. Users and Roles

| Role | Access |
|---|---|
| Parent/Guardian | Mobile app only; can view and manage their own applications. |
| Financial Clerk | Web app; payment-related information and payment verification only. |
| Administrator | Web app; applications and supporting documents; the only role allowed to approve, reject or request corrections. |

## 6. Project Scope

**In scope (deliverables)**
- Flutter mobile application prototype (parent-facing)
- ASP.NET web application prototype (school-facing)
- Supabase backend, database and document storage
- Project documentation

**Out of scope**
- Integration with Department of Education systems (e.g. SA-SAMS)
- Online fee/payment processing (the system only displays the fee and banking details and lets parents upload proof of payment)
- Online medical consultations
- Province-wide deployment
- Production use of real learner records
- Advanced analytics and full school-management functionality beyond enrolment

**Constraints and assumptions**
- Must be completed within the academic project period.
- Development is limited to Flutter, ASP.NET and Supabase.
- Testing uses sample/mock data only; no real learner information is used.
- Target parents are assumed to have a smartphone and basic connectivity.

## 7. Requirements Summary

The full list is in the SRS document. In summary:

- **Functional (FR1–FR15):** registration and sign-in, application submission, document and proof-of-payment upload, status tracking, payment verification, application review and decisions, notes, parent messaging, deadline reminders, confirmation letters, running application count, secure storage, and payment information display.
- **Non-functional (NFR1–NFR6):** role-based access control, secure storage of documents, mock data only, clear error messages, correct display on a standard Android phone.
- **System (SR1–SR4):** Flutter for mobile, ASP.NET for web, Supabase backend, GitHub for source control.
- **Integration (IR1–IR3):** Flutter submissions stored in Supabase, Supabase records displayed in ASP.NET, and ASP.NET status updates reflected in Flutter.

## 8. Tech Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter (Dart) |
| Web portal | ASP.NET Core (C#) |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Design tools | Figma (wireframes), Software Ideas Modeler (UML), dbdiagram.io (ERD) |
| Project management | Microsoft Project, GitHub |

## 9. System Architecture

```
 Parent/Guardian            Administrator        Financial Clerk
        |                         |                     |
        v                         v                     v
 Flutter mobile app        ASP.NET web app (role-based dashboards)
        \                         |                     /
         \------------- HTTPS ----+--------------------/
                                  v
                        Supabase backend
              (Authentication | Database | Storage)
```

## 10. Database Overview

Main tables: `profiles`, `learners`, `learner_medical_info`, `applications`, `application_documents`, `payments`, `school_payment_records`, `application_notes`, `application_status_history`, `confirmation_letters`, `notifications`.

Key design decisions:
- Every payment attempt is stored as a new row, so resubmission history is preserved.
- Status values follow a fixed vocabulary, with Row Level Security (RLS) controlling who can do what.
- No cascading deletes on payment, audit and confirmation-letter tables.

## 11. Design Links

- ERD: https://dbdiagram.io/d/ERD-6ab5c1300f25a52d0100e2b7
- Figma (Flutter and ASP.NET wireframes): https://www.figma.com/design/afkx2OMta474iXNnlscqO5/Flutter-and-ASP.NET-interfaces
- Full documentation (SRS, UML, ERD, interface designs) is in the `documents` folder.

## 12. Getting Started

> Fill in the exact commands once the code structure is final.

**Prerequisites:** Flutter SDK, .NET SDK, a Supabase project, and Git.

1. Clone the repository:
   ```bash
   git clone https://github.com/Katleho-19/WIL-Project-2026.git
   ```
2. Create your own local configuration (for example a `.env` file or `appsettings.Development.json`) with your Supabase project URL and anon key.
3. Run the mobile app: `flutter pub get` then `flutter run`.
4. Run the web app: `dotnet run` from the ASP.NET project folder.

**Security note:** Never commit API keys, `.env` files or Supabase service-role keys. Use only mock/test data.

## 13. Project Status

| Phase | Status |
|---|---|
| Phase 1 – Requirements and SRS | Complete |
| Phase 2 – System architecture and design | Complete |
| Phase 3 – Development, integration and testing | In progress |

## 14. Team

| Member | GitHub |
|---|---|
| Katleho Makhoali | @Katleho-19 |
| Mamello Lepitla | @mells148 |
| Paballo Lebusa | @Lebusa24 |
| Romeo Mahlatsi | @CyberGhost90 |
| David Adegbola | @RedXjd |
| Mpho Motaung | @Unknown123450 |

## 15. Acknowledgements

Thank you to Phehello Secondary School for their time and input as our project stakeholder.
