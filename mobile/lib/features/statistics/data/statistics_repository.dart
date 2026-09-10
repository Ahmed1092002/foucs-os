import 'package:dio/dio.dart';

import '../../../core/domain/stats.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';

class StatisticsRepository {
  StatisticsRepository(this._api);
  final ApiClient _api;

  Future<StatsSummaryEntity> summary(StatsRange range) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/stats/summary',
        query: {'range': range.wire},
      );
      final j = resp.data!;
      return StatsSummaryEntity(
        range: range,
        from: DateTime.parse(j['from'] as String),
        to: DateTime.parse(j['to'] as String),
        totalActualSeconds: j['totalActualSeconds'] as int,
        totalPlannedSeconds: j['totalPlannedSeconds'] as int,
        sessionsCompleted: j['sessionsCompleted'] as int,
        completionRate: (j['completionRate'] as num?)?.toDouble(),
      );
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<List<SubjectStatEntity>> bySubject(StatsRange range) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/stats/by-subject',
        query: {'range': range.wire},
      );
      return (resp.data ?? []).cast<Map<String, dynamic>>().map((j) {
        return SubjectStatEntity(
          subjectId: j['subjectId'] as String,
          name: j['name'] as String,
          color: j['color'] as String?,
          actualSeconds: j['actualSeconds'] as int,
          sessions: j['sessions'] as int,
        );
      }).toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<StreakEntity> streak() async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/stats/streak');
      final j = resp.data!;
      return StreakEntity(
        current: j['current'] as int,
        longest: j['longest'] as int,
        lastStudyDate: j['lastStudyDate'] != null
            ? DateTime.parse(j['lastStudyDate'] as String)
            : null,
      );
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<List<DailyTotalEntity>> byDay(DateTime from, DateTime to) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/stats/by-day',
        query: {
          'from': _dateKey(from),
          'to': _dateKey(to),
        },
      );
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map((j) => DailyTotalEntity(
                date: DateTime.parse(j['date'] as String),
                plannedSeconds: j['plannedSeconds'] as int,
                actualSeconds: j['actualSeconds'] as int,
              ))
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}