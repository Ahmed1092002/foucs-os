import 'package:dio/dio.dart';

import '../../../core/domain/daily_review.dart';
import '../../../core/error/app_failure.dart';
import '../../../data/remote/api_client.dart';
import '../../../data/remote/dto/dto.dart';

class DailyReviewsRepository {
  DailyReviewsRepository(this._api);
  final ApiClient _api;

  String _dateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<DailyReviewEntity>> list({DateTime? from, DateTime? to}) async {
    try {
      final resp = await _api.get<List<dynamic>>(
        '/reviews',
        query: {
          if (from != null) 'from': _dateKey(from),
          if (to != null) 'to': _dateKey(to),
        },
      );
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(DailyReviewDto.fromJson)
          .map(_toEntity)
          .toList();
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<DailyReviewEntity?> getForDate(DateTime date) async {
    try {
      final resp = await _api.get<Map<String, dynamic>?>(
        '/reviews/${_dateKey(date)}',
      );
      if (resp.data == null) return null;
      return _toEntity(DailyReviewDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  Future<DailyReviewEntity> upsert(
    DateTime date, {
    int? productivityRating,
    int? energyRating,
    int? focusRating,
    String? wentWell,
    String? blockedBy,
  }) async {
    try {
      final body = <String, dynamic>{
        if (productivityRating != null) 'productivityRating': productivityRating,
        if (energyRating != null) 'energyRating': energyRating,
        if (focusRating != null) 'focusRating': focusRating,
        if (wentWell != null) 'wentWell': wentWell,
        if (blockedBy != null) 'blockedBy': blockedBy,
      };
      final resp = await _api.put<Map<String, dynamic>>(
        '/reviews/${_dateKey(date)}',
        body: body,
      );
      return _toEntity(DailyReviewDto.fromJson(resp.data!));
    } on DioException catch (e) {
      throw e.error as AppFailure;
    }
  }

  DailyReviewEntity _toEntity(DailyReviewDto d) => DailyReviewEntity(
        id: d.id,
        userId: d.userId,
        reviewDate: d.reviewDate,
        productivityRating: d.productivityRating,
        energyRating: d.energyRating,
        focusRating: d.focusRating,
        wentWell: d.wentWell,
        blockedBy: d.blockedBy,
        createdAt: d.createdAt,
      );

  // ---- upsert for sync ----

  Future<void> upsertReview(DailyReviewDto dto) async {
    // No-op for remote repo; SyncService handles upsert directly.
  }
}