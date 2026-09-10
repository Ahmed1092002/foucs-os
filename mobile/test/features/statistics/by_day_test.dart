// Unit tests for StatisticsRepository.byDay.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/domain/stats.dart';
import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/features/statistics/data/statistics_repository.dart';

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

void main() {
  late ApiClient api;
  late StatisticsRepository repo;

  setUp(() {
    api = ApiClient(tokenStorage: _NoOpTokenStorage());
    repo = StatisticsRepository(api);
  });

  test('byDay decodes the array shape', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json([
        {'date': '2026-09-01', 'plannedSeconds': 0, 'actualSeconds': 0},
        {'date': '2026-09-02', 'plannedSeconds': 1800, 'actualSeconds': 1500},
        {'date': '2026-09-03', 'plannedSeconds': 0, 'actualSeconds': 0},
      ]);
    });
    final result = await repo.byDay(
      DateTime.utc(2026, 9, 1),
      DateTime.utc(2026, 9, 3),
    );
    expect(result, hasLength(3));
    expect(result[1].plannedSeconds, 1800);
    expect(result[1].actualSeconds, 1500);
  });

  test('byDay sends from/to in the wire format', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.queryParameters;
      return _json([]);
    });
    await repo.byDay(
      DateTime.utc(2026, 9, 1),
      DateTime.utc(2026, 9, 7),
    );
    expect(captured!['from'], '2026-09-01');
    expect(captured!['to'], '2026-09-07');
  });

  test('summary with range=all sends the right wire value', () async {
    Map<String, dynamic>? captured;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      captured = opts.queryParameters;
      return _json({
        'range': 'all',
        'from': '2000-01-01T00:00:00.000Z',
        'to': '2026-09-07T00:00:00.000Z',
        'totalActualSeconds': 0,
        'totalPlannedSeconds': 0,
        'sessionsCompleted': 0,
        'completionRate': null,
      });
    });
    await repo.summary(StatsRange.all);
    expect(captured!['range'], 'all');
  });

  test('byDay failure maps to UnknownFailure on 500', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({'code': 'INTERNAL', 'message': 'Server error'},
          status: 500);
    });
    expect(
      () => repo.byDay(DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 7)),
      throwsA(isA<UnknownFailure>()),
    );
  });
}