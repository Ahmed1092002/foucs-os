// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'areas_dao.dart';

// ignore_for_file: type=lint
mixin _$AreasDaoMixin on DatabaseAccessor<Database> {
  $AreasTable get areas => attachedDatabase.areas;
  $OutboxEntriesTable get outboxEntries => attachedDatabase.outboxEntries;
  AreasDaoManager get managers => AreasDaoManager(this);
}

class AreasDaoManager {
  final _$AreasDaoMixin _db;
  AreasDaoManager(this._db);
  $$AreasTableTableManager get areas =>
      $$AreasTableTableManager(_db.attachedDatabase, _db.areas);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db.attachedDatabase, _db.outboxEntries);
}
