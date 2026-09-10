import 'package:dio/dio.dart';

import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class SubjectsRepository {
  SubjectsRepository(this._api);
  final ApiClient _api;

  Future<List<SubjectEntity>> list({String? areaId, String? status}) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/subjects',
        query: {
          if (areaId != null) 'areaId': areaId,
          if (status != null) 'status': status,
        },
      );
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(SubjectDto.fromJson)
          .map(_toEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SubjectEntity> create({
    required String areaId,
    required String name,
    String? description,
    String? color,
    double targetHours = 0,
    int priority = 0,
    DateTime? deadline,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/subjects',
        body: {
          'areaId': areaId,
          'name': name,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
          'targetHours': targetHours,
          'priority': priority,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
        },
      );
      return _toEntity(SubjectDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<SubjectEntity> update(String id, {
    String? name,
    String? description,
    String? color,
    double? targetHours,
    int? priority,
    DateTime? deadline,
    String? status,
  }) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/subjects/$id',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
          if (targetHours != null) 'targetHours': targetHours,
          if (priority != null) 'priority': priority,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          if (status != null) 'status': status,
        },
      );
      return _toEntity(SubjectDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('/subjects/$id');
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  SubjectEntity _toEntity(SubjectDto d) => SubjectEntity(
        id: d.id,
        userId: d.userId,
        areaId: d.areaId,
        name: d.name,
        description: d.description,
        color: d.color,
        targetHours: d.targetHours,
        status: d.status,
        priority: d.priority,
        deadline: d.deadline,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );
}