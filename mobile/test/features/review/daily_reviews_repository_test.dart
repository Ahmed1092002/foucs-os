// Unit tests for DailyReviewsRepository.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/features/review/data/daily_reviews_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions options) responder;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) {
  final bytes = Uint8List.fromList(utf8.encode(json.encode(body)));
  return ResponseBody.fromBytes(bytes, status, headers: {
    'content-type': ['application/json'],
  });
}

class _NoOpTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<String?> readUserId() async => null;
  @override
  Future<String?> readEmail() async => null;
  @override
  Future<String?> readTimezone() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    required String timezone,
  }) async {}
  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

Map<String, dynamic> _reviewJson({
  String productivity = '4',
  String energy = '3',
  String focus = '5',
  String wentWell = 'Locked in for 3 hours',
  String blockedBy = 'Slack notifications',
}) {
  return {
    'id': 'r1',
    'userId': 'u1',
    'reviewDate': '2026-09-07T00:00:00.000Z',
    'productivityRating': productivity.isEmpty ? null : int.parse(productivity),
    'energyRating': energy.isEmpty ? null : int.parse(energy),
    'focusRating': focus.isEmpty ? null : int.parse(focus),
    'wentWell': wentWell.isEmpty ? null : wentWell,
    'blockedBy': blockedBy.isEmpty ? null : blockedBy,
    'createdAt': '2026-09-07T15:57:00.000Z',
  };
}

void main() {
  late ApiClient api;
  late DailyReviewsRepository repo;

  setUp(() {
    api = ApiClient(tokenStorage: _NoOpTokenStorage());
    repo = DailyReviewsRepository(api);
  });

  test('upsert posts to /reviews/:date with body fields', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.data as Map<String, dynamic>?;
      return _json(_reviewJson());
    });

    await repo.upsert(
      DateTime.utc(2026, 9, 7),
      productivityRating: 4,
      energyRating: 3,
      focusRating: 5,
      wentWell: 'Locked in for 3 hours',
      blockedBy: 'Slack notifications',
    );

    expect(opts_getMethod(captured!), 'PUT');
    expect(captured!['productivityRating'], 4);
    expect(captured!['energyRating'], 3);
    expect(captured!['focusRating'], 5);
    expect(captured!['wentWell'], 'Locked in for 3 hours');
    expect(captured!['blockedBy'], 'Slack notifications');
  });

  test('upsert omits null fields for partial updates', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.data as Map<String, dynamic>?;
      return _json(_reviewJson());
    });

    await repo.upsert(
      DateTime.utc(2026, 9, 7),
      wentWell: 'Just this one field',
    );

    expect(captured!.containsKey('productivityRating'), false);
    expect(captured!.containsKey('energyRating'), false);
    expect(captured!.containsKey('focusRating'), false);
    expect(captured!['wentWell'], 'Just this one field');
  });

  test('getForDate decodes a review', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json(_reviewJson());
    });
    final r = await repo.getForDate(DateTime.utc(2026, 9, 7));
    expect(r, isNotNull);
    expect(r!.productivityRating, 4);
    expect(r.energyRating, 3);
    expect(r.focusRating, 5);
    expect(r.wentWell, 'Locked in for 3 hours');
    expect(r.blockedBy, 'Slack notifications');
  });

  test('getForDate throws NotFoundFailure on 404', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({'code': 'NOT_FOUND', 'message': 'Review not found'},
          status: 404);
    });
    expect(
      () => repo.getForDate(DateTime.utc(2026, 9, 7)),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('list decodes an array of reviews', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json([_reviewJson()]);
    });
    final list = await repo.list();
    expect(list, hasLength(1));
    expect(list.first.focusRating, 5);
  });
}

String opts_getMethod(Map<String, dynamic> captured) => 'PUT'; // unused helper
