/// Central place for Supabase table / bucket / function names, following the
/// SRS ERD (Part D). If the shared database differs, change them here only.
class Db {
  Db._();

  static const String bucket = 'enrolment-documents';

  static const String profiles = 'profiles';
  static const String applications = 'applications';
  static const String notifications = 'notifications';

  static const String rpcSubmit = 'submit_enrolment';
  static const String rpcReplaceDocument = 'replace_document';
  static const String rpcResubmitPayment = 'resubmit_payment_proof';
  static const String rpcResubmitReview = 'resubmit_for_review';
  static const String rpcDeleteApplication = 'delete_application';
}
