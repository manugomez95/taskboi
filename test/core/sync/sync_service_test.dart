import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskboi/core/database/database.dart';
import 'package:taskboi/core/connectivity/connectivity_service.dart';
import 'package:taskboi/core/sync/sync_service.dart';
import 'package:taskboi/core/sync/sync_operation.dart';
import 'package:taskboi/core/sync/sync_provider.dart';
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/features/tasks/providers/tasks_provider.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockSyncService extends Mock implements SyncService {}

class MockRef extends Mock implements Ref<Object?> {}

void main() {
  late AppDatabase db;
  late MockSupabaseClient mockSupabase;
  late MockConnectivityService mockConnectivity;
  late SyncService syncService;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    // Create in-memory database for testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockSupabase = MockSupabaseClient();
    mockConnectivity = MockConnectivityService();

    // Default connectivity to online
    when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
    when(() => mockConnectivity.onlineStatusStream)
        .thenAnswer((_) => Stream.value(true));

    syncService = SyncService(
      db: db,
      supabase: mockSupabase,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncService', () {
    group('Task Sync Operations', () {
      test('should queue task update operation', () async {
        const taskId = 'test-task-id';
        final payload = {
          'id': taskId,
          'is_completed': true,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await syncService.queueUpdate(
          SyncEntityType.task,
          taskId,
          payload,
        );

        final operations = await db.getPendingSyncOperations();
        expect(operations.length, 1);
        expect(operations.first.entityId, taskId);
        expect(operations.first.operation, 'update');
      });

      test('should replace existing update for same entity', () async {
        const taskId = 'test-task-id';

        // Queue first update
        await syncService.queueUpdate(
          SyncEntityType.task,
          taskId,
          {'id': taskId, 'title': 'First'},
        );

        // Queue second update for same task
        await syncService.queueUpdate(
          SyncEntityType.task,
          taskId,
          {'id': taskId, 'title': 'Second'},
        );

        final operations = await db.getPendingSyncOperations();
        expect(operations.length, 1); // Should only have one operation
        expect(operations.first.payload, contains('Second'));
      });

      test('should queue delete operation', () async {
        const taskId = 'test-task-id';

        await syncService.queueDelete(SyncEntityType.task, taskId);

        final operations = await db.getPendingSyncOperations();
        expect(operations.length, 1);
        expect(operations.first.operation, 'delete');
      });
    });

    group('Conflict Resolution', () {
      test('should preserve local pending task on remote update', () async {
        // Insert a local task marked as pending sync
        final localTime = DateTime.now();
        await db.upsertTask(TasksCompanion(
          id: const Value('test-task-id'),
          projectId: const Value('test-project-id'),
          userId: const Value('test-user-id'),
          title: const Value('Local Title'),
          isCompleted: const Value(true),
          updatedAt: Value(localTime),
          isPendingSync: const Value(true), // Pending sync!
          isDeleted: const Value(false),
        ));

        final pendingTasks = await db.getPendingSyncTasks();
        expect(pendingTasks.length, 1);
        expect(pendingTasks.first.isPendingSync, true);
      });
    });

    group('Database Operations', () {
      test('should create task in local database', () async {
        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Test Task'),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(true),
          isDeleted: Value(false),
        ));

        final task = await db.getTask('task-1');
        expect(task, isNotNull);
        expect(task!.title, 'Test Task');
        expect(task.isCompleted, false);
      });

      test('should update task completion status', () async {
        // Create task
        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Test Task'),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(false),
          isDeleted: Value(false),
        ));

        // Update to completed
        await db.upsertTask(TasksCompanion(
          id: const Value('task-1'),
          projectId: const Value('project-1'),
          userId: const Value('user-1'),
          title: const Value('Test Task'),
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
          sortOrder: const Value(0),
          priority: const Value(0),
          isPendingSync: const Value(true),
          isDeleted: const Value(false),
        ));

        final task = await db.getTask('task-1');
        expect(task!.isCompleted, true);
        expect(task.completedAt, isNotNull);
      });

      test('should watch tasks stream for changes', () async {
        const projectId = 'project-1';

        // Watch the stream
        final stream = db.watchTasks(projectId);

        // Create a task
        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Test Task'),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(false),
          isDeleted: Value(false),
        ));

        // Verify stream emits
        await expectLater(
          stream,
          emits(isA<List>().having((l) => l.length, 'length', 1)),
        );
      });

      test('should filter out deleted tasks from watch', () async {
        const projectId = 'project-1';

        // Create a deleted task
        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Deleted Task'),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(false),
          isDeleted: Value(true), // Deleted!
        ));

        final stream = db.watchTasks(projectId);

        // Should be empty (deleted tasks filtered out)
        await expectLater(
          stream,
          emits(isA<List>().having((l) => l.isEmpty, 'isEmpty', true)),
        );
      });

      test('should enforce one active recurring occurrence per series date',
          () async {
        final occurrenceDate = DateTime(2026, 6, 7);
        final firstOccurrence = TasksCompanion(
          id: const Value('task-1'),
          projectId: const Value('project-1'),
          userId: const Value('user-1'),
          title: const Value('Daily task'),
          dueDate: Value(occurrenceDate),
          recurrenceRule: const Value(RecurrenceRule.daily),
          recurrenceParentId: const Value('series-1'),
          recurrenceAnchorDate: Value(occurrenceDate),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          priority: const Value(0),
          isPendingSync: const Value(false),
          isDeleted: const Value(false),
        );
        final duplicateOccurrence = firstOccurrence.copyWith(
          id: const Value('task-2'),
        );

        await db.upsertTask(firstOccurrence);

        await expectLater(
          db.upsertTask(duplicateOccurrence),
          throwsA(anything),
        );
      });

      test('task notifier should clear nullable task fields', () async {
        final mockSyncService = MockSyncService();
        when(() => mockSyncService.queueUpdate(
              SyncEntityType.task,
              'task-1',
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.processPendingOperations())
            .thenAnswer((_) async {});

        await db.upsertTask(TasksCompanion(
          id: const Value('task-1'),
          projectId: const Value('project-1'),
          userId: const Value('user-1'),
          title: const Value('Test Task'),
          description: const Value('Existing description'),
          dueDate: Value(DateTime(2026, 1, 15)),
          recurrenceRule: const Value(RecurrenceRule.daily),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          priority: const Value(0),
          isPendingSync: const Value(false),
          isDeleted: const Value(false),
        ));

        final notifier = TasksNotifier(
          db,
          mockSyncService,
          'user-1',
          MockRef(),
        );

        await notifier.updateTask(
          id: 'task-1',
          description: null,
          updateDescription: true,
          dueDate: null,
          updateDueDate: true,
          recurrenceRule: null,
          updateRecurrenceRule: true,
        );

        final task = await db.getTask('task-1');
        expect(task!.description, isNull);
        expect(task.dueDate, isNull);
        expect(task.recurrenceRule, isNull);
        expect(task.isPendingSync, true);

        final payload = verify(() => mockSyncService.queueUpdate(
              SyncEntityType.task,
              'task-1',
              captureAny(),
            )).captured.single as Map<String, dynamic>;
        expect(payload, containsPair('description', null));
        expect(payload, containsPair('due_date', null));
        expect(payload, containsPair('recurrence_rule', null));
      });

      test('completing a recurring task twice creates one next occurrence',
          () async {
        final mockSyncService = MockSyncService();
        when(() => mockSyncService.queueUpdate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.queueCreate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.processPendingOperations())
            .thenAnswer((_) async {});

        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        await db.upsertTask(TasksCompanion(
          id: const Value('task-1'),
          projectId: const Value('project-1'),
          userId: const Value('user-1'),
          title: const Value('Daily task'),
          dueDate: Value(todayOnly),
          recurrenceRule: const Value(RecurrenceRule.daily),
          recurrenceAnchorDate: Value(todayOnly),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          priority: const Value(0),
          isPendingSync: const Value(false),
          isDeleted: const Value(false),
        ));

        final notifier = TasksNotifier(
          db,
          mockSyncService,
          'user-1',
          MockRef(),
        );

        await Future.wait([
          notifier.completeTask('task-1'),
          notifier.completeTask('task-1'),
        ]);

        final tasks = await db.getTasks('user-1');
        final nextOccurrences = tasks.where(
          (task) =>
              task.id != 'task-1' &&
              task.recurrenceParentId == 'task-1' &&
              task.recurrenceRule == RecurrenceRule.daily,
        );

        expect(tasks.length, 2);
        expect(nextOccurrences.length, 1);
      });

      test('complete undo complete reuses existing recurring occurrence',
          () async {
        final mockSyncService = MockSyncService();
        when(() => mockSyncService.queueUpdate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.queueCreate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.processPendingOperations())
            .thenAnswer((_) async {});
        when(() => mockSyncService.queueDelete(
              SyncEntityType.task,
              any(),
            )).thenAnswer((_) async {});

        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        await db.upsertTask(TasksCompanion(
          id: const Value('task-1'),
          projectId: const Value('project-1'),
          userId: const Value('user-1'),
          title: const Value('Daily task'),
          dueDate: Value(todayOnly),
          recurrenceRule: const Value(RecurrenceRule.daily),
          recurrenceAnchorDate: Value(todayOnly),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          priority: const Value(0),
          isPendingSync: const Value(false),
          isDeleted: const Value(false),
        ));

        final notifier = TasksNotifier(
          db,
          mockSyncService,
          'user-1',
          MockRef(),
        );

        await notifier.completeTask('task-1');
        await notifier.uncompleteTask('task-1');
        await notifier.completeTask('task-1');

        final tasks = await db.getTasks('user-1');
        final nextOccurrences = tasks.where(
          (task) =>
              task.id != 'task-1' &&
              task.recurrenceParentId == 'task-1' &&
              task.recurrenceRule == RecurrenceRule.daily,
        );

        expect(tasks.length, 2);
        expect(nextOccurrences.length, 1);
      });

      test(
          'uncompleting a recurring task removes the occurrence its completion '
          'spawned', () async {
        final mockSyncService = MockSyncService();
        when(() => mockSyncService.queueUpdate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.queueCreate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.queueDelete(
              SyncEntityType.task,
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.processPendingOperations())
            .thenAnswer((_) async {});

        // A daily recurring template with no due date (e.g. "take fish oil") —
        // the shape that previously produced a duplicate in the Today view:
        // the due-null template plus the dated occurrence spawned on completion.
        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Daily task'),
          recurrenceRule: Value(RecurrenceRule.daily),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(false),
          isDeleted: Value(false),
        ));

        final notifier = TasksNotifier(
          db,
          mockSyncService,
          'user-1',
          MockRef(),
        );

        await notifier.completeTask('task-1');

        // Completion leaves exactly one active instance: the spawned occurrence.
        var activeInstances = (await db.getTasks('user-1')).where(
          (task) =>
              !task.isCompleted &&
              (task.id == 'task-1' || task.recurrenceParentId == 'task-1'),
        );
        expect(activeInstances.length, 1);
        expect(activeInstances.single.recurrenceParentId, 'task-1');

        await notifier.uncompleteTask('task-1');

        // Re-opening the task must remove the spawned occurrence, leaving a
        // single active instance (the reopened template) rather than two.
        activeInstances = (await db.getTasks('user-1')).where(
          (task) =>
              !task.isCompleted &&
              (task.id == 'task-1' || task.recurrenceParentId == 'task-1'),
        );
        expect(activeInstances.length, 1);
        expect(activeInstances.single.id, 'task-1');

        verify(() => mockSyncService.queueDelete(SyncEntityType.task, any()))
            .called(1);
      });
    });

    group('Offline Support', () {
      test('should skip processing when offline', () async {
        when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);

        // Queue an operation
        await syncService.queueUpdate(
          SyncEntityType.task,
          'task-1',
          {'id': 'task-1', 'title': 'Test'},
        );

        // Try to process - should skip
        await syncService.processPendingOperations();

        // Operation should still be in queue
        final operations = await db.getPendingSyncOperations();
        expect(operations.length, 1);
      });

      test(
          'exhausted create remains recoverable across full sync and local edits',
          () async {
        var createShouldFail = true;
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          accessToken: () async => 'test-token',
          httpClient: MockClient((request) async {
            final isTaskCreate = request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/tasks');
            if (isTaskCreate && createShouldFail) {
              return http.Response(
                jsonEncode({
                  'code': 'TEMPORARY_FAILURE',
                  'message': 'Temporary sync failure',
                }),
                503,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (isTaskCreate) {
              return http.Response(
                jsonEncode([
                  {'id': 'task-1'}
                ]),
                201,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.method == 'GET') {
              return http.Response(
                '[]',
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            return http.Response('Not found', 404, request: request);
          }),
        );
        final recoveringSyncService = SyncService(
          db: db,
          supabase: client,
          connectivity: mockConnectivity,
        );

        addTearDown(client.dispose);

        await db.upsertTask(const TasksCompanion(
          id: Value('task-1'),
          projectId: Value('project-1'),
          userId: Value('user-1'),
          title: Value('Original title'),
          isCompleted: Value(false),
          sortOrder: Value(0),
          priority: Value(0),
          isPendingSync: Value(true),
          isDeleted: Value(false),
        ));
        await db.addToSyncQueue(SyncQueueCompanion(
          entityType: const Value('task'),
          entityId: const Value('task-1'),
          operation: const Value('create'),
          payload: Value(jsonEncode({
            'id': 'task-1',
            'project_id': 'project-1',
            'user_id': 'user-1',
            'title': 'Original title',
          })),
          createdAt: Value(DateTime.now()),
          retryCount: const Value(SyncOperation.maxRetries),
        ));

        // A failed attempt after the retry budget must keep the CREATE and its
        // pending flag, so an authoritative full sync cannot delete the task.
        await recoveringSyncService.processPendingOperations();
        var operations = await db.getPendingSyncOperations();
        expect(operations, hasLength(1));
        expect(operations.single.operation, 'create');
        expect(operations.single.retryCount, SyncOperation.maxRetries);

        final container = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ]);
        addTearDown(container.dispose);
        final queueStatus =
            await container.read(syncQueueStatusProvider.future);
        expect(queueStatus.pendingCount, 1);
        expect(queueStatus.hasExhaustedOperations, isTrue);

        await recoveringSyncService.performFullSync('user-1');
        expect(await db.getTask('task-1'), isNotNull);

        // An edit must merge into the durable CREATE, never turn into an
        // UPDATE for a row that does not exist remotely.
        await recoveringSyncService.queueUpdate(
          SyncEntityType.task,
          'task-1',
          {'title': 'Edited while pending'},
        );
        operations = await db.getPendingSyncOperations();
        expect(operations, hasLength(1));
        expect(operations.single.operation, 'create');
        expect(
          jsonDecode(operations.single.payload),
          containsPair('title', 'Edited while pending'),
        );

        // Once the backend recovers, the same CREATE succeeds and both queue
        // and pending flag are cleared normally.
        createShouldFail = false;
        await recoveringSyncService.processPendingOperations();
        expect(await db.getPendingSyncOperations(), isEmpty);
        expect((await db.getTask('task-1'))!.isPendingSync, isFalse);
      });
    });

    group('Optimistic task mutations', () {
      test('createTask does not wait for remote queue processing', () async {
        final mockSyncService = MockSyncService();
        final remoteProcessing = Completer<void>();
        when(() => mockSyncService.queueCreate(
              SyncEntityType.task,
              any(),
              any(),
            )).thenAnswer((_) async {});
        when(() => mockSyncService.processPendingOperations())
            .thenAnswer((_) => remoteProcessing.future);

        final notifier = TasksNotifier(
          db,
          mockSyncService,
          'user-1',
          MockRef(),
        );

        final task = await notifier
            .createTask(
              id: 'task-1',
              projectId: 'project-1',
              title: 'Optimistic task',
            )
            .timeout(const Duration(seconds: 1));

        expect(task, isNotNull);
        expect(await db.getTask('task-1'), isNotNull);
        remoteProcessing.complete();
      });
    });

    group('Timestamp Handling', () {
      test('should correctly compare timestamps for sync', () {
        final time1 = DateTime.parse('2024-01-15T10:30:45.123456Z');
        final time2 = DateTime.parse('2024-01-15T10:30:45.123457Z');
        final time3 = DateTime.parse('2024-01-15T10:30:45.123456Z');

        // time2 should be after time1
        expect(time2.isAfter(time1), true);
        expect(time1.isBefore(time2), true);

        // time1 and time3 should be at same moment
        expect(time1.isAtSameMomentAs(time3), true);
      });

      test('should handle ISO8601 timestamp parsing', () {
        // Test various timestamp formats that might come from Supabase
        final formats = [
          '2024-01-15T10:30:45.123456Z',
          '2024-01-15T10:30:45.123Z',
          '2024-01-15T10:30:45Z',
          '2024-01-15T10:30:45+00:00',
        ];

        for (final format in formats) {
          final parsed = DateTime.parse(format);
          expect(parsed, isNotNull);
          expect(parsed.year, 2024);
          expect(parsed.month, 1);
          expect(parsed.day, 15);
        }
      });
    });
  });
}
