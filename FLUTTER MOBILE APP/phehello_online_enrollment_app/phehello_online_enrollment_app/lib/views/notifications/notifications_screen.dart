//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: notifications_screen.dart defines the Alerts tab (FR10, FR11): a list of staff messages,
// reminders and application status updates, split into two tabs, with unread markers, "Mark all read", and a
// dialog to read each message in full.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/notifications_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/state_views.dart';

/// NotificationsScreen (class) - the Alerts tab of the main shell. It is stateful because it remembers which of the two tabs is selected.
/// Messages & Notifications (FR10, FR11): staff messages, reminders and
/// application status updates delivered through Supabase.
class NotificationsScreen extends StatefulWidget {
  /// Constructor - no required parameters.
  const NotificationsScreen({super.key});

  /// createState() - creates the State object _NotificationsScreenState.
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// _NotificationsScreenState (class) - holds the selected tab and builds the screen.
class _NotificationsScreenState extends State<NotificationsScreen> {
  /// _tab - the selected tab: 0 = Messages, 1 = Notifications.
  int _tab = 0; // 0 = Messages, 1 = Notifications

  /// build() - watches NotificationsViewModel and picks the list for the selected tab (messages or updates). It chooses
  /// the body: a loader on first load; an error message with a retry button; an empty-state message if the tab has no items;
  /// otherwise a pull-to-refresh list of _NotificationCard widgets. It then draws the "Messages & Notifications" header (with a red
  /// unread-count badge when there are unread items), the two _Tab pills, a "Mark all read" button (only when there are unread items) and the body.
  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationsViewModel>();
    final list = _tab == 0 ? p.messages : p.updates;

    Widget body;
    if (p.loading && p.items.isEmpty) {
      body = const CenteredLoader();
    } else if (p.error != null && p.items.isEmpty) {
      body = ErrorState(message: p.error!, onRetry: p.load);
    } else if (list.isEmpty) {
      body = EmptyState(
        icon: Icons.notifications_none_rounded,
        title: _tab == 0 ? 'No messages' : 'No notifications',
        message: 'Updates from the school will appear here.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _NotificationCard(item: list[i]),
        ),
      );
    }

    return Column(
      children: [
        AppHeader(
          title: 'Messages & Notifications',
          subtitle: 'Important updates from school',
          trailing: p.unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE3E3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${p.unreadCount}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              _Tab(
                label: 'Messages',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 10),
              _Tab(
                label: 'Notifications',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const Spacer(),
              if (p.unreadCount > 0)
                TextButton(
                  onPressed: p.markAllRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.brown,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// _Tab (class) - one pill-shaped tab button; brown and white text when selected, light tile and brown text when not.
class _Tab extends StatelessWidget {
  /// Constructor - label, selected and onTap are all required.
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// build() - a tappable rounded container showing the label; its colours depend on 'selected'.
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.brown : AppColors.tile,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.brownDark,
        ),
      ),
    ),
  );
}

/// _NotificationCard (class) - the card for one notification or message.
class _NotificationCard extends StatelessWidget {
  /// Constructor - the AppNotification is required.
  const _NotificationCard({required this.item});

  final AppNotification item;

  /// _showMessage() - opens a dialog with the full title and message. If the notification is linked to an application it also
  /// offers a "View application" button that opens that application's details; "Close" dismisses the dialog.
  void _showMessage(BuildContext context) {
    final appId = item.applicationId;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(child: Text(item.message)),
        actions: [
          if (appId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                RouteManager.toApplicationDetails(context, appId);
              },
              child: const Text('View application'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// build() - a card that, when tapped, marks the notification as read and shows the full message dialog. It shows the title,
  /// the date/time label, a gold dot if unread (or a chevron if read and linked to an application), a divider and the message text.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        context.read<NotificationsViewModel>().markRead(item);
        _showMessage(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.createdAt == null
                          ? ''
                          : Formatters.dateTimeLabel(item.createdAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                )
              else if (item.applicationId != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            item.message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
