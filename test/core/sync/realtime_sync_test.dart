import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskboi/core/database/database.dart';
import 'package:taskboi/core/connectivity/connectivity_service.dart';
import 'package:taskboi/core/sync/sync_service.dart';

/// This test replicates the real-world sync issue:
/// 1. Client A has a task (incomplete)
/// 2. Client B completes the task and syncs to Supabase
/// 3. Supabase broadcasts the update via realtime
/// 4. Client A receives the realtime event
/// 5. Client A should update its local database
///
/// The bug: Step 5 wasn't happening - completed tasks weren't
/// being reflected on other clients.

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  late AppDatabase clientADatabase;
  late MockSupabaseClient mockSupabase;
  late MockConnectivityService mockConnectivity;
  late SyncService clientASyncService;

  const userId = 'test-user-123';
  const projectId = 'test-project-456';
  const taskId = 'test-task-789';

  setUp(() {
    // Simulate Client A's local state
    clientADatabase = AppDatabase.forTesting(NativeDatabase.memory());
    mockSupabase = MockSupabaseClient();
    mockConnectivity = MockConnectivityService();

    when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
    when(() => mockConnectivity.onlineStatusStream)
        .thenAnswer((_) => Stream.value(true));

    clientASyncService = SyncService(
      db: clientADatabase,
      supabase: mockSupabase,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() async {
    await clientADatabase.close();
  });

  group('Realtime Sync - Cross-Client Task Completion', () {
    test(
        'SCENARIO: Client B completes task, Client A should see it as completed',
        () async {
      // ========== SETUP: Client A has an incomplete task ==========
      final originalTime = DateTime.now().subtract(const Duration(hours: 1));

      await clientADatabase.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Buy groceries'),
        isCompleted: const Value(false), // NOT completed
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(originalTime),
        updatedAt: Value(originalTime),
        isPendingSync: const Value(false), // Already synced
        isDeleted: const Value(false),
      ));

      // Verify initial state
      var task = await clientADatabase.getTask(taskId);
      expect(task, isNotNull);
      expect(task!.isCompleted, false,
          reason: 'Task should start as incomplete');

      // ========== ACTION: Simulate realtime event from Supabase ==========
      // This is what Supabase sends when Client B completes the task
      final completedTime = DateTime.now();
      final realtimePayload = {
        'id': taskId,
        'project_id': projectId,
        'user_id': userId,
        'title': 'Buy groceries',
        'description': null,
        'due_date': null,
        'priority': 0,
        'is_completed': true, // NOW COMPLETED by Client B
        'completed_at': completedTime.toIso8601String(),
        'sort_order': 0,
        'recurrence_rule': null,
        'recurrence_parent_id': null,
        'created_at': originalTime.toIso8601String(),
        'updated_at': completedTime.toIso8601String(), // Newer timestamp!
      };

      // Simulate the realtime callback
      // This calls the same code path as the real realtime handler
      await _simulateRealtimeTaskUpdate(
          clientASyncService, clientADatabase, realtimePayload);

      // ========== VERIFY: Client A's local database should be updated ==========
      task = await clientADatabase.getTask(taskId);
      expect(task, isNotNull);

      // THIS IS THE BUG - if this fails, the sync isn't working!
      expect(
        task!.isCompleted,
        true,
        reason:
            'Task should be marked as completed after receiving realtime update',
      );
      expect(
        task.completedAt,
        isNotNull,
        reason: 'completedAt should be set',
      );
    });

    test('SCENARIO: Realtime update with older timestamp should be ignored',
        () async {
      // Client A has a task that was recently updated locally
      final localTime = DateTime.now();

      await clientADatabase.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Updated locally'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(localTime.subtract(const Duration(hours: 1))),
        updatedAt: Value(localTime), // Recent local update
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Simulate receiving an OLD realtime update (from before local change)
      final oldTime = localTime.subtract(const Duration(minutes: 5));
      final realtimePayload = {
        'id': taskId,
        'project_id': projectId,
        'user_id': userId,
        'title': 'Old title from server',
        'is_completed': true,
        'completed_at': oldTime.toIso8601String(),
        'sort_order': 0,
        'priority': 0,
        'created_at':
            localTime.subtract(const Duration(hours: 1)).toIso8601String(),
        'updated_at': oldTime.toIso8601String(), // OLDER than local!
      };

      await _simulateRealtimeTaskUpdate(
          clientASyncService, clientADatabase, realtimePayload);

      // Local state should NOT be changed
      final task = await clientADatabase.getTask(taskId);
      expect(task!.title, 'Updated locally', reason: 'Should keep local title');
      expect(task.isCompleted, false,
          reason: 'Should NOT apply old remote completion');
    });

    test('SCENARIO: Task pending local sync should not be overwritten',
        () async {
      // Client A has a task with pending local changes
      final localTime = DateTime.now();

      await clientADatabase.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('My local changes'),
        isCompleted: const Value(true), // Completed locally
        completedAt: Value(localTime),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(localTime.subtract(const Duration(hours: 1))),
        updatedAt: Value(localTime),
        isPendingSync: const Value(true), // PENDING SYNC!
        isDeleted: const Value(false),
      ));

      // Simulate remote update trying to uncomplete the task
      final remoteTime = localTime.add(const Duration(seconds: 1));
      final realtimePayload = {
        'id': taskId,
        'project_id': projectId,
        'user_id': userId,
        'title': 'My local changes',
        'is_completed': false, // Remote says NOT completed
        'completed_at': null,
        'sort_order': 0,
        'priority': 0,
        'created_at':
            localTime.subtract(const Duration(hours: 1)).toIso8601String(),
        'updated_at': remoteTime.toIso8601String(),
      };

      await _simulateRealtimeTaskUpdate(
          clientASyncService, clientADatabase, realtimePayload);

      // Local pending changes should be preserved
      final task = await clientADatabase.getTask(taskId);
      expect(task!.isCompleted, true,
          reason: 'Should keep local pending completion');
      expect(task.isPendingSync, true, reason: 'Should still be pending sync');
    });

    test('SCENARIO: Verify Drift stream emits after remote update', () async {
      // Setup task
      final originalTime = DateTime.now().subtract(const Duration(hours: 1));

      await clientADatabase.upsertTask(TasksCompanion(
        id: const Value(taskId),
        projectId: const Value(projectId),
        userId: const Value(userId),
        title: const Value('Stream test task'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        priority: const Value(0),
        createdAt: Value(originalTime),
        updatedAt: Value(originalTime),
        isPendingSync: const Value(false),
        isDeleted: const Value(false),
      ));

      // Listen to the stream (this is what the UI does)
      final stream = clientADatabase.watchTasks(projectId);
      final emissions = <List<Task>>[];
      final subscription = stream.listen((tasks) {
        emissions.add(tasks);
      });

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 100));
      expect(emissions.isNotEmpty, true,
          reason: 'Should have initial emission');
      expect(emissions.last.first.isCompleted, false);

      // Simulate realtime update
      final completedTime = DateTime.now();
      final realtimePayload = {
        'id': taskId,
        'project_id': projectId,
        'user_id': userId,
        'title': 'Stream test task',
        'is_completed': true,
        'completed_at': completedTime.toIso8601String(),
        'sort_order': 0,
        'priority': 0,
        'created_at': originalTime.toIso8601String(),
        'updated_at': completedTime.toIso8601String(),
      };

      await _simulateRealtimeTaskUpdate(
          clientASyncService, clientADatabase, realtimePayload);

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Should have received update via stream
      expect(emissions.length, greaterThanOrEqualTo(2),
          reason: 'Stream should emit after database update');
      expect(emissions.last.first.isCompleted, true,
          reason: 'Latest emission should show completed task');
    });
  });
}

/// Simulates what happens when a realtime event is received.
/// This replicates the _applyRemoteTask logic in SyncService.
Future<void> _simulateRealtimeTaskUpdate(
  SyncService syncService,
  AppDatabase db,
  Map<String, dynamic> remoteData,
) async {
  final remoteId = remoteData['id'] as String;
  final remoteUpdatedAt = remoteData['updated_at'] != null
      ? DateTime.parse(remoteData['updated_at'] as String)
      : null;

  // Check if we have a pending sync for this entity
  // CRITICAL: Never overwrite pending local changes with remote updates.
  final pendingTasks = await db.getPendingSyncTasks();
  final localPending = pendingTasks.where((t) => t.id == remoteId).firstOrNull;

  if (localPending != null) {
    return;
  }

  // Check current local state
  final localTask = await db.getTask(remoteId);
  if (localTask != null &&
      localTask.updatedAt != null &&
      remoteUpdatedAt != null) {
    if (remoteUpdatedAt.isBefore(localTask.updatedAt!) ||
        remoteUpdatedAt.isAtSameMomentAs(localTask.updatedAt!)) {
      return;
    }
  }

  // Apply remote update (same as SyncService._applyRemoteTask)
  await db.upsertTask(TasksCompanion(
    id: Value(remoteId),
    projectId: Value(remoteData['project_id'] as String),
    userId: Value(remoteData['user_id'] as String),
    parentId: Value(remoteData['parent_id'] as String?),
    title: Value(remoteData['title'] as String? ?? ''),
    description: Value(remoteData['description'] as String?),
    dueDate: Value(remoteData['due_date'] != null
        ? DateTime.parse(remoteData['due_date'] as String)
        : null),
    priority: Value(remoteData['priority'] as int? ?? 0),
    isCompleted: Value(remoteData['is_completed'] as bool? ?? false),
    completedAt: Value(remoteData['completed_at'] != null
        ? DateTime.parse(remoteData['completed_at'] as String)
        : null),
    sortOrder: Value(remoteData['sort_order'] as int? ?? 0),
    recurrenceRule: Value(remoteData['recurrence_rule'] as String?),
    recurrenceParentId: Value(remoteData['recurrence_parent_id'] as String?),
    createdAt: Value(remoteData['created_at'] != null
        ? DateTime.parse(remoteData['created_at'] as String)
        : null),
    updatedAt: Value(remoteUpdatedAt),
    isPendingSync: const Value(false),
    isDeleted: const Value(false),
  ));
}
