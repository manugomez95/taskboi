import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskboi/core/database/database.dart';

void main() {
  test(
    'upgrades a v9 database and removes retired assignment and webhook columns',
    () async {
      final tempDirectory =
          await Directory.systemTemp.createTemp('taskboi_v9_migration_');
      final databaseFile = File('${tempDirectory.path}/taskboi.sqlite');
      AppDatabase? database;

      try {
        database = AppDatabase.forTesting(NativeDatabase(databaseFile));
        await database.customStatement(
          "INSERT INTO projects (id, user_id, name) "
          "VALUES ('project-1', 'user-1', 'Kept project')",
        );
        await database.customStatement(
          "INSERT INTO tasks (id, project_id, user_id, title) "
          "VALUES ('task-1', 'project-1', 'user-1', 'Kept task')",
        );

        // Build the historical v9 shape from the generated current schema. This
        // keeps the fixture deterministic without maintaining a second Drift
        // database class solely to recreate an old schema version.
        await database.customStatement(
          "ALTER TABLE projects ADD COLUMN default_assignee "
          "TEXT NOT NULL DEFAULT 'manuel'",
        );
        await database.customStatement(
          "ALTER TABLE projects ADD COLUMN agent_webhook_url "
          "TEXT NOT NULL DEFAULT ''",
        );
        await database.customStatement(
          "ALTER TABLE tasks ADD COLUMN assigned_to "
          "TEXT NOT NULL DEFAULT 'manuel'",
        );
        await database.customStatement('PRAGMA user_version = 9');
        await database.close();
        database = null;

        database = AppDatabase.forTesting(NativeDatabase(databaseFile));

        final projectColumns = await _columnNames(database, 'projects');
        final taskColumns = await _columnNames(database, 'tasks');
        expect(projectColumns, isNot(contains('default_assignee')));
        expect(projectColumns, isNot(contains('agent_webhook_url')));
        expect(taskColumns, isNot(contains('assigned_to')));

        final project = await database.select(database.projects).getSingle();
        expect(project.id, 'project-1');
        expect(project.name, 'Kept project');

        final task = await database.select(database.tasks).getSingle();
        expect(task.id, 'task-1');
        expect(task.projectId, 'project-1');
        expect(task.title, 'Kept task');

        final version = await database
            .customSelect('PRAGMA user_version')
            .map((row) => row.read<int>('user_version'))
            .getSingle();
        expect(version, database.schemaVersion);
      } finally {
        await database?.close();
        await tempDirectory.delete(recursive: true);
      }
    },
  );
}

Future<Set<String>> _columnNames(
  AppDatabase database,
  String table,
) async {
  final rows = await database.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toSet();
}
