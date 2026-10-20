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

class PhehelloApp extends StatelessWidget {
  const PhehelloApp({super.key});

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

/// Chooses between the splash, login and main app from the auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

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
