import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/tables.dart';

part 'areas_dao.g.dart';

@DriftAccessor(tables: [Areas, OutboxEntries])
class AreasDao extends DatabaseAccessor<Database> with _$AreasDaoMixin {
  AreasDao(super.db);

  Future<List<Area>> listAll({bool includeArchived = false}) {
    final q = select(areas);
    if (!includeArchived) {
      q.where((t) => t.archivedAt.isNull());
    }
    q.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return q.get();
  }

  Future<Area?> findById(String id) =>
      (select(areas)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Area> upsert({
    required String id,
    required String userId,
    required String name,
    required String color,
    String? icon,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now().toUtc();
    await into(areas).insertOnConflictUpdate(
      AreasCompanion.insert(
        id: id,
        userId: userId,
        name: name,
        color: color,
        icon: Value(icon),
        archivedAt: Value(archivedAt),
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
        syncStatus: SyncStatus.synced,
      ),
    );
    return (await findById(id))!;
  }

  Future<Area> create({
    required String id,
    required String userId,
    required String name,
    required String color,
    String? icon,
  }) async {
    final now = DateTime.now().toUtc();
    final area = await into(areas).insertReturning(
      AreasCompanion.insert(
        id: id,
        userId: userId,
        name: name,
        color: color,
        icon: Value(icon),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.dirty,
      ),
    );
    await _enqueue('area', 'create', id, {
      'id': id,
      'userId': userId,
      'name': name,
      'color': color,
      if (icon != null) 'icon': icon,
    });
    return area;
  }

  Future<Area> edit(
    String id, {
    String? name,
    String? color,
    String? icon,
    bool? archived,
  }) async {
    final now = DateTime.now().toUtc();
    final current = await findById(id);
    if (current == null) throw StateError('Area not found locally');
    final updated = await (update(areas)..where((t) => t.id.equals(id))).writeReturning(
      AreasCompanion(
        name: name == null ? const Value.absent() : Value(name),
        color: color == null ? const Value.absent() : Value(color),
        icon: icon == null ? const Value.absent() : Value(icon),
        archivedAt:
            archived == null ? const Value.absent() : Value(archived ? now : null),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.dirty),
      ),
    );
    await _enqueue('area', 'update', id, {
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (archived != null) 'archived': archived,
    });
    return updated.first;
  }

  Future<void> softDelete(String id) async {
    await edit(id, archived: true);
  }

  Future<void> markSynced(String id) async {
    await (update(areas)..where((t) => t.id.equals(id))).write(
      const AreasCompanion(syncStatus: Value(SyncStatus.synced)),
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