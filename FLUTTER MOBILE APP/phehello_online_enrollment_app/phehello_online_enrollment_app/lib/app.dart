//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app.dart defines the root widget of the app (PhehelloApp). It registers every
// repository, service and view model with Provider (so any screen can access them), sets the app
// title, theme and routing, and uses _AuthGate to decide which top-level screen to show.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/draft_view_model.dart';

import 'data/repositories/application_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/services/draft_storage.dart';
import 'data/services/file_picker_service.dart';
import 'routes/route_manager.dart';
import 'theme/app_theme.dart';
import 'viewmodels/applications_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/notifications_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'viewmodels/shell_nav_view_model.dart';

import 'views/auth/login_screen.dart';
import 'views/shell/main_shell.dart';
import 'views/widgets/state_views.dart';

/// PhehelloApp (class) - the root widget of the whole application.
/// It holds no changing state itself; its job is to wire up dependency injection and the MaterialApp.
class PhehelloApp extends StatelessWidget {
  const PhehelloApp({super.key});

  /// build() - creates the widget tree for the app.
  /// MultiProvider registers, in order:
  ///  - plain providers for the data layer (AuthRepository, ApplicationRepository,
  ///    NotificationRepository, DraftStorage, FilePickerService), created once and shared;
  ///  - ChangeNotifierProviders for SettingsViewModel, ShellNavViewModel and AuthViewModel,
  ///    which rebuild any widget that listens to them when their state changes;
  ///  - ChangeNotifierProxyProviders for ApplicationsViewModel, DraftViewModel and
  ///    NotificationsViewModel. These depend on AuthViewModel: whenever the signed-in user changes,
  ///    the update callback re-uses the existing view model and calls onUserChanged(userId) so that
  ///    the data is reloaded for the new user (or cleared on sign out).
  /// The child is a MaterialApp that applies the light theme, sends named-route navigation to
  /// RouteManager, and starts on _AuthGate.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<ApplicationRepository>(create: (_) => ApplicationRepository()),
        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(),
        ),
        Provider<DraftStorage>(create: (_) => DraftStorage()),
        Provider<FilePickerService>(create: (_) => FilePickerService()),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (_) => SettingsViewModel(),
        ),
        ChangeNotifierProvider<ShellNavViewModel>(
          create: (_) => ShellNavViewModel(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, ApplicationsViewModel>(
          create: (ctx) =>
              ApplicationsViewModel(ctx.read<ApplicationRepository>()),
          update: (ctx, auth, previous) =>
              (previous ??
                    ApplicationsViewModel(ctx.read<ApplicationRepository>()))
                ..onUserChanged(auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, DraftViewModel>(
          create: (ctx) => DraftViewModel(ctx.read<DraftStorage>()),
          update: (ctx, auth, previous) =>
              (previous ?? DraftViewModel(ctx.read<DraftStorage>()))
                ..onUserChanged(auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, NotificationsViewModel>(
          create: (ctx) =>
              NotificationsViewModel(ctx.read<NotificationRepository>()),
          update: (ctx, auth, previous) =>
              (previous ??
                    NotificationsViewModel(ctx.read<NotificationRepository>()))
                ..onUserChanged(auth.userId),
        ),
      ],
      child: MaterialApp(
        title: 'Phehello Enrolment',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: RouteManager.onGenerateRoute,
        home: const _AuthGate(),
      ),
    );
  }
}

/// _AuthGate (class) - a private widget that acts as the app's front door.
/// It chooses the first screen from the authentication status.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  /// build() - watches only AuthViewModel.status (so it rebuilds only when the status changes) and returns:
  ///  - initializing    -> a loading spinner while the saved session is being checked;
  ///  - authenticated   -> MainShell, the main app with bottom navigation;
  ///  - unauthenticated -> LoginScreen.
  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthViewModel, AuthStatus>((a) => a.status);

    switch (status) {
      case AuthStatus.initializing:
        return const Scaffold(body: CenteredLoader());

      case AuthStatus.authenticated:
        return const MainShell();

      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
