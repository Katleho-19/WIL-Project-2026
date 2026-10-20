import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/applications_view_model.dart';
import '../../viewmodels/notifications_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/shell_nav_view_model.dart';
import '../applications/applications_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/app_bottom_nav.dart';

/// Logged-in area: Home, Applications, Alerts, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-load status from Supabase whenever the app returns to the foreground,
  /// so staff updates from the ASP.NET app appear (IR3).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ApplicationsViewModel>().load();
      context.read<NotificationsViewModel>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<ShellNavViewModel>();
    final unread = context.watch<NotificationsViewModel>().unreadCount;
    final notificationsOn = context.watch<SettingsViewModel>().notificationsEnabled;
    return Scaffold(
      body: IndexedStack(
        index: nav.index,
        children: const [
          HomeScreen(),
          ApplicationsScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: nav.index,
        showAlertDot: unread > 0 && notificationsOn,
        onTap: (i) {
          nav.setIndex(i);
          if (i == 1) context.read<ApplicationsViewModel>().load();
          if (i == 2) context.read<NotificationsViewModel>().load();
        },
      ),
    );
  }
}
