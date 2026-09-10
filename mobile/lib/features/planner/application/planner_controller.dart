import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/domain/plan.dart';
import '../../../core/domain/entities.dart';
import '../../../data/notifications/notification_service.dart';

class PlannerState {
  final DateTime date;
  final List<PlanItemEntity> items;
  final List<SubjectEntity> subjects;
  final bool isLoading;
  final String? error;

  const PlannerState({
    required this.date,
    required this.items,
    required this.subjects,
    required this.isLoading,
    this.error,
  });

  PlannerState copyWith({
    DateTime? date,
    List<PlanItemEntity>? items,
    List<SubjectEntity>? subjects,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PlannerState(
      date: date ?? this.date,
      items: items ?? this.items,
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalPlannedSeconds =>
      items.fold(0, (s, i) => s + i.durationSeconds);

  String? get warning {
    final hours = totalPlannedSeconds / 3600;
    if (hours >= 10) return 'red';
    if (hours >= 6) return 'yellow';
    return null;
  }
}

class PlannerController extends FamilyAsyncNotifier<PlannerState, DateTime> {
  @override
  Future<PlannerState> build(DateTime date) async {
    final repo = ref.read(dailyPlansRepositoryProvider);
    final subjectsRepo = ref.read(subjectsRepositoryProvider);
    final plan = await repo.getForDate(date);
    final subjects = await subjectsRepo.list();
    return PlannerState(
      date: date,
      items: plan.items,
      subjects: subjects,
      isLoading: false,
    );
  }

  Future<void> addItem({
    required String subjectId,
    required String startTime,
    required int durationSeconds,
  }) async {
    final current = state.value!;
    final orderIndex = current.items.length;
    final newItem = PlanItemEntity(
      id: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      dailyPlanId: '',
      subjectId: subjectId,
      startTime: startTime,
      durationSeconds: durationSeconds,
      orderIndex: orderIndex,
    );
    final next = current.copyWith(
      items: [...current.items, newItem],
      clearError: true,
    );
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> removeItem(int index) async {
    final current = state.value!;
    final next = current.copyWith(
      items: [
        for (var i = 0; i < current.items.length; i++)
          if (i != index) current.items[i],
      ],
    );
    state = AsyncData(next);
    await _save(next);
  }

  Future<void> _save(PlannerState s) async {
    try {
      await ref.read(dailyPlansRepositoryProvider).replace(
        s.date,
        items: s.items
            .map((i) => (
                  subjectId: i.subjectId,
                  startTime: i.startTime,
                  durationSeconds: i.durationSeconds,
                  orderIndex: i.orderIndex,
                ))
            .toList(),
      );
      // After saving, schedule session reminders for every item.
      await _rescheduleReminders(s);
    } catch (e) {
      state = AsyncData(s.copyWith(error: '$e'));
    }
  }

  Future<void> _rescheduleReminders(PlannerState s) async {
    final notif = ref.read(notificationServiceProvider);
    await notif.cancelAll();
    if (s.items.isEmpty) return;
    final subjects = s.subjects;
    for (var i = 0; i < s.items.length; i++) {
      final item = s.items[i];
      final subject = subjects.firstWhere(
        (sub) => sub.id == item.subjectId,
        orElse: () => _unknownSubject,
      );
      final startDt = _hhmmToDateTime(s.date, item.startTime);
      final reminder = composeSessionReminder(
        subjectName: subject.name,
        durationMinutes: item.durationSeconds ~/ 60,
        lead: const Duration(minutes: 10),
      );
      await notif.scheduleSessionReminder(
        id: 1000 + i, // simple id space
        title: reminder.title,
        body: reminder.body,
        whenLocal: startDt,
      );
    }
  }

  DateTime _hhmmToDateTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

final plannerControllerProvider =
    AsyncNotifierProvider.family<PlannerController, PlannerState, DateTime>(
  PlannerController.new,
);

final _unknownSubject = SubjectEntity(
  id: '',
  userId: '',
  areaId: '',
  name: 'Subject',
  description: null,
  color: null,
  targetHours: 0,
  status: 'active',
  priority: 0,
  deadline: null,
  createdAt: _epoch,
  updatedAt: _epoch,
);

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);