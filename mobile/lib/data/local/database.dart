import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/tables.dart';

part 'database.g.dart';

/// Drift database for Focus OS.
@DriftDatabase(tables: [
  Users,
  Areas,
  Subjects,
  OutboxEntries,
  StudySessions,
  Courses,
  Modules,
  Lessons,
])
class Database extends _$Database {
  Database([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'focus_os'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // V1: courses/modules/lessons for the course tree.
            await m.createTable(courses);
            await m.createTable(modules);
            await m.createTable(lessons);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}