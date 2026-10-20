import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enrolment_application.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/applications_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';

/// Read-only view of everything submitted (View Full Details).
class FullDetailsScreen extends StatelessWidget {
  const FullDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<ApplicationsViewModel>().byId(applicationId);
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Full Application Details',
            subtitle: app?.referenceNumber,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: app == null
                ? const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Application not found',
                    message: 'Please go back and open the application again.')
                : _content(app),
          ),
        ],
      ),
    );
  }

  Widget _content(EnrolmentApplication app) {
    final l = app.learner;
    final m = app.medical;
    final history = [...app.history]
      ..sort((a, b) => (b.changedAt ?? DateTime(2000)).compareTo(a.changedAt ?? DateTime(2000)));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _Section('Application', [
          _Row('Reference', app.referenceNumber),
          _Row('Status', app.status.dbValue),
          _Row('Payment status', (app.latestPayment?.status ?? app.paymentStatus).dbValue),
          _Row('Grade applied for', app.gradeApplied),
          _Row('Submitted', app.submittedAt == null ? '-' : Formatters.longDate(app.submittedAt!)),
        ]),
        _Section('Learner', [
          _Row('Full name', l?.fullName ?? '-'),
          _Row('Initials / nickname', l?.initials),
          _Row('Other names', l?.otherNames),
          _Row('Date of birth', l?.dateOfBirth == null ? null : Formatters.longDate(l!.dateOfBirth!)),
          _Row('Gender', l?.gender),
          _Row('ID / passport', Formatters.maskId(l?.idNumber)),
          _Row('Student number', l?.studentNumber),
        ]),
        _Section('Academic & School History', [
          _Row('Highest grade passed', l?.highestGradePassed),
          _Row('Year passed', l?.yearGradePassed),
          _Row('Previous school', l?.previousSchoolName),
          _Row('Notes', l?.schoolHistoryNotes),
        ]),
        _Section('Medical & Family', [
          _Row('Medical aid', m?.medicalAidName),
          _Row('Medical aid number', m?.medicalAidNumber),
          _Row('Main member', m?.medicalAidMainMember),
          _Row('Doctor', m?.doctorName),
          _Row('Doctor address', m?.doctorAddress),
          _Row('Siblings at school', m?.siblingsAtSchool),
        ]),
        if (app.payments.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment attempts',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final p in ([...app.payments]..sort((a, b) =>
                    (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)))))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${p.reference} • ${Formatters.money(p.amount)}'
                            '${p.createdAt == null ? '' : '\n${Formatters.shortDate(p.createdAt!)}'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        StatusChip.payment(p.status),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (app.payments.isNotEmpty) const SizedBox(height: 14),
        if (history.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status history',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final h in history)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${h.newStatus}'
                      '${h.changedAt == null ? '' : '  •  ${Formatters.shortDate(h.changedAt!)}'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String? value;
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows);

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => (r.value ?? '').trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              const Text('Nothing provided.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            for (final r in visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(r.label,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(r.value!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
