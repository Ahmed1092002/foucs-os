import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/time/time_source.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'sessions_dao.g.dart';

/// Drift DAO for [StudySessions] + [OutboxEntries].
///
/// Reads: list, find by id, active session.
/// Writes: create, update fields (state/paused/endedAt), complete, cancel.
/// Every write also stages an [OutboxEntries] row so the [SyncService] can
/// push to the backend later.
@DriftAccessor(tables: [StudySessions, OutboxEntries])
class SessionsDao extends DatabaseAccessor<Database> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  static const _uuid = Uuid();

  Future<List<StudySession>> listAll({int limit = 200}) {
    return (select(studySessions)
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  Future<StudySession?> active() {
    return (select(studySessions)
          ..where((t) => t.state.isIn(['running', 'paused']))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .get()
        .then((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<StudySession?> findById(String id) {
    return (select(studySessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<StudySession> create({
    required String userId,
    required String subjectId,
    required int plannedDurationSeconds,
    required DateTime startedAt,
    String? topic,
    String? goalText,
    Duration staleAfter = const Duration(hours: 1),
    TimeSource? clock,
  }) async {
    final id = _uuid.v4();
    final now = (clock ?? SystemClock()).now();
    final created = await into(studySessions).insertReturning(
      StudySessionsCompanion.insert(
        id: id,
        userId: userId,
        subjectId: Value(subjectId),
        topic: Value(topic),
        plannedDurationSeconds: plannedDurationSeconds,
        startedAt: startedAt,
        endedAt: const Value(null),
        actualDurationSeconds: const Value(null),
        pausedIntervalsSeconds: const Value(0),
        state: 'running',
        goalText: Value(goalText),
        syncStatus: SyncStatus.dirty,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _enqueue('session', 'create', id, {
      'id': id,
      'subjectId': subjectId,
      'topic': topic,
      'plannedDurationSeconds': plannedDurationSeconds,
      'startedAt': startedAt.toIso8601String(),
      'goalText': goalText,
    });
    return created;
  }

  Future<void> patchState(String id, {
    String? state,
    int? pausedIntervalsSeconds,
    DateTime? endedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await (update(studySessions)..where((t) => t.id.equals(id))).write(
      StudySessionsCompanion(
        state: state == null ? const Value.absent() : Value(state),
        pausedIntervalsSeconds: pausedIntervalsSeconds == null
            ? const Value.absent()
            : Value(pausedIntervalsSeconds),
        endedAt: endedAt == null ? const Value.absent() : Value(endedAt),
        updatedAt: Value(now),
        syncStatus: Value(SyncStatus.dirty),
      ),
    );
    await _enqueue('session', 'update', id, {
      if (state != null) 'state': state,
      if (pausedIntervalsSeconds != null)
        'pausedIntervalsSeconds': pausedIntervalsSeconds,
      if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
    });
  }

  Future<void> complete(
    String id, {
    required DateTime endedAt,
    required int actualDurationSeconds,
    required int pausedIntervalsSeconds,
    String? goalResult,
    int? focusRating,
    int? energyRating,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    await (update(studySessions)..where((t) => t.id.equals(id))).write(
      StudySessionsCompanion(
        state: const Value('completed'),
        endedAt: Value(endedAt),
        actualDurationSeconds: Value(actualDurationSeconds),
        pausedIntervalsSeconds: Value(pausedIntervalsSeconds),
        goalResult: Value(goalResult),
        focusRating: Value(focusRating),
        energyRating: Value(energyRating),
        notes: Value(notes),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.dirty),
      ),
    );
    await _enqueue('session', 'complete', id, {
      'actualDurationSeconds': actualDurationSeconds,
      'pausedIntervalsSeconds': pausedIntervalsSeconds,
      'endedAt': endedAt.toIso8601String(),
      if (goalResult != null) 'goalResult': goalResult,
      if (focusRating != null) 'focusRating': focusRating,
      if (energyRating != null) 'energyRating': energyRating,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> cancel(String id) async {
    final now = DateTime.now().toUtc();
    await (update(studySessions)..where((t) => t.id.equals(id))).write(
      StudySessionsCompanion(
        state: const Value('cancelled'),
        endedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.dirty),
      ),
    );
    await _enqueue('session', 'cancel', id, {});
  }

  Future<void> markSynced(String id) async {
    await (update(studySessions)..where((t) => t.id.equals(id))).write(
      const StudySessionsCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  Future<void> _enqueue(String entity, String op, String entityId, Map<String, Object?> payload) async {
    final encoded = _jsonEncode(payload);
    await into(outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        entity: entity,
        op: op,
        entityId: entityId,
        payload: encoded,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

/// Minimal JSON encoder — avoids importing dart:convert just for one helper.
String _jsonEncode(Object? o) {
  if (o == null) return 'null';
  if (o is num || o is bool) return o.toString();
  if (o is String) {
    return '"${o.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';
  }
  if (o is List) return '[${o.map(_jsonEncode).join(',')}]';
  if (o is Map) {
    return '{${o.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}').join(',')}}';
  }
  throw StateError('unsupported: ${o.runtimeType}');
}