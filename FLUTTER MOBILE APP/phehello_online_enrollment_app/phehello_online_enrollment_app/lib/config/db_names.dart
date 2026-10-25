//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: db_names.dart keeps every Supabase table, storage bucket and database function
// (RPC) name in one place, so a rename in the shared database only needs changing here.

/// Central place for Supabase table / bucket / function names, following the
/// SRS ERD (Part D). If the shared database differs, change them here only.
///
/// Db (class) - static-only constants; the private constructor Db._() prevents instances.
class Db {
  Db._();

  /// bucket - the Supabase Storage bucket where uploaded documents and proofs of payment are stored.
  static const String bucket = 'enrolment-documents';

  /// Table names used by the repositories.
  static const String profiles = 'profiles'; // parent profile details
  static const String applications = 'applications'; // enrolment applications
  static const String notifications =
      'notifications'; // messages sent to the parent

  /// RPC (stored function) names called through supabase.rpc(...).
  static const String rpcSubmit =
      'submit_enrolment'; // submits a completed enrolment
  static const String rpcReplaceDocument =
      'replace_document'; // swaps an uploaded document
  static const String rpcResubmitPayment =
      'resubmit_payment_proof'; // re-sends proof of payment
  static const String rpcResubmitReview =
      'resubmit_for_review'; // sends a corrected application back for review
  static const String rpcDeleteApplication =
      'delete_application'; // lets a parent delete their own application
}
