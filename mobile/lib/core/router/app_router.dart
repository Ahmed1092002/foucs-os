import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/areas/presentation/areas_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/sessions/presentation/quick_start_screen.dart';
import '../../features/sessions/presentation/session_summary_screen.dart';
import '../../features/sessions/presentation/timer_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/courses/presentation/course_detail_screen.dart';
import '../../features/courses/presentation/subject_detail_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/review/presentation/reviews_history_screen.dart';
import '../../features/subjects/presentation/subject_list_screen.dart';
import 'app_shell.dart';

/// Tells the router whether the user is authenticated, *now*.
final _authStateProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user != null)),
);

/// Tells the router whether onboarding is completed (first-run flag).
final _onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('focus_os.onboarding_completed') ?? false;
});

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _Refreshable(ref),
    redirect: (context, state) async {
      final loggedIn = ref.read(_authStateProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/signup';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/dashboard';

      return null;
    },
    routes: [
      // Auth flows (no shell).
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),

      // Authenticated shell with 5 bottom-nav tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 1: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 2: Areas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/areas',
                builder: (_, _) => const AreasScreen(),
                routes: [
                  GoRoute(
                    path: ':areaId',
                    name: 'area-detail',
                    builder: (_, st) => SubjectListScreen(
                      areaId: st.pathParameters['areaId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Tab 3: Timer (quick-start entry, /session/active handled by AppShell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quick-start',
                builder: (_, _) => const QuickStartScreen(),
              ),
              GoRoute(
                path: '/session/active',
                builder: (_, _) => const TimerScreen(),
              ),
            ],
          ),
          // Tab 4: Stats
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (_, _) => const StatisticsScreen(),
              ),
            ],
          ),
          // Tab 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level (no shell) — drill-downs that should hide the bottom nav.
      GoRoute(
        path: '/subjects/:subjectId',
        name: 'subject-detail',
        builder: (_, st) => SubjectDetailScreen(
          subjectId: st.pathParameters['subjectId']!,
        ),
        routes: [
          GoRoute(
            path: 'courses/:courseId',
            name: 'course-detail',
            builder: (_, st) => CourseDetailScreen(
              subjectId: st.pathParameters['subjectId']!,
              courseId: st.pathParameters['courseId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/session/:sessionId/summary',
        builder: (_, st) => SessionSummaryScreen(
          sessionId: st.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/planner', builder: (_, _) => const PlannerScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(
        path: '/review/:date',
        builder: (_, st) {
          final parts = st.pathParameters['date']!.split('-');
          return ReviewScreen(
            date: DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ),
          );
        },
      ),
      GoRoute(
        path: '/reviews',
        builder: (_, _) => const ReviewsHistoryScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}

class _Refreshable extends ChangeNotifier {
  _Refreshable(WidgetRef ref) {
    ref.listen<bool>(_authStateProvider, (_, _) => notifyListeners());
  }
}