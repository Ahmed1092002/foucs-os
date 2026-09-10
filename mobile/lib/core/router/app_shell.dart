import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/sessions/application/sessions_controller.dart';

/// App shell with bottom navigation. Five tabs:
///   - Dashboard
///   - Areas
///   - Timer (smart: shows /session/active if a session is running, else QuickStart)
///   - Stats
///   - Settings
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force the auth controller to build so it redirects to /login on logout.
    ref.watch(authControllerProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap(context, ref, navigationShell),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Areas',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_arrow_outlined),
            selectedIcon: Icon(Icons.play_arrow),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void Function(int) _onTap(
    BuildContext context,
    WidgetRef ref,
    StatefulNavigationShell shell,
  ) {
    return (index) {
      // Special case the Timer tab: route to /session/active or /quick-start
      // based on whether a session is running.
      if (index == 2) {
        final hasActive = ref.read(sessionsControllerProvider) != null;
        final target = timerTabRouteFor(hasActiveSession: hasActive);
        shell.goBranch(2, initialLocation: true);
        if (context.mounted) context.go(target);
        return;
      }
      shell.goBranch(index, initialLocation: true);
    };
  }
}

/// Pure function extracted for testability. Returns the route the Timer
/// tab should navigate to based on whether a session is active.
String timerTabRouteFor({required bool hasActiveSession}) {
  return hasActiveSession ? '/session/active' : '/quick-start';
}