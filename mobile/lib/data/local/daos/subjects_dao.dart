import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/tables.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects, OutboxEntries])
class SubjectsDao extends DatabaseAccessor<Database> with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Future<List<Subject>> listAll({String? areaId, String? status}) {
    final q = select(subjects);
    if (areaId != null) q.where((t) => t.areaId.equals(areaId));
    if (status != null) q.where((t) => t.status.equals(status));
    q.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.get();
  }

  Future<Subject?> findById(String id) =>
      (select(subjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Subject> upsert({
    required String id,
    required String userId,
    required String areaId,
    required String name,
    String? description,
    String? color,
    double? targetHours,
    int? priority,
    DateTime? deadline,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await into(subjects).insertOnConflictUpdate(
      SubjectsCompanion.insert(
        id: id,
        userId: userId,
        areaId: areaId,
        name: name,
        description: Value(description),
        color: Value(color),
        targetHours: Value(targetHours ?? 0),
        priority: Value(priority ?? 0),
        deadline: Value(deadline),
        status: Value(status ?? 'active'),
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
        syncStatus: SyncStatus.synced,
      ),
    );
    return (await findById(id))!;
  }

  Future<Subject> create({
    required String id,
    required String userId,
    required String areaId,
    required String name,
    String? description,
    String? color,
    double targetHours = 0,
    int priority = 0,
    DateTime? deadline,
  }) async {
    final now = DateTime.now().toUtc();
    final subject = await into(subjects).insertReturning(
      SubjectsCompanion.insert(
        id: id,
        userId: userId,
        areaId: areaId,
        name: name,
        description: Value(description),
        color: Value(color),
        targetHours: Value(targetHours),
        priority: Value(priority),
        deadline: Value(deadline),
        status: const Value('active'),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.dirty,
      ),
    );
    await _enqueue('subject', 'create', id, {
      'id': id,
      'areaId': areaId,
      'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      'targetHours': targetHours,
      'priority': priority,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
    });
    return subject;
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().toUtc();
    await (update(subjects)..where((t) => t.id.equals(id))).write(
      const SubjectsCompanion(
        status: Value('archived'),
        syncStatus: Value(SyncStatus.dirty),
        updatedAt: Value.absent(),
      ),
    );
    // No backend support for DELETE yet — pretend it's an update with status=archived.
    await _enqueue('subject', 'update', id, {'status': 'archived'});
  }

  Future<void> markSynced(String id) async {
    await (update(subjects)..where((t) => t.id.equals(id))).write(
      const SubjectsCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  Future<void> _enqueue(String entity, String op, String entityId, Map<String, Object?> payload) async {
    await into(outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        entity: entity,
        op: op,
        entityId: entityId,
        payload: _jsonEncode(payload),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

String _jsonEncode(Object? o) {
  if (o == null) return 'null';
  if (o is num || o is bool) return o.toString();
  if (o is String) return '"${o.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';
  if (o is List) return '[${o.map(_jsonEncode).join(',')}]';
  if (o is Map) return '{${o.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}').join(',')}}';
  throw StateError('unsupported: ${o.runtimeType}');
}