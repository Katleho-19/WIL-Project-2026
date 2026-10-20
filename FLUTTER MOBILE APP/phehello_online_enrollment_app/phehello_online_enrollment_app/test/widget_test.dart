import 'package:flutter_test/flutter_test.dart';
import 'package:phehello_online_enrollment_app/models/enrolment_application.dart';
import 'package:phehello_online_enrollment_app/models/enrolment_draft.dart';
import 'package:phehello_online_enrollment_app/models/enums.dart';
import 'package:phehello_online_enrollment_app/utils/formatters.dart';
import 'package:phehello_online_enrollment_app/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('parent.test@example.com'), isNull);
    });

    test('password rules', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough1'), isNull);
      expect(Validators.confirmPassword('a', 'b'), isNotNull);
      expect(Validators.confirmPassword('same', 'same'), isNull);
    });

    test('phone', () {
      expect(Validators.phone('082 123 4567'), isNull);
      expect(Validators.phone('+27821234567'), isNull);
      expect(Validators.phone('12345'), isNotNull);
    });

    test('ID or passport', () {
      expect(Validators.idOrPassport('1205145000084'), isNull);
      expect(Validators.idOrPassport('12051450'), isNotNull);
      expect(Validators.idOrPassport('A1234567'), isNull);
      expect(Validators.idOrPassport(''), isNotNull);
    });

    test('amount', () {
      expect(Validators.amount('200.00'), isNull);
      expect(Validators.amount('R 200,00'), isNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('0'), isNotNull);
    });
  });

  group('Status vocabulary', () {
    test('application status parsing', () {
      expect(ApplicationStatus.fromDb('Approved'), ApplicationStatus.approved);
      expect(ApplicationStatus.fromDb('rejected'), ApplicationStatus.rejected);
      expect(ApplicationStatus.fromDb('Corrections Requested'),
          ApplicationStatus.correctionsRequested);
      expect(ApplicationStatus.fromDb('Pending Admin View'),
          ApplicationStatus.pendingAdminReview);
      expect(ApplicationStatus.fromDb(null), ApplicationStatus.pendingAdminReview);
    });

    test('payment status parsing', () {
      expect(PaymentVerificationStatus.fromDb('Verified'),
          PaymentVerificationStatus.verified);
      expect(PaymentVerificationStatus.fromDb('Rejected'),
          PaymentVerificationStatus.rejected);
      expect(PaymentVerificationStatus.fromDb('anything'),
          PaymentVerificationStatus.pending);
    });
  });

  group('Models and helpers', () {
    test('draft round-trips through JSON', () {
      final d = EnrolmentDraft()
        ..firstName = 'Test'
        ..surname = 'Learner'
        ..gradeApplied = 'Grade 8'
        ..dateOfBirth = DateTime(2012, 5, 14);
      final back = EnrolmentDraft.decode(d.encode());
      expect(back.firstName, 'Test');
      expect(back.gradeApplied, 'Grade 8');
      expect(back.dateOfBirth, DateTime(2012, 5, 14));
    });

    test('application parses embedded relations', () {
      final app = EnrolmentApplication.fromMap({
        'application_id': 'a1',
        'reference_number': 'PH2026-001',
        'status': 'Pending Admin Review',
        'payment_verification_status': 'Pending',
        'grade_applied_for': 'Grade 8',
        'submitted_at': '2026-08-24T10:00:00Z',
        'learners': {'learner_id': 'l1', 'first_name': 'Test', 'surname': 'Learner'},
        'application_documents': [
          {'document_id': 'd1', 'application_id': 'a1', 'document_type': 'Birth Certificate',
           'file_name': 'bc.pdf', 'storage_path': 'u/a1/bc.pdf'}
        ],
        'payments': [
          {'payment_id': 'p1', 'application_id': 'a1', 'payment_reference': 'REF1',
           'amount': 200, 'verification_status': 'Pending'}
        ],
      });
      expect(app.referenceNumber, 'PH2026-001');
      expect(app.learner?.fullName, 'Test Learner');
      expect(app.documentOfType(DocumentType.birthCertificate), isNotNull);
      expect(app.documentOfType(DocumentType.transferLetter), isNull);
      expect(app.latestPayment?.reference, 'REF1');
    });

    test('formatters', () {
      expect(Formatters.maskId('1205145000084'), '**********084');
      expect(Formatters.money(200), 'R 200.00');
      expect(Formatters.fileSize(2 * 1024 * 1024), '2.0 MB');
    });
  });
}
