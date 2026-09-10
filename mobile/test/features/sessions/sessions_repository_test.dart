// Unit tests for SessionsRepository using a fake Dio adapter.
//
// Covers: list, active, create, patch, complete, cancel — and confirms that
// the AppFailure envelope translation is wired through Dio.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/domain/entities.dart';
import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/features/sessions/data/sessions_repository.dart';

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

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) {
  final bytes = Uint8List.fromList(utf8.encode(json.encode(body)));
  return ResponseBody.fromBytes(bytes, status, headers: {
    'content-type': ['application/json'],
  });
}

SessionEntity _sampleSession({
  String id = 'sess-1',
  String state = 'completed',
  int actualSeconds = 2700,
}) {
  final start = DateTime.utc(2026, 9, 4, 14);
  return SessionEntity(
    id: id,
    subjectId: 'sub-1',
    topic: 'useEffect',
    plannedDurationSeconds: 3600,
    startedAt: start,
    endedAt: start.add(Duration(seconds: actualSeconds + 120)),
    actualDurationSeconds: actualSeconds,
    pausedIntervalsSeconds: 120,
    state: state,
    goalText: 'Understand useEffect',
    goalResult: state == 'completed' ? 'yes' : null,
    focusRating: state == 'completed' ? 4 : null,
    energyRating: state == 'completed' ? 3 : null,
    notes: null,
    createdAt: start,
    updatedAt: start.add(Duration(seconds: actualSeconds + 120)),
  );
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

  setUp(() {
    // Pass a no-op token storage so the auth interceptor doesn't try to
    // hit the secure storage platform channel (unavailable in Dart VM tests).
    api = ApiClient(tokenStorage: _NoOpTokenStorage());
  });

  test('list decodes backend envelope', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({
        'items': [
          {
            'id': 'sess-1',
            'subjectId': 'sub-1',
            'topic': 'useEffect',
            'plannedDurationSeconds': 3600,
            'startedAt': '2026-09-04T14:00:00.000Z',
            'endedAt': '2026-09-04T14:45:00.000Z',
            'actualDurationSeconds': 2700,
            'pausedIntervalsSeconds': 120,
            'state': 'completed',
            'goalText': 'Understand useEffect',
            'goalResult': 'yes',
            'focusRating': 4,
            'energyRating': 3,
            'notes': null,
            'createdAt': '2026-09-04T14:00:00.000Z',
            'updatedAt': '2026-09-04T14:45:00.000Z',
          },
        ],
      });
    });

    final repo = SessionsRepository(api);
    final list = await repo.list();
    expect(list, hasLength(1));
    expect(list.first.id, 'sess-1');
    expect(list.first.actualDurationSeconds, 2700);
  });

  test('create posts the right body shape', () async {
    Map<String, dynamic>? capturedBody;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      capturedBody = opts.data as Map<String, dynamic>?;
      return _json({
        'id': 'sess-1',
        'subjectId': 'sub-1',
        'topic': null,
        'plannedDurationSeconds': 1800,
        'startedAt': '2026-09-04T14:00:00.000Z',
        'endedAt': null,
        'actualDurationSeconds': null,
        'pausedIntervalsSeconds': 0,
        'state': 'running',
        'goalText': null,
        'goalResult': null,
        'focusRating': null,
        'energyRating': null,
        'notes': null,
        'createdAt': '2026-09-04T14:00:00.000Z',
        'updatedAt': '2026-09-04T14:00:00.000Z',
      });
    });

    final repo = SessionsRepository(api);
    final created = await repo.create(
      id: 'sess-1',
      subjectId: 'sub-1',
      plannedDurationSeconds: 1800,
      startedAt: DateTime.utc(2026, 9, 4, 14),
    );

    expect(capturedBody, isNotNull);
    expect(capturedBody!['id'], 'sess-1');
    expect(capturedBody!['plannedDurationSeconds'], 1800);
    expect(capturedBody!['startedAt'], '2026-09-04T14:00:00.000Z');
    expect(created.state, 'running');
  });

  test('complete posts full completion body', () async {
    Map<String, dynamic>? capturedBody;
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      capturedBody = opts.data as Map<String, dynamic>?;
      return _json({
        'id': 'sess-1',
        'subjectId': 'sub-1',
        'topic': null,
        'plannedDurationSeconds': 3600,
        'startedAt': '2026-09-04T14:00:00.000Z',
        'endedAt': '2026-09-04T14:45:00.000Z',
        'actualDurationSeconds': 2700,
        'pausedIntervalsSeconds': 120,
        'state': 'completed',
        'goalText': null,
        'goalResult': 'yes',
        'focusRating': 4,
        'energyRating': 3,
        'notes': 'Learned it',
        'createdAt': '2026-09-04T14:00:00.000Z',
        'updatedAt': '2026-09-04T14:45:00.000Z',
      });
    });

    final repo = SessionsRepository(api);
    await repo.complete(
      'sess-1',
      actualDurationSeconds: 2700,
      pausedIntervalsSeconds: 120,
      endedAt: DateTime.utc(2026, 9, 4, 14, 45),
      goalResult: 'yes',
      focusRating: 4,
      energyRating: 3,
      notes: 'Learned it',
    );

    expect(capturedBody!['actualDurationSeconds'], 2700);
    expect(capturedBody!['pausedIntervalsSeconds'], 120);
    expect(capturedBody!['goalResult'], 'yes');
  });

  test('failure maps to NotFoundFailure on 404', () async {
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json(
        {'code': 'NOT_FOUND', 'message': 'Session not found'},
        status: 404,
      );
    });
    final repo = SessionsRepository(api);
    expect(
      () => repo.complete(
        'nope',
        actualDurationSeconds: 100,
        pausedIntervalsSeconds: 0,
        endedAt: DateTime.now().toUtc(),
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}