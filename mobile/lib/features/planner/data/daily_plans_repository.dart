import 'package:dio/dio.dart';

import '../../../core/domain/plan.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class DailyPlansRepository {
  DailyPlansRepository(this._api);
  final ApiClient _api;

  Future<DailyPlanEntity> getForDate(DateTime date) async {
    try {
      final dateStr = _dateKey(date);
      final resp = await _api.get<Map<String, dynamic>>('/plans/$dateStr');
      return _toEntity(resp.data!);
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<DailyPlanEntity> replace(
    DateTime date, {
    required List<({String subjectId, String startTime, int durationSeconds, int orderIndex})> items,
  }) async {
    try {
      final dateStr = _dateKey(date);
      final resp = await _api.put<Map<String, dynamic>>(
        '/plans/$dateStr',
        body: {
          'items': items
              .map((i) => {
                    'subjectId': i.subjectId,
                    'startTime': i.startTime,
                    'durationSeconds': i.durationSeconds,
                    'orderIndex': i.orderIndex,
                  })
              .toList(),
        },
      );
      return _toEntity(resp.data!);
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  DailyPlanEntity _toEntity(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((i) => PlanItemEntity(
              id: i['id'] as String,
              dailyPlanId: i['dailyPlanId'] as String,
              subjectId: i['subjectId'] as String,
              startTime: _extractHhMm(i['startTime']),
              durationSeconds: i['durationSeconds'] as int,
              orderIndex: i['orderIndex'] as int,
            ))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return DailyPlanEntity(
      id: j['id'] as String? ?? '',
      userId: j['userId'] as String? ?? '',
      planDate: DateTime.parse(j['planDate'] as String),
      items: items,
    );
  }

  /// Backend serializes Time as `1970-01-01THH:MM:SSZ`; pull the HH:MM back out.
  String _extractHhMm(dynamic raw) {
    final s = raw as String;
    final tIdx = s.indexOf('T');
    if (tIdx < 0) return s;            // already 'HH:MM' from somewhere
    final hhmm = s.substring(tIdx + 1, tIdx + 6);
    return hhmm;
  }

  // ---- upsert for sync ----

  Future<void> upsertPlan(DailyPlanDto dto) async {
    // No-op for remote repo; SyncService handles upsert directly.
  }
}