import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../time/time_source.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/token_storage.dart';
import '../../data/local/daos/areas_dao.dart';
import '../../data/local/daos/sessions_dao.dart';
import '../../data/local/daos/subjects_dao.dart';
import '../../data/local/database.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/sync/sync_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/areas/data/areas_repository.dart';
import '../../features/courses/data/courses_repository.dart';
import '../../features/subjects/data/subjects_repository.dart';
import '../../features/sessions/data/sessions_repository.dart';
import '../../features/planner/data/daily_plans_repository.dart';
import '../../features/review/data/daily_reviews_repository.dart';
import '../../features/statistics/data/statistics_repository.dart';
import '../../features/planner/application/daily_plans_controller.dart';
import '../../core/domain/plan.dart';

/// Single source of truth for app-wide singletons.
///
/// Use `overrideWith` in tests to swap these out.
final timeSourceProvider = Provider<TimeSource>((ref) => const SystemClock());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(ref.watch(secureStorageProvider)),
);

final databaseProvider = Provider<Database>(
  (ref) {
    final db = Database();
    ref.onDispose(db.close);
    return db;
  },
);

final sessionsDaoProvider = Provider<SessionsDao>(
  (ref) => SessionsDao(ref.watch(databaseProvider)),
);

final areasDaoProvider = Provider<AreasDao>(
  (ref) => AreasDao(ref.watch(databaseProvider)),
);

final subjectsDaoProvider = Provider<SubjectsDao>(
  (ref) => SubjectsDao(ref.watch(databaseProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.watch(databaseProvider),
    dao: ref.watch(sessionsDaoProvider),
    areasRepo: ref.watch(areasRepositoryProvider),
    subjectsRepo: ref.watch(subjectsRepositoryProvider),
    sessionsRepo: ref.watch(sessionsRepositoryProvider),
    coursesRepo: ref.watch(coursesRepositoryProvider),
    dailyPlansRepo: ref.watch(dailyPlansRepositoryProvider),
    dailyReviewsRepo: ref.watch(dailyReviewsRepositoryProvider),
    apiClient: ref.watch(apiClientProvider),
    timeSource: ref.watch(timeSourceProvider),
  ),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final areasRepositoryProvider = Provider<AreasRepository>(
  (ref) => AreasRepository(ref.watch(apiClientProvider)),
);

final subjectsRepositoryProvider = Provider<SubjectsRepository>(
  (ref) => SubjectsRepository(ref.watch(apiClientProvider)),
);

final sessionsRepositoryProvider = Provider<SessionsRepository>(
  (ref) => SessionsRepository(ref.watch(apiClientProvider)),
);

final dailyPlansRepositoryProvider = Provider<DailyPlansRepository>(
  (ref) => DailyPlansRepository(ref.watch(apiClientProvider)),
);

final dailyReviewsRepositoryProvider = Provider<DailyReviewsRepository>(
  (ref) => DailyReviewsRepository(ref.watch(apiClientProvider)),
);

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(ref.watch(apiClientProvider)),
);

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepository(ref.watch(apiClientProvider)),
);

final dailyPlansControllerProvider = NotifierProvider<DailyPlansController, AsyncValue<DailyPlanEntity?>>(
  DailyPlansController.new,
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// True if a logged-in session exists on disk.
final isLoggedInProvider = FutureProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).isLoggedIn(),
);