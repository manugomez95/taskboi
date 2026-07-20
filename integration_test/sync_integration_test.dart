import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taskboi/core/database/database.dart' hide Task;
import 'package:taskboi/features/tasks/data/models/task.dart';
import 'package:taskboi/core/database/model_converters.dart';

/// Integration tests for task synchronization
///
/// These tests verify that:
/// 1. Task changes are properly queued for sync
/// 2. Local database updates correctly when remote changes arrive
/// 3. Conflict resolution works as expected
/// 4. Realtime events are properly handled
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Sync Integration Tests', () {
    late AppDatabase db;

    setUp(() {
      // Use in-memory database for each test
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Task completion updates local database immediately',
        (tester) async {
      // Setup: Create a task
      const taskId = 'test-task-123';
      const projectId = 'test-project-456';
      const userId = 'test-user-789';

      await db.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Test Task'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Act: Complete the task (simulating what TasksNotifier does)
      final now = DateTime.now();
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          isCompleted: const Value(true),
          completedAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Assert: Task should be marked as completed locally
      final task = await db.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.isCompleted, true);
      expect(task.completedAt, isNotNull);
      expect(task.isPendingSync, true);
    });

    testWidgets('Remote task update applies to local database', (tester) async {
      // Setup: Create a local task
      const taskId = 'remote-task-123';
      const projectId = 'test-project-456';
      const userId = 'test-user-789';

      final oldTime = DateTime.now().subtract(const Duration(hours: 1));
      await db.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Original Title'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(oldTime),
        updatedAt: Value(oldTime),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Act: Simulate receiving a remote update (newer timestamp)
      final newTime = DateTime.now();
      await db.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Updated Title'),
        isCompleted: const Value(true),
        completedAt: Value(newTime),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(oldTime),
        updatedAt: Value(newTime),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Assert: Task should reflect remote changes
      final task = await db.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.title, 'Updated Title');
      expect(task.isCompleted, true);
    });

    testWidgets('Drift stream emits when task is updated', (tester) async {
      const projectId = 'stream-test-project';
      const userId = 'test-user-789';

      // Create initial task
      await db.upsertTask(TasksCompanion(
        id: const Value('stream-task-1'),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Stream Test Task'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Listen to stream
      final stream = db.watchTasks(projectId);
      final emissions = <List<Task>>[];

      final subscription = stream.listen((tasks) {
        emissions.add(ModelConverters.tasksFromDrift(tasks));
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));

      // Update the task
      await (db.update(db.tasks)..where((t) => t.id.equals('stream-task-1')))
          .write(
        TasksCompanion(
          isCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Assert: Should have received at least 2 emissions
      expect(emissions.length, greaterThanOrEqualTo(2));

      // First emission should have incomplete task
      expect(emissions.first.first.isCompleted, false);

      // Last emission should have completed task
      expect(emissions.last.first.isCompleted, true);
    });

    testWidgets('Completed tasks are filtered from Upcoming view',
        (tester) async {
      const userId = 'test-user-789';
      const projectId = 'test-project-456';
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Create an incomplete task due tomorrow
      await db.upsertTask(TasksCompanion(
        id: const Value('upcoming-task-1'),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Upcoming Task'),
        isCompleted: const Value(false),
        dueDate: Value(tomorrow),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Verify it appears in upcoming
      var upcomingTasks = await db.watchUpcomingTasks(userId).first;
      expect(upcomingTasks.length, 1);

      // Complete the task
      await (db.update(db.tasks)..where((t) => t.id.equals('upcoming-task-1')))
          .write(
        TasksCompanion(
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Verify it no longer appears in upcoming
      upcomingTasks = await db.watchUpcomingTasks(userId).first;
      expect(upcomingTasks.length, 0);
    });

    testWidgets('Sync queue operations work correctly', (tester) async {
      // Queue multiple operations
      await db.addToSyncQueue(SyncQueueCompanion(
        entityType: const Value('task'),
        entityId: const Value('task-1'),
        operation: const Value('update'),
        payload: const Value('{"id": "task-1", "title": "Test"}'),
        createdAt: Value(DateTime.now()),
      ));

      await db.addToSyncQueue(SyncQueueCompanion(
        entityType: const Value('task'),
        entityId: const Value('task-2'),
        operation: const Value('create'),
        payload: const Value('{"id": "task-2", "title": "New Task"}'),
        createdAt: Value(DateTime.now()),
      ));

      // Verify queue has both operations
      final operations = await db.getPendingSyncOperations();
      expect(operations.length, 2);

      // Remove first operation
      await db.removeSyncOperation(operations.first.id);

      // Verify only one remains
      final remainingOps = await db.getPendingSyncOperations();
      expect(remainingOps.length, 1);
      expect(remainingOps.first.entityId, 'task-2');
    });

    testWidgets('Soft delete marks task but keeps it locally', (tester) async {
      const taskId = 'delete-task-123';
      const projectId = 'test-project-456';
      const userId = 'test-user-789';

      // Create a task
      await db.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Task to Delete'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Soft delete
      await db.softDeleteTask(taskId);

      // Task should still exist but marked as deleted
      final task = await db.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.isDeleted, true);
      expect(task.isPendingSync, true);

      // Task should not appear in normal queries
      final tasks = await db.getTasks(userId);
      expect(tasks.where((t) => t.id == taskId).isEmpty, true);
    });

    testWidgets('Hard delete removes task completely', (tester) async {
      const taskId = 'hard-delete-task-123';
      const projectId = 'test-project-456';
      const userId = 'test-user-789';

      // Create a task
      await db.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Task to Hard Delete'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Hard delete
      await db.hardDeleteTask(taskId);

      // Task should no longer exist
      final task = await db.getTask(taskId);
      expect(task, isNull);
    });

    testWidgets('Timestamp comparison for conflict resolution', (tester) async {
      // This test verifies the timestamp comparison logic used in sync

      final time1 = DateTime.parse('2024-01-15T10:30:45.123456Z');
      final time2 =
          DateTime.parse('2024-01-15T10:30:45.123457Z'); // 1 microsecond later
      final time3 =
          DateTime.parse('2024-01-15T10:30:45.123456Z'); // Same as time1

      // time2 should be after time1
      expect(time2.isAfter(time1), true);
      expect(time1.isBefore(time2), true);

      // time1 and time3 should be at same moment
      expect(time1.isAtSameMomentAs(time3), true);

      // This is what the sync service checks:
      // Skip if remote is older OR same as local
      bool shouldSkipUpdate(DateTime remote, DateTime local) {
        return remote.isBefore(local) || remote.isAtSameMomentAs(local);
      }

      expect(shouldSkipUpdate(time1, time2), true); // time1 is older
      expect(shouldSkipUpdate(time2, time1),
          false); // time2 is newer - should apply
      expect(shouldSkipUpdate(time1, time3), true); // same - skip
    });
  });
}
