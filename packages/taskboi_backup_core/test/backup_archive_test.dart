import 'dart:convert';

import 'package:taskboi_backup_core/taskboi_backup_core.dart';
import 'package:test/test.dart';

void main() {
  group('archive metadata', () {
    test('publishes the current format and supported major versions', () {
      expect(BackupArchiveMetadata.currentFormatVersion, '1.0');
      expect(BackupArchiveMetadata.supportedMajorVersions, {1});
      expect(BackupArchiveMetadata.supports('1.9'), isTrue);
      expect(BackupArchiveMetadata.supports('2.0'), isFalse);
      expect(BackupArchiveMetadata.supports('1.beta'), isFalse);
    });
  });

  group('nested collection value semantics', () {
    test('BackupProject.tasks is a defensive unmodifiable snapshot', () {
      final tasks = [BackupTask(id: 'task-1', title: 'First')];
      final project = BackupProject(
        id: 'project-1',
        name: 'Project',
        color: 'blue',
        icon: 'folder',
        tasks: tasks,
      );

      tasks.add(BackupTask(id: 'task-2', title: 'Second'));

      expect(project.tasks, hasLength(1));
      expect(
        () => project.tasks.add(BackupTask(id: 'task-3', title: 'Third')),
        throwsUnsupportedError,
      );
    });

    test('BackupTask.subtasks is a defensive unmodifiable snapshot', () {
      final subtasks = [BackupTask(id: 'subtask-1', title: 'First')];
      final task = BackupTask(id: 'task-1', title: 'Task', subtasks: subtasks);

      subtasks.add(BackupTask(id: 'subtask-2', title: 'Second'));

      expect(task.subtasks, hasLength(1));
      expect(
        () => task.subtasks.add(BackupTask(id: 'subtask-3', title: 'Third')),
        throwsUnsupportedError,
      );
    });

    test('BackupTask.comments is a defensive unmodifiable snapshot', () {
      final comments = [
        BackupComment(
          id: 'comment-1',
          content: 'First',
          createdAt: DateTime.utc(2026),
        ),
      ];
      final task = BackupTask(id: 'task-1', title: 'Task', comments: comments);

      comments.add(
        BackupComment(
          id: 'comment-2',
          content: 'Second',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(task.comments, hasLength(1));
      expect(
        () => task.comments.add(
          BackupComment(
            id: 'comment-3',
            content: 'Third',
            createdAt: DateTime.utc(2026, 1, 3),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('BackupArchiveCodec', () {
    const codec = BackupArchiveCodec();

    test('round trips the complete nested archive shape', () {
      final archive = BackupArchive(
        version: '1.0',
        exportedAt: DateTime.utc(2026, 8, 2, 12, 30),
        appVersion: '1.15.4',
        projects: [
          BackupProject(
            id: 'project-1',
            name: 'Work',
            color: '#fff',
            icon: 'folder',
            isInbox: true,
            sortOrder: 2,
            tasks: [
              BackupTask(
                id: 'task-1',
                title: 'Ship',
                description: 'Carefully',
                dueDate: '2026-08-03',
                priority: 3,
                isCompleted: true,
                completedAt: DateTime.utc(2026, 8, 2),
                sortOrder: 4,
                recurrenceRule: 'FREQ=DAILY',
                recurrenceAnchorDate: '2026-08-03',
                subtasks: [BackupTask(id: 'subtask-1', title: 'Test')],
                comments: [
                  BackupComment(
                    id: 'comment-1',
                    content: 'Done',
                    createdAt: DateTime.utc(2026, 8, 2),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(codec.decode(codec.encode(archive)), archive);
    });

    test('writes stable, human-readable JSON and legacy field names', () {
      final encoded = codec.encode(BackupArchive(
        version: '1.0',
        exportedAt: DateTime.utc(2026),
        appVersion: '1.0.0',
        projects: const [],
      ));

      expect(encoded, contains('\n  "version": "1.0"'));
      expect(encoded, contains('"exportedAt": "2026-01-01T00:00:00.000Z"'));
      expect(encoded, contains('"appVersion": "1.0.0"'));
    });

    test('applies backward-compatible defaults for optional collections', () {
      final archive = codec.decode(jsonEncode({
        'version': '1.0',
        'exportedAt': '2026-08-02T00:00:00.000Z',
        'appVersion': '1.0.0',
        'projects': [
          {'id': 'p', 'name': 'Inbox', 'color': 'blue', 'icon': 'inbox'}
        ],
      }));

      expect(archive.projects.single.tasks, isEmpty);
      expect(archive.projects.single.isInbox, isFalse);
      expect(archive.projects.single.sortOrder, 0);
    });

    test('rejects malformed JSON and non-object roots', () {
      expect(() => codec.decode('{'), throwsA(isA<FormatException>()));
      expect(() => codec.decode('[]'), throwsA(isA<FormatException>()));
    });

    test('rejects missing or incorrectly typed required fields', () {
      expect(
        () => codec.decode(jsonEncode({
          'version': '1.0',
          'exportedAt': '2026-08-02T00:00:00.000Z',
          'appVersion': '1.0.0',
          'projects': 'not-a-list',
        })),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => codec.decode(jsonEncode({
          'version': '1.0',
          'exportedAt': 'not-a-date',
          'appVersion': '1.0.0',
          'projects': [],
        })),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported archive versions before import', () {
      expect(
        () => codec.decode(jsonEncode({
          'version': '2.0',
          'exportedAt': '2026-08-02T00:00:00.000Z',
          'appVersion': '2.0.0',
          'projects': [],
        })),
        throwsA(
          isA<UnsupportedBackupVersionException>()
              .having((error) => error.version, 'version', '2.0'),
        ),
      );
    });
  });
}
