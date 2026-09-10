import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/plan.dart';
import '../../../core/error/app_failure.dart';
import '../data/daily_plans_repository.dart';

/// Controller for daily plans.
class DailyPlansController extends Notifier<AsyncValue<DailyPlanEntity?>> {
  @override
  AsyncValue<DailyPlanEntity?> build() {
    // Initial state is empty - plans are loaded on demand by date
    return const AsyncData(null);
  }

  /// Load plan for a specific date.
  Future<void> loadForDate(DateTime date) async {
    state = const AsyncLoading();
    try {
      final plan = await ref.read(dailyPlansRepositoryProvider).getForDate(date);
      state = AsyncData(plan);
    } on AppFailure catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Replace (create or update) the plan for a date.
  Future<void> replace(
    DateTime date, {
    required List<({
      String subjectId,
      String startTime,
      int durationSeconds,
      int orderIndex,
    })> items,
  }) async {
    state = const AsyncLoading();
    try {
      final plan = await ref.read(dailyPlansRepositoryProvider).replace(date, items: items);
      state = AsyncData(plan);
    } on AppFailure catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final dailyPlansControllerProvider = NotifierProvider<DailyPlansController, AsyncValue<DailyPlanEntity?>>(
  DailyPlansController.new,
);