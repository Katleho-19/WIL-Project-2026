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

/// Messages & Notifications (FR10, FR11): staff messages, reminders and
/// application status updates delivered through Supabase.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _tab = 0; // 0 = Messages, 1 = Notifications

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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

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
