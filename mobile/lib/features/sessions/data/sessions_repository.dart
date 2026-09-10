import 'package:dio/dio.dart';

import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class SessionsRepository {
  SessionsRepository(this._api);
  final ApiClient _api;

  Future<List<SessionEntity>> list({String? subjectId, int? limit}) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>(
        '/sessions',
        query: {
          if (subjectId != null) 'subjectId': subjectId,
          if (limit != null) 'limit': limit,
        },
      );
      final items = (resp.data?['items'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(SessionDto.fromJson)
          .map(_toEntity)
          .toList();
      return items;
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SessionEntity?> active() async {
    try {
      final resp = await _api.get<Map<String, dynamic>?>('/sessions/active');
      if (resp.data == null) return null;
      return _toEntity(SessionDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SessionEntity> create({
    required String id,
    required String subjectId,
    required int plannedDurationSeconds,
    required DateTime startedAt,
    String? topic,
    String? goalText,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/sessions',
        body: {
          'id': id,
          'subjectId': subjectId,
          if (topic != null) 'topic': topic,
          'plannedDurationSeconds': plannedDurationSeconds,
          'startedAt': startedAt.toUtc().toIso8601String(),
          if (goalText != null) 'goalText': goalText,
        },
      );
      return _toEntity(SessionDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SessionEntity> patch(String id, {
    String? state,
    int? pausedIntervalsSeconds,
    DateTime? endedAt,
  }) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/sessions/$id',
        body: {
          if (state != null) 'state': state,
          if (pausedIntervalsSeconds != null)
            'pausedIntervalsSeconds': pausedIntervalsSeconds,
          if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
        },
      );
      return _toEntity(SessionDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SessionEntity> complete(
    String id, {
    required int actualDurationSeconds,
    required int pausedIntervalsSeconds,
    required DateTime endedAt,
    String? goalResult,
    int? focusRating,
    int? energyRating,
    String? notes,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/sessions/$id/complete',
        body: {
          'actualDurationSeconds': actualDurationSeconds,
          'pausedIntervalsSeconds': pausedIntervalsSeconds,
          'endedAt': endedAt.toUtc().toIso8601String(),
          if (goalResult != null) 'goalResult': goalResult,
          if (focusRating != null) 'focusRating': focusRating,
          if (energyRating != null) 'energyRating': energyRating,
          if (notes != null) 'notes': notes,
        },
      );
      return _toEntity(SessionDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SessionEntity> cancel(String id) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/sessions/$id/cancel',
      );
      return _toEntity(SessionDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  SessionEntity _toEntity(SessionDto d) => SessionEntity(
        id: d.id,
        subjectId: d.subjectId,
        topic: d.topic,
        plannedDurationSeconds: d.plannedDurationSeconds,
        startedAt: d.startedAt,
        endedAt: d.endedAt,
        actualDurationSeconds: d.actualDurationSeconds,
        pausedIntervalsSeconds: d.pausedIntervalsSeconds,
        state: d.state,
        goalText: d.goalText,
        goalResult: d.goalResult,
        focusRating: d.focusRating,
        energyRating: d.energyRating,
        notes: d.notes,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );
}