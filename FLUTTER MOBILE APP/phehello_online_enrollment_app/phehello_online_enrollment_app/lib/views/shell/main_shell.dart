//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: main_shell.dart defines the logged-in area of the app: the four main tabs (Home,
// Applications, Alerts, Profile) with the bottom navigation bar, and the automatic data refresh when the
// app returns to the foreground.

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

/// MainShell (class) - the screen shown once the parent is signed in; it hosts the four tab screens.
/// Logged-in area: Home, Applications, Alerts, Profile.
class MainShell extends StatefulWidget {
  /// Constructor - no required parameters.
  const MainShell({super.key});

  /// createState() - creates the State object _MainShellState.
  @override
  State<MainShell> createState() => _MainShellState();
}

/// _MainShellState (class) - listens to app lifecycle events (WidgetsBindingObserver) to know when the app comes back to the foreground.
class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  /// initState() - registers this object as a lifecycle observer when the shell is created.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// dispose() - removes the lifecycle observer when the shell is removed.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// didChangeAppLifecycleState() - called when the app goes to the background or returns. When it is resumed, it
  /// reloads the applications and notifications from Supabase so changes made by school staff in the ASP.NET app
  /// appear (IR3).
  /// Re-load status from Supabase whenever the app returns to the foreground,
  /// so staff updates from the ASP.NET app appear (IR3).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ApplicationsViewModel>().load();
      context.read<NotificationsViewModel>().load();
    }
  }

  /// build() - reads the selected tab, the unread notification count and the notifications on/off setting. It shows an
  /// IndexedStack (all four tab screens kept alive, only the selected one visible) and the AppBottomNav. The alert
  /// dot shows when there are unread notifications and notifications are switched on. Tapping a tab switches to it,
  /// and the Applications and Alerts tabs also reload their data.
  @override
  Widget build(BuildContext context) {
    final nav = context.watch<ShellNavViewModel>();
    final unread = context.watch<NotificationsViewModel>().unreadCount;
    final notificationsOn = context
        .watch<SettingsViewModel>()
        .notificationsEnabled;
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
