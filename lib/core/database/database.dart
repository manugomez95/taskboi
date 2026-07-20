import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Projects table - mirrors Supabase projects table with sync tracking
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#6B7280'))();
  TextColumn get icon => text().nullable()();
  BoolColumn get isInbox =>
      boolean().withDefault(const Constant(false)).named('is_inbox')();
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0)).named('sort_order')();
  TextColumn get defaultAssignee =>
      text().withDefault(const Constant('manuel')).named('default_assignee')();
  TextColumn get agentWebhookUrl =>
      text().withDefault(const Constant('')).named('agent_webhook_url')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  // Encryption fields
  TextColumn get nameEncrypted => text().nullable().named('name_encrypted')();
  IntColumn get encryptionVersion =>
      integer().withDefault(const Constant(0)).named('encryption_version')();

  // Local-only sync tracking fields
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false)).named('is_pending_sync')();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false)).named('is_deleted')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tasks table - mirrors Supabase tasks table with sync tracking
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().named('project_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get parentId => text().nullable().named('parent_id')();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable().named('due_date')();
  TextColumn get dueTime => text().nullable().named('due_time')();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false)).named('is_completed')();
  DateTimeColumn get completedAt =>
      dateTime().nullable().named('completed_at')();
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0)).named('sort_order')();
  TextColumn get recurrenceRule => text().nullable().named('recurrence_rule')();
  TextColumn get recurrenceParentId =>
      text().nullable().named('recurrence_parent_id')();
  DateTimeColumn get recurrenceAnchorDate =>
      dateTime().nullable().named('recurrence_anchor_date')();
  TextColumn get assignedTo =>
      text().withDefault(const Constant('manuel')).named('assigned_to')();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  // Encryption fields
  TextColumn get titleEncrypted => text().nullable().named('title_encrypted')();
  TextColumn get descriptionEncrypted =>
      text().nullable().named('description_encrypted')();
  IntColumn get encryptionVersion =>
      integer().withDefault(const Constant(0)).named('encryption_version')();

  // Local-only sync tracking fields
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false)).named('is_pending_sync')();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false)).named('is_deleted')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table - tracks pending operations for offline sync
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType =>
      text().named('entity_type')(); // 'project' or 'task'
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON-encoded data
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0)).named('retry_count')();
  TextColumn get lastError => text().nullable().named('last_error')();
}

/// Sync metadata table - tracks last sync timestamps
class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {key};
}

/// Comments table - mirrors Supabase comments table with sync tracking
class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().named('task_id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().nullable().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  // Image attachments (JSON-encoded list of storage URLs)
  TextColumn get images => text().withDefault(const Constant('[]'))();

  // Encryption fields
  TextColumn get contentEncrypted =>
      text().nullable().named('content_encrypted')();
  IntColumn get encryptionVersion =>
      integer().withDefault(const Constant(0)).named('encryption_version')();

  // Local-only sync tracking fields
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false)).named('is_pending_sync')();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false)).named('is_deleted')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local encryption metadata cache
class LocalEncryptionMetadata extends Table {
  TextColumn get userId => text().named('user_id')();
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(false)).named('is_enabled')();
  IntColumn get keyVersion =>
      integer().withDefault(const Constant(1)).named('key_version')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(tables: [
  Projects,
  Tasks,
  SyncQueue,
  SyncMetadata,
  Comments,
  LocalEncryptionMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createRecurringOccurrenceIndex();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add comments table
          await m.createTable(comments);
        }
        if (from < 3) {
          // Add encryption columns to existing tables
          await customStatement(
            'ALTER TABLE projects ADD COLUMN name_encrypted TEXT',
          );
          await customStatement(
            'ALTER TABLE projects ADD COLUMN encryption_version INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN title_encrypted TEXT',
          );
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN description_encrypted TEXT',
          );
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN encryption_version INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE comments ADD COLUMN content_encrypted TEXT',
          );
          await customStatement(
            'ALTER TABLE comments ADD COLUMN encryption_version INTEGER NOT NULL DEFAULT 0',
          );
          // Add local encryption metadata table
          await m.createTable(localEncryptionMetadata);
        }
        if (from < 4) {
          // Add recurrence anchor date for recurring tasks
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN recurrence_anchor_date INTEGER',
          );
        }
        if (from < 5) {
          await _dedupeRecurringOccurrences();
          await _createRecurringOccurrenceIndex();
        }
        if (from < 6) {
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN assigned_to TEXT NOT NULL DEFAULT \'manuel\'',
          );
        }
        if (from < 7) {
          await customStatement(
            'ALTER TABLE projects ADD COLUMN default_assignee TEXT NOT NULL DEFAULT \'manuel\'',
          );
        }
        if (from < 8) {
          // Add images column to comments for photo attachments
          await customStatement(
            'ALTER TABLE comments ADD COLUMN images TEXT NOT NULL DEFAULT \'[]\'',
          );
          await customStatement(
            'ALTER TABLE tasks ADD COLUMN due_time TEXT',
          );
        }
        if (from < 9) {
          // Add agent_webhook_url column to projects for per-project webhook override
          await customStatement(
            'ALTER TABLE projects ADD COLUMN agent_webhook_url TEXT NOT NULL DEFAULT \'\'',
          );
        }
      },
    );
  }

  Future<void> _dedupeRecurringOccurrences() async {
    await customStatement('''
DELETE FROM tasks
WHERE id IN (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY user_id, recurrence_parent_id, recurrence_anchor_date
        ORDER BY created_at ASC, updated_at ASC, id ASC
      ) AS rn
    FROM tasks
    WHERE recurrence_rule IS NOT NULL
      AND recurrence_parent_id IS NOT NULL
      AND recurrence_anchor_date IS NOT NULL
      AND is_completed = 0
      AND is_deleted = 0
  )
  WHERE rn > 1
)
''');
  }

  Future<void> _createRecurringOccurrenceIndex() async {
    await customStatement('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_recurring_occurrence_unique
ON tasks(user_id, recurrence_parent_id, recurrence_anchor_date)
WHERE recurrence_rule IS NOT NULL
  AND recurrence_parent_id IS NOT NULL
  AND recurrence_anchor_date IS NOT NULL
  AND is_completed = 0
  AND is_deleted = 0
''');
  }

  // ==================== Projects ====================

  /// Watch all non-deleted projects for a user
  Stream<List<Project>> watchProjects(String userId) {
    return (select(projects)
          ..where((p) => p.userId.equals(userId) & p.isDeleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm(expression: p.isInbox, mode: OrderingMode.desc),
            (p) => OrderingTerm(expression: p.sortOrder),
            (p) => OrderingTerm(expression: p.createdAt),
          ]))
        .watch();
  }

  /// Get all non-deleted projects for a user
  Future<List<Project>> getProjects(String userId) {
    return (select(projects)
          ..where((p) => p.userId.equals(userId) & p.isDeleted.equals(false))
          ..orderBy([
            (p) => OrderingTerm(expression: p.isInbox, mode: OrderingMode.desc),
            (p) => OrderingTerm(expression: p.sortOrder),
            (p) => OrderingTerm(expression: p.createdAt),
          ]))
        .get();
  }

  /// Get the inbox project for a user
  Future<Project?> getInboxProject(String userId) {
    return (select(projects)
          ..where((p) =>
              p.userId.equals(userId) &
              p.isInbox.equals(true) &
              p.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Insert or update a project
  Future<void> upsertProject(ProjectsCompanion project) {
    return into(projects).insertOnConflictUpdate(project);
  }

  /// Mark a project as deleted (soft delete)
  Future<void> softDeleteProject(String id) {
    return (update(projects)..where((p) => p.id.equals(id))).write(
      ProjectsCompanion(
        isDeleted: const Value(true),
        isPendingSync: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently delete a project
  Future<void> hardDeleteProject(String id) {
    return (delete(projects)..where((p) => p.id.equals(id))).go();
  }

  /// Update project sort orders
  Future<void> updateProjectSortOrders(List<Project> orderedProjects) async {
    await batch((batch) {
      for (int i = 0; i < orderedProjects.length; i++) {
        batch.update(
          projects,
          ProjectsCompanion(
            sortOrder: Value(i),
            isPendingSync: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
          where: (p) => p.id.equals(orderedProjects[i].id),
        );
      }
    });
  }

  /// Get projects pending sync
  Future<List<Project>> getPendingSyncProjects() {
    return (select(projects)..where((p) => p.isPendingSync.equals(true))).get();
  }

  /// Clear pending sync flag for a project
  Future<void> clearProjectPendingSync(String id) {
    return (update(projects)..where((p) => p.id.equals(id))).write(
      const ProjectsCompanion(isPendingSync: Value(false)),
    );
  }

  // ==================== Tasks ====================

  /// Watch all non-deleted tasks for a project
  Stream<List<Task>> watchTasks(String projectId) {
    return (select(tasks)
          ..where(
              (t) => t.projectId.equals(projectId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  /// Watch all non-deleted tasks for a user (all projects)
  Stream<List<Task>> watchAllTasks(String userId) {
    return (select(tasks)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  /// Watch tasks due today (including recurring tasks with no due date)
  /// Includes completed tasks due today so "Show completed" toggle works
  Stream<List<Task>> watchTasksDueToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.parentId.isNull() &
              // Due today (both complete and incomplete)
              // OR overdue (incomplete only)
              // OR recurring with no due date (incomplete only)
              ((t.dueDate.isBiggerOrEqualValue(startOfDay) &
                      t.dueDate.isSmallerThanValue(endOfDay)) |
                  (t.dueDate.isSmallerThanValue(startOfDay) &
                      t.isCompleted.equals(false)) |
                  (t.recurrenceRule.isNotNull() &
                      t.dueDate.isNull() &
                      t.isCompleted.equals(false))))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.dueDate),
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  /// Watch upcoming tasks (excludes completed tasks)
  Stream<List<Task>> watchUpcomingTasks(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return (select(tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.isCompleted.equals(false) &
              t.parentId.isNull() &
              t.dueDate.isNotNull() &
              t.dueDate.isBiggerOrEqualValue(startOfDay))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dueDate),
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  /// Watch subtasks of a parent task
  Stream<List<Task>> watchSubtasks(String parentId) {
    return (select(tasks)
          ..where(
              (t) => t.parentId.equals(parentId) & t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  /// Get all non-deleted tasks for a user
  Future<List<Task>> getTasks(String userId) {
    return (select(tasks)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get a single task by ID (excluding deleted)
  Future<Task?> getTask(String id) {
    return (select(tasks)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Insert or update a task
  Future<void> upsertTask(TasksCompanion task) {
    return into(tasks).insertOnConflictUpdate(task);
  }

  /// Mark a task as deleted (soft delete)
  Future<void> softDeleteTask(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        isPendingSync: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently delete a task
  Future<void> hardDeleteTask(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Update task sort orders
  Future<void> updateTaskSortOrders(List<Task> orderedTasks) async {
    await batch((batch) {
      for (int i = 0; i < orderedTasks.length; i++) {
        batch.update(
          tasks,
          TasksCompanion(
            sortOrder: Value(i),
            isPendingSync: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
          where: (t) => t.id.equals(orderedTasks[i].id),
        );
      }
    });
  }

  /// Get tasks pending sync
  Future<List<Task>> getPendingSyncTasks() {
    return (select(tasks)..where((t) => t.isPendingSync.equals(true))).get();
  }

  /// Clear pending sync flag for a task
  Future<void> clearTaskPendingSync(String id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      const TasksCompanion(isPendingSync: Value(false)),
    );
  }

  /// Update task timestamp to match server timestamp (for realtime sync protection)
  Future<void> updateTaskTimestamp(String id, DateTime updatedAt) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(updatedAt: Value(updatedAt)),
    );
  }

  // ==================== Sync Queue ====================

  /// Add an operation to the sync queue
  Future<int> addToSyncQueue(SyncQueueCompanion entry) {
    return into(syncQueue).insert(entry);
  }

  /// Get all pending sync operations (oldest first)
  Future<List<SyncQueueData>> getPendingSyncOperations() {
    return (select(syncQueue)..orderBy([(q) => OrderingTerm(expression: q.id)]))
        .get();
  }

  /// Watch pending sync count
  Stream<int> watchPendingSyncCount() {
    final countExp = syncQueue.id.count();
    return (selectOnly(syncQueue)..addColumns([countExp]))
        .map((row) => row.read(countExp) ?? 0)
        .watchSingle();
  }

  /// Watch the queue entries so the UI can distinguish active retries from
  /// operations that have exhausted their automatic retry budget.
  Stream<List<SyncQueueData>> watchPendingSyncOperations() {
    return (select(syncQueue)..orderBy([(q) => OrderingTerm(expression: q.id)]))
        .watch();
  }

  /// Remove a sync operation after successful sync
  Future<void> removeSyncOperation(int id) {
    return (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Replace the payload of a queued operation, keeping its queue position.
  /// Used to merge successive edits of the same entity into a single op.
  Future<void> updateSyncOperationPayload(int id, String payload) {
    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(payload: Value(payload)),
    );
  }

  /// Update retry count and error for failed operation
  Future<void> updateSyncOperationRetry(
      int id, int currentRetryCount, String? error) {
    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(currentRetryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Clear all sync queue entries for an entity
  Future<void> clearSyncQueueForEntity(String entityType, String entityId) {
    return (delete(syncQueue)
          ..where((q) =>
              q.entityType.equals(entityType) & q.entityId.equals(entityId)))
        .go();
  }

  // ==================== Sync Metadata ====================

  /// Get a sync metadata value
  Future<String?> getSyncMetadata(String key) async {
    final result = await (select(syncMetadata)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Set a sync metadata value
  Future<void> setSyncMetadata(String key, String value) {
    return into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ==================== Comments ====================

  /// Watch all non-deleted comments for a task
  Stream<List<Comment>> watchComments(String taskId) {
    return (select(comments)
          ..where((c) => c.taskId.equals(taskId) & c.isDeleted.equals(false))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Get all non-deleted comments for a task
  Future<List<Comment>> getComments(String taskId) {
    return (select(comments)
          ..where((c) => c.taskId.equals(taskId) & c.isDeleted.equals(false))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Get all non-deleted comments (for sync cleanup)
  Future<List<Comment>> getAllComments() {
    return (select(comments)..where((c) => c.isDeleted.equals(false))).get();
  }

  /// Get a single comment by ID
  Future<Comment?> getComment(String id) {
    return (select(comments)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Insert or update a comment
  Future<void> upsertComment(CommentsCompanion comment) {
    return into(comments).insertOnConflictUpdate(comment);
  }

  /// Mark a comment as deleted (soft delete)
  Future<void> softDeleteComment(String id) {
    return (update(comments)..where((c) => c.id.equals(id))).write(
      CommentsCompanion(
        isDeleted: const Value(true),
        isPendingSync: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently delete a comment
  Future<void> hardDeleteComment(String id) {
    return (delete(comments)..where((c) => c.id.equals(id))).go();
  }

  /// Get comments pending sync
  Future<List<Comment>> getPendingSyncComments() {
    return (select(comments)..where((c) => c.isPendingSync.equals(true))).get();
  }

  /// Clear pending sync flag for a comment
  Future<void> clearCommentPendingSync(String id) {
    return (update(comments)..where((c) => c.id.equals(id))).write(
      const CommentsCompanion(isPendingSync: Value(false)),
    );
  }

  // ==================== Clear Data ====================

  /// Clear all data for a user (used on logout)
  Future<void> clearAllData() async {
    await delete(syncQueue).go();
    await delete(syncMetadata).go();
    await delete(comments).go();
    await delete(tasks).go();
    await delete(projects).go();
  }

  /// Clear soft-deleted items after confirmed sync
  Future<void> cleanupDeletedItems() async {
    await (delete(projects)..where((p) => p.isDeleted.equals(true))).go();
    await (delete(tasks)..where((t) => t.isDeleted.equals(true))).go();
    await (delete(comments)..where((c) => c.isDeleted.equals(true))).go();
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'taskboi',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
