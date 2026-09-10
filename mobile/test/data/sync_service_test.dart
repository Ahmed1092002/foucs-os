// Unit tests for SyncService.
//
// Uses an in-memory Drift NativeDatabase and a fake Dio to verify that
// outbox rows are dispatched to the right repository method based on
// (entity, op), and that AppFailure on push leaves the row queued for
// the next attempt.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_os/core/error/app_failure.dart';
import 'package:focus_os/core/time/time_source.dart';
import 'package:focus_os/data/local/database.dart';
import 'package:focus_os/data/local/daos/sessions_dao.dart';
import 'package:focus_os/data/local/tables/tables.dart';
import 'package:focus_os/data/remote/api_client.dart';
import 'package:focus_os/data/remote/token_storage.dart';
import 'package:focus_os/data/sync/sync_service.dart';
import 'package:focus_os/features/areas/data/areas_repository.dart';
import 'package:focus_os/features/courses/data/courses_repository.dart';
import 'package:focus_os/features/planner/data/daily_plans_repository.dart';
import 'package:focus_os/features/review/data/daily_reviews_repository.dart';
import 'package:focus_os/features/subjects/data/subjects_repository.dart';
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

class _FakeTimeSource implements TimeSource {
  const _FakeTimeSource();
  @override
  DateTime now() => DateTime(2026, 9, 7, 12, 0, 0);
}

Future<Database> _freshDb() async {
  return Database(NativeDatabase.memory());
}

void main() {
  late Database db;
  late ApiClient api;
  late List<RequestOptions> calls;

  setUp(() async {
    db = await _freshDb();
    api = ApiClient(tokenStorage: _NoOpTokenStorage());
    calls = <RequestOptions>[];
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      calls.add(opts);
      // Smart default: echo back a body that matches the endpoint's
      // shape so DTO parsing succeeds.
      if (opts.method == 'POST' && opts.path == '/areas') {
        final body = opts.data as Map<String, dynamic>;
        return _json({
          'id': body['id'] ?? 'x',
          'userId': 'u1',
          'name': body['name'],
          'color': body['color'],
          'icon': body['icon'],
          'archivedAt': null,
          'createdAt': '2026-09-05T00:00:00.000Z',
          'updatedAt': '2026-09-05T00:00:00.000Z',
        });
      }
      return _json({'id': 'x', 'items': [], 'subjects': []});
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('drains queued area creates', () async {
    // Seed an area row + outbox row.
    await db.into(db.areas).insert(AreasCompanion.insert(
          id: 'a1',
          userId: 'u1',
          name: 'Frontend',
          color: '#5B8DEF',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          syncStatus: SyncStatus.dirty,
        ));
    await db.into(db.outboxEntries).insert(OutboxEntriesCompanion.insert(
          entity: 'area',
          op: 'create',
          entityId: 'a1',
          payload: jsonEncode({
              'id': 'a1',
              'userId': 'u1',
              'name': 'Frontend',
              'color': '#5B8DEF',
            }),
          createdAt: DateTime.now().toUtc(),
        ));

    final sync = SyncService(
      db: db,
      dao: SessionsDao(db),
      areasRepo: AreasRepository(api),
      subjectsRepo: SubjectsRepository(api),
      sessionsRepo: SessionsRepository(api),
      coursesRepo: CoursesRepository(api),
      dailyPlansRepo: DailyPlansRepository(api),
      dailyReviewsRepo: DailyReviewsRepository(api),
      apiClient: api,
      timeSource: const _FakeTimeSource(),
    );

    final n = await sync.drainOutbox();
    expect(n, 1);
    expect(calls, isNotEmpty);
    expect(calls.first.method, 'POST');
    expect(calls.first.path, '/areas');

    final synced = (await (db.select(db.areas)..where((t) => t.id.equals('a1'))).getSingle()).syncStatus;
    expect(synced, SyncStatus.synced);

    final remaining = await db.select(db.outboxEntries).get();
    expect(remaining, isEmpty);
  });

  test('AppFailure leaves the row queued and bumps attempts', () async {
    await db.into(db.outboxEntries).insert(OutboxEntriesCompanion.insert(
          entity: 'subject',
          op: 'create',
          entityId: 's1',
          payload: jsonEncode({
              'id': 's1',
              'areaId': 'a1',
              'name': 'React',
              'targetHours': 10,
              'priority': 0,
            }),
          createdAt: DateTime.now().toUtc(),
        ));

    // Force the API to return 409 Conflict.
    api.dio.httpClientAdapter = _FakeAdapter((opts) async {
      return _json({'code': 'CONFLICT', 'message': 'dup'}, status: 409);
    });

    final sync = SyncService(
      db: db,
      dao: SessionsDao(db),
      areasRepo: AreasRepository(api),
      subjectsRepo: SubjectsRepository(api),
      sessionsRepo: SessionsRepository(api),
      coursesRepo: CoursesRepository(api),
      dailyPlansRepo: DailyPlansRepository(api),
      dailyReviewsRepo: DailyReviewsRepository(api),
      apiClient: api,
      timeSource: const _FakeTimeSource(),
    );

    final n = await sync.drainOutbox();
    expect(n, 0);

    final remaining = await db.select(db.outboxEntries).get();
    expect(remaining, hasLength(1));
    expect(remaining.first.attempts, 1);
  });
}