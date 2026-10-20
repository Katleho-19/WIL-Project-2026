import 'package:flutter/material.dart';

import '../../config/school_info.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/school_crest.dart';

/// Help & Support: guidance on applying, documents, payment and contacting
/// the school. Content is based on the SRS and the school's enrolment form.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static final List<HelpTopic> _topics = [
    HelpTopic('FAQs', 'Frequently asked questions', [
      HelpBlock(
        'Who can use this app?',
        'Parents and guardians who want to apply for a learner to be enrolled at ${SchoolInfo.name}.',
      ),
      HelpBlock(
        'Do I pay inside the app?',
        'No. The app does not take payment. Pay the enrolment fee into the school bank account, then enter your payment reference and upload your proof of payment.',
      ),
      HelpBlock(
        'How do I know if my application was approved?',
        'Open the Applications tab. The status comes directly from the school and updates after the Financial Clerk and Administrator have reviewed your application. You will also see messages under Alerts.',
      ),
      HelpBlock(
        'What if a document is wrong?',
        'The school will send you a message and set your application to "Corrections Requested". Open the application, replace the document and tap "Resubmit for Review".',
      ),
    ]),
    HelpTopic('Contact Us', 'Get in touch with school support', [
      HelpBlock('Telephone', SchoolInfo.telephone),
      HelpBlock('Address', SchoolInfo.address),
      HelpBlock(
        'Please note',
        'Have your application reference ready when you contact the school.',
      ),
    ]),
    HelpTopic('Payment Guide', 'Payment reference and verification guidance', [
      HelpBlock('Enrolment fee', Formatters.money(SchoolInfo.enrolmentFee)),
      HelpBlock(
        'Bank details',
        '${SchoolInfo.accountName}\n${SchoolInfo.bank}\nAccount number: ${SchoolInfo.accountNumber}\nBranch: ${SchoolInfo.branch} (${SchoolInfo.branchCode})\nAccount type: ${SchoolInfo.accountType}',
      ),
      HelpBlock(
        'Payment reference',
        "Use the learner's ID number or your application reference so the school can match your payment.",
      ),
      HelpBlock(
        'Verification',
        'After you submit, the Financial Clerk checks your proof of payment against the school records. Your payment status changes from Pending to Verified (or Rejected, in which case you can upload a new proof).',
      ),
    ]),
    HelpTopic('Document Requirements', 'What documents must be uploaded', [
      HelpBlock(
        'Birth Certificate',
        'A clear copy of the learner\'s birth certificate.',
      ),
      HelpBlock(
        'Immunisation Record',
        'A copy of the learner\'s immunisation / clinic records.',
      ),
      HelpBlock(
        'Progress Report',
        'The most recent progress report from the previous school.',
      ),
      HelpBlock(
        'Transfer Letter',
        'A transfer letter from the previous school, if applicable.',
      ),
      HelpBlock('File types', 'JPG, PNG or PDF. Maximum 5 MB per file.'),
    ]),
    HelpTopic('User Guide', 'Parent/guardian portal instructions', [
      HelpBlock(
        '1. Register and log in',
        'Create your account with your email address and a password.',
      ),
      HelpBlock(
        '2. Start a new application',
        'Tap "New Application" on the Home screen and complete the six steps.',
      ),
      HelpBlock(
        '3. Pay and upload proof',
        'Pay the fee, enter the payment reference and upload your proof of payment.',
      ),
      HelpBlock('4. Submit', 'Check the summary and tap "Confirm & Submit".'),
      HelpBlock(
        '5. Track progress',
        'Use Applications to see your status and Alerts for messages and reminders.',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Help & Support',
            subtitle: SchoolInfo.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                const Text('How can we help?', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                const Text(
                  'Find guidance for using the online enrolment system.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                for (final t in _topics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => RouteManager.toHelpContent(context, t),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.brownDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      SchoolCrest(height: 84),
                      SizedBox(height: 12),
                      Text(
                        'PHEHELLO SECONDARY SCHOOL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        SchoolInfo.motto,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpTopic {
  const HelpTopic(this.title, this.subtitle, this.blocks);
  final String title;
  final String subtitle;
  final List<HelpBlock> blocks;
}

class HelpBlock {
  const HelpBlock(this.heading, this.text);
  final String heading;
  final String text;
}

class HelpContentScreen extends StatelessWidget {
  const HelpContentScreen({super.key, required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: topic.title,
            subtitle: 'Help & Support',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                for (final b in topic.blocks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.heading,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            b.text,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
