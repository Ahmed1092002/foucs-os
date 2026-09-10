import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/notifications/notification_service.dart';
import 'features/settings/application/settings_controller.dart';

class FocusOsApp extends ConsumerStatefulWidget {
  const FocusOsApp({super.key});

  @override
  ConsumerState<FocusOsApp> createState() => _FocusOsAppState();
}

class _FocusOsAppState extends ConsumerState<FocusOsApp> {
  @override
  void initState() {
    super.initState();
    unawaitedSafe(ref.read(notificationServiceProvider).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(ref);
    final settingsAsync = ref.watch(settingsControllerProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (s) => s.themeMode,
      orElse: () => ThemeMode.system,
    );
    return MaterialApp.router(
      title: 'Focus OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

void main() {
  runApp(const ProviderScope(child: FocusOsApp()));
}

void unawaitedSafe(Future<void> future) {
  future.catchError((_) {});
}