import 'package:drift/drift.dart';

/// Per-row sync state. `synced` rows match the backend; `dirty` rows have
/// local mutations that need pushing; `conflict` rows need user resolution.
enum SyncStatus { synced, dirty, conflict }

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get timezone => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class Areas extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get areaId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  RealColumn get targetHours => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Course tree (V1). Mirrors backend `courses`, `modules`, `lessons`.
class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class Modules extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('not_started'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()(); // 'area' | 'subject' | 'session'
  TextColumn get op => text()();     // 'create' | 'update' | 'delete' | 'complete'
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON-encoded body
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

/// Mirrors the backend `study_sessions` table.
/// See docs/08-database-schema.md.
class StudySessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectId => text().nullable()();   // R-S4: SetNull on delete
  TextColumn get topic => text().nullable()();
  IntColumn get plannedDurationSeconds => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get actualDurationSeconds => integer().nullable()();
  IntColumn get pausedIntervalsSeconds => integer().withDefault(const Constant(0))();
  TextColumn get state => text()();          // running | paused | completed | cancelled
  TextColumn get goalText => text().nullable()();
  TextColumn get goalResult => text().nullable()(); // yes | partially | no
  IntColumn get focusRating => integer().nullable()();
  IntColumn get energyRating => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}