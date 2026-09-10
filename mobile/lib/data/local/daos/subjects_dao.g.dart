// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_dao.dart';

// ignore_for_file: type=lint
mixin _$SubjectsDaoMixin on DatabaseAccessor<Database> {
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $OutboxEntriesTable get outboxEntries => attachedDatabase.outboxEntries;
  SubjectsDaoManager get managers => SubjectsDaoManager(this);
}

class SubjectsDaoManager {
  final _$SubjectsDaoMixin _db;
  SubjectsDaoManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db.attachedDatabase, _db.outboxEntries);
}
