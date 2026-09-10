import 'package:dio/dio.dart';

import '../../../core/domain/entities.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class AreasRepository {
  AreasRepository(this._api);
  final ApiClient _api;

  Future<List<AreaEntity>> list({bool includeArchived = false}) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/areas',
        query: {'includeArchived': includeArchived},
      );
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(AreaDto.fromJson)
          .map(_toEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<AreaEntity> getOne(String id) async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/areas/$id');
      return _toEntity(AreaDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<AreaEntity> create({
    required String name,
    required String color,
    String? icon,
  }) async {
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        '/areas',
        body: {'name': name, 'color': color, if (icon != null) 'icon': icon},
      );
      return _toEntity(AreaDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<AreaEntity> update(String id, {
    String? name,
    String? color,
    String? icon,
    bool? archived,
  }) async {
    try {
      final resp = await _api.patch<Map<String, dynamic>>(
        '/areas/$id',
        body: {
          if (name != null) 'name': name,
          if (color != null) 'color': color,
          if (icon != null) 'icon': icon,
          if (archived != null) 'archived': archived,
        },
      );
      return _toEntity(AreaDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('/areas/$id');
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  AreaEntity _toEntity(AreaDto d) => AreaEntity(
        id: d.id,
        userId: d.userId,
        name: d.name,
        color: d.color,
        icon: d.icon,
        archivedAt: d.archivedAt,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );
}