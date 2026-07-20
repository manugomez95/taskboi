import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../connectivity/connectivity_service.dart';
import 'sync_operation.dart';

/// Service responsible for syncing local database with Supabase
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final ConnectivityService _connectivity;

  RealtimeChannel? _projectsChannel;
  RealtimeChannel? _tasksChannel;
  RealtimeChannel? _commentsChannel;
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  bool _isProcessingQueue = false;
  bool _isSyncing = false;
  Completer<void>? _syncCompleter;
  String? _activeUserId;

  static const Duration _periodicSyncInterval = Duration(minutes: 5);
  static const Duration _realtimeRetryDelay = Duration(seconds: 10);
  static const Duration _networkTimeout = Duration(seconds: 30);
  int _realtimeRetryCount = 0;
  static const int _maxRealtimeRetries = 5;

  /// Incremented every time the realtime channels are (re)created.
  /// Status callbacks from channels of an older generation — fired when
  /// [startRealtimeSync] unsubscribes them — are ignored, so tearing down
  /// old channels can never be mistaken for a disconnect.
  int _realtimeGeneration = 0;
  Timer? _realtimeReconnectTimer;

  SyncService({
    required AppDatabase db,
    required SupabaseClient supabase,
    required ConnectivityService connectivity,
  })  : _db = db,
        _supabase = supabase,
        _connectivity = connectivity;

  /// Initialize sync service - start listening for connectivity changes
  void initialize() {
    _connectivitySubscription =
        _connectivity.onlineStatusStream.listen((isOnline) {
      if (isOnline) {
        resumeSync();
      }
    });

    // Start periodic sync timer as a safety net for changes that
    // might not be picked up by Realtime (disconnects, race conditions).
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) async {
      if (_activeUserId != null && await _connectivity.isOnline) {
        await processPendingOperations();
        await performFullSync(_activeUserId!);
      }
    });
  }

  /// Re-sync when app resumes from background or connectivity is restored.
  /// Re-subscribes to realtime channels and pulls latest data from server.
  Future<void> resumeSync() async {
    final userId = _activeUserId;
    if (userId == null) return;
    if (!await _connectivity.isOnline) return;

    // Re-subscribe to realtime (cleans up stale channels). A resume is a
    // genuine external trigger, so it earns a fresh reconnect-retry budget;
    // timer-driven reconnects deliberately don't reset it.
    _realtimeRetryCount = 0;
    startRealtimeSync(userId);

    // Push pending local changes first
    await processPendingOperations();

    // Pull latest from server
    await performFullSync(userId);
  }

  /// Dispose resources
  void dispose() {
    _realtimeGeneration++;
    _realtimeReconnectTimer?.cancel();
    _projectsChannel?.unsubscribe();
    _tasksChannel?.unsubscribe();
    _commentsChannel?.unsubscribe();
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _activeUserId = null;
  }

  // ==================== Queue Operations ====================

  /// Queue a create operation
  Future<void> queueCreate(SyncEntityType entityType, String entityId,
      Map<String, dynamic> payload) async {
    await _db.addToSyncQueue(SyncQueueCompanion(
      entityType: Value(entityType.value),
      entityId: Value(entityId),
      operation: Value(SyncOperationType.create.value),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Queue an update operation.
  ///
  /// If the entity already has a queued create/update, the new fields are
  /// merged into that operation instead of replacing it. Replacing used to
  /// lose data: an offline-created task lost its CREATE op (so it never
  /// reached the server), and consecutive partial edits dropped the fields
  /// of the earlier one.
  Future<void> queueUpdate(SyncEntityType entityType, String entityId,
      Map<String, dynamic> payload) async {
    final pendingOps = await _db.getPendingSyncOperations();
    final existing = pendingOps
        .where((op) =>
            op.entityType == entityType.value &&
            op.entityId == entityId &&
            op.operation != SyncOperationType.delete.value)
        .firstOrNull;

    if (existing != null) {
      final merged = {
        ...jsonDecode(existing.payload) as Map<String, dynamic>,
        ...payload,
      };
      await _db.updateSyncOperationPayload(existing.id, jsonEncode(merged));
      return;
    }

    await _db.addToSyncQueue(SyncQueueCompanion(
      entityType: Value(entityType.value),
      entityId: Value(entityId),
      operation: Value(SyncOperationType.update.value),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Queue a delete operation
  Future<void> queueDelete(SyncEntityType entityType, String entityId) async {
    // Remove any existing operations for this entity
    await _db.clearSyncQueueForEntity(entityType.value, entityId);

    await _db.addToSyncQueue(SyncQueueCompanion(
      entityType: Value(entityType.value),
      entityId: Value(entityId),
      operation: Value(SyncOperationType.delete.value),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ==================== Process Queue ====================

  /// Process all pending sync operations
  Future<void> processPendingOperations() async {
    if (_isProcessingQueue) return;
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) return;

    _isProcessingQueue = true;

    try {
      final operations = await _db.getPendingSyncOperations();

      for (final op in operations) {
        try {
          // Timeout so a hung request can't stall the queue forever — the
          // startup loading screen waits on this, so an unbounded await
          // here froze the whole app.
          await _processOperation(op).timeout(_networkTimeout);
          // Success - remove from queue
          await _db.removeSyncOperation(op.id);
        } catch (e) {
          // CREATE operations are the only durable record that a local-only
          // entity still needs to be inserted remotely. Never discard them:
          // later edits must keep merging into the CREATE and a recovered
          // connection/session must be able to retry it. Cap the persisted
          // count at maxRetries while continuing the periodic retries.
          if (op.operation == SyncOperationType.create.value) {
            await _db.updateSyncOperationRetry(
              op.id,
              op.retryCount < SyncOperation.maxRetries
                  ? op.retryCount
                  : SyncOperation.maxRetries - 1,
              e.toString(),
            );
          } else if (op.retryCount < SyncOperation.maxRetries) {
            await _db.updateSyncOperationRetry(
                op.id, op.retryCount, e.toString());
          } else {
            // UPDATE/DELETE can be abandoned after the retry budget. Their
            // pending flag must be cleared so Realtime is not blocked forever.
            await _db.removeSyncOperation(op.id);
            await _clearPendingSync(op.entityType, op.entityId);
          }
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Process a single sync operation
  Future<void> _processOperation(SyncQueueData op) async {
    final entityType = SyncEntityTypeExtension.fromString(op.entityType);
    final operation = SyncOperationTypeExtension.fromString(op.operation);
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;

    switch (entityType) {
      case SyncEntityType.project:
        await _processProjectOperation(op.entityId, operation, payload);
        break;
      case SyncEntityType.task:
        await _processTaskOperation(op.entityId, operation, payload);
        break;
      case SyncEntityType.comment:
        await _processCommentOperation(op.entityId, operation, payload);
        break;
    }
  }

  Future<void> _processProjectOperation(
    String entityId,
    SyncOperationType operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case SyncOperationType.create:
        final createResult =
            await _supabase.from('projects').insert(payload).select();
        if (createResult.isEmpty) {
          throw Exception('Create failed: project $entityId was not inserted');
        }
        await _db.clearProjectPendingSync(entityId);
        break;
      case SyncOperationType.update:
        final updateResult = await _supabase
            .from('projects')
            .update(payload)
            .eq('id', entityId)
            .select();
        if (updateResult.isEmpty) {
          throw Exception(
              'Update failed: project $entityId not found in Supabase');
        }
        await _db.clearProjectPendingSync(entityId);
        break;
      case SyncOperationType.delete:
        await _supabase.from('projects').delete().eq('id', entityId);
        await _db.hardDeleteProject(entityId);
        break;
    }
  }

  Future<void> _processTaskOperation(
    String entityId,
    SyncOperationType operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case SyncOperationType.create:
        List<dynamic> createResult;
        try {
          createResult = await _supabase.from('tasks').insert(payload).select();
        } on PostgrestException catch (e) {
          if (e.code != '23505' ||
              !await _resolveDuplicateTaskCreate(entityId, payload)) {
            rethrow;
          }
          return;
        }
        if (createResult.isEmpty) {
          throw Exception('Create failed: task $entityId was not inserted');
        }
        await _db.clearTaskPendingSync(entityId);
        break;
      case SyncOperationType.update:
        final updateResult = await _supabase
            .from('tasks')
            .update(payload)
            .eq('id', entityId)
            .select();
        if (updateResult.isEmpty) {
          // Without a session RLS hides every row, which is indistinguishable
          // from a deleted task — fail and retry instead of deleting.
          if (_supabase.auth.currentSession == null) {
            throw Exception(
                'Update failed: no auth session while syncing task $entityId');
          }
          // The task no longer exists on the server: it was deleted from
          // another device or via the MCP API. Re-inserting it from local
          // data (the old behavior) resurrected deleted tasks, so drop the
          // local copy instead. Offline-created tasks can't hit this path:
          // queueUpdate merges their edits into the still-queued CREATE.
          await _db.hardDeleteTask(entityId);
          break;
        }
        // Update local timestamp to match server's timestamp
        // This ensures realtime updates with the same timestamp are correctly skipped
        final serverUpdatedAt = updateResult.first['updated_at'] as String?;
        if (serverUpdatedAt != null) {
          await _db.updateTaskTimestamp(
              entityId, DateTime.parse(serverUpdatedAt));
        }
        await _db.clearTaskPendingSync(entityId);
        break;
      case SyncOperationType.delete:
        await _supabase.from('tasks').delete().eq('id', entityId);
        await _db.hardDeleteTask(entityId);
        break;
    }
  }

  Future<bool> _resolveDuplicateTaskCreate(
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final existingById = await _supabase
        .from('tasks')
        .select('id')
        .eq('id', entityId)
        .maybeSingle();
    if (existingById != null) {
      await _db.clearTaskPendingSync(entityId);
      return true;
    }

    final recurrenceParentId = payload['recurrence_parent_id'] as String?;
    final recurrenceAnchorDate =
        _dateOnly(payload['recurrence_anchor_date'] ?? payload['due_date']);
    if (recurrenceParentId == null || recurrenceAnchorDate == null) {
      return false;
    }

    final existingOccurrence = await _supabase
        .from('tasks')
        .select('id')
        .eq('user_id', payload['user_id'] as String)
        .eq('recurrence_parent_id', recurrenceParentId)
        .eq('recurrence_anchor_date', recurrenceAnchorDate)
        .eq('is_completed', false)
        .maybeSingle();
    if (existingOccurrence == null) {
      return false;
    }

    await _db.hardDeleteTask(entityId);
    return true;
  }

  String? _dateOnly(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String().split('T').first;
    return value.toString().split('T').first;
  }

  Future<void> _processCommentOperation(
    String entityId,
    SyncOperationType operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case SyncOperationType.create:
        final createResult =
            await _supabase.from('comments').insert(payload).select();
        if (createResult.isEmpty) {
          throw Exception('Create failed: comment $entityId was not inserted');
        }
        await _db.clearCommentPendingSync(entityId);
        break;
      case SyncOperationType.update:
        final updateResult = await _supabase
            .from('comments')
            .update(payload)
            .eq('id', entityId)
            .select();
        if (updateResult.isEmpty) {
          throw Exception(
              'Update failed: comment $entityId not found in Supabase');
        }
        await _db.clearCommentPendingSync(entityId);
        break;
      case SyncOperationType.delete:
        await _supabase.from('comments').delete().eq('id', entityId);
        await _db.hardDeleteComment(entityId);
        break;
    }
  }

  // ==================== Realtime Sync ====================

  /// Start listening for remote changes using Realtime Channels
  /// This is more reliable than .stream() because:
  /// 1. We receive the actual changed data directly (not re-fetch all rows)
  /// 2. Better handling of INSERT, UPDATE, DELETE events
  /// 3. More reliable on web platforms
  void startRealtimeSync(String userId) {
    _activeUserId = userId;
    _realtimeReconnectTimer?.cancel();

    // Invalidate status callbacks from the channels being torn down.
    // unsubscribe() fires the old channel's subscribe callback with a
    // `closed` status; without the generation guard each of those callbacks
    // scheduled another startRealtimeSync, which unsubscribed 3 more
    // channels, snowballing into an exponential reconnect storm that froze
    // the app on every platform.
    final generation = ++_realtimeGeneration;

    // Clean up existing channels
    _projectsChannel?.unsubscribe();
    _tasksChannel?.unsubscribe();
    _commentsChannel?.unsubscribe();

    // Listen for project changes
    _projectsChannel = _supabase
        .channel('projects_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'projects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeProjectEvent(payload),
        )
        .subscribe(
            (status, error) => _onRealtimeStatus(generation, status, error));

    // Listen for task changes
    _tasksChannel = _supabase
        .channel('tasks_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeTaskEvent(payload),
        )
        .subscribe(
            (status, error) => _onRealtimeStatus(generation, status, error));

    // Listen for comment changes
    _commentsChannel = _supabase
        .channel('comments_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeCommentEvent(payload),
        )
        .subscribe(
            (status, error) => _onRealtimeStatus(generation, status, error));
  }

  /// Handle realtime subscription status changes with autoreconnect
  void _onRealtimeStatus(
      int generation, RealtimeSubscribeStatus status, Object? error) {
    // Stale callback from a channel that startRealtimeSync/stopRealtimeSync
    // already tore down — its `closed` status is expected, not a disconnect.
    if (generation != _realtimeGeneration) return;

    if (status == RealtimeSubscribeStatus.subscribed) {
      _realtimeRetryCount = 0;
      return;
    }

    if (_activeUserId == null) return;

    // CHANNEL_ERROR, TIMED_OUT, or CLOSED — schedule a reconnect if we haven't
    // exceeded the max retry count. A single shared timer coalesces the three
    // channels' status callbacks into one reconnect attempt; even if realtime
    // stays down, the periodic full sync keeps data flowing.
    if (_realtimeReconnectTimer?.isActive ?? false) return;

    if (_realtimeRetryCount < _maxRealtimeRetries) {
      _realtimeRetryCount++;
      developer.log(
        '[SyncService] Realtime disconnected (attempt $_realtimeRetryCount/$_maxRealtimeRetries). '
        'Reconnecting in ${_realtimeRetryDelay.inSeconds}s... Status: $status Error: $error',
        name: 'taskboi.sync',
      );
      _realtimeReconnectTimer = Timer(_realtimeRetryDelay, () {
        if (_activeUserId != null) {
          startRealtimeSync(_activeUserId!);
        }
      });
    } else {
      developer.log(
        '[SyncService] Realtime failed after $_maxRealtimeRetries retries. '
        'Status: $status Error: $error',
        name: 'taskboi.sync',
      );
    }
  }

  /// Stop realtime sync
  void stopRealtimeSync() {
    _activeUserId = null;
    _realtimeGeneration++;
    _realtimeReconnectTimer?.cancel();
    _projectsChannel?.unsubscribe();
    _tasksChannel?.unsubscribe();
    _commentsChannel?.unsubscribe();
    _projectsChannel = null;
    _tasksChannel = null;
    _commentsChannel = null;
  }

  /// Handle realtime project events
  Future<void> _handleRealtimeProjectEvent(
      PostgresChangePayload payload) async {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        if (payload.newRecord.isNotEmpty) {
          await _applyRemoteProject(payload.newRecord);
        }
        break;
      case PostgresChangeEvent.delete:
        if (payload.oldRecord.isNotEmpty) {
          final projectId = payload.oldRecord['id'] as String?;
          if (projectId != null) {
            await _db.hardDeleteProject(projectId);
          }
        }
        break;
      default:
        break;
    }
  }

  /// Handle realtime task events
  Future<void> _handleRealtimeTaskEvent(PostgresChangePayload payload) async {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        if (payload.newRecord.isNotEmpty) {
          await _applyRemoteTask(payload.newRecord);
        }
        break;
      case PostgresChangeEvent.delete:
        if (payload.oldRecord.isNotEmpty) {
          final taskId = payload.oldRecord['id'] as String?;
          if (taskId != null) {
            // Check if we have pending changes for this task
            final pendingTasks = await _db.getPendingSyncTasks();
            final isPending = pendingTasks.any((t) => t.id == taskId);
            if (!isPending) {
              await _db.hardDeleteTask(taskId);
            }
          }
        }
        break;
      default:
        break;
    }
  }

  /// Handle realtime comment events
  Future<void> _handleRealtimeCommentEvent(
      PostgresChangePayload payload) async {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
      case PostgresChangeEvent.update:
        if (payload.newRecord.isNotEmpty) {
          await _applyRemoteComment(payload.newRecord);
        }
        break;
      case PostgresChangeEvent.delete:
        if (payload.oldRecord.isNotEmpty) {
          final commentId = payload.oldRecord['id'] as String?;
          if (commentId != null) {
            await _db.hardDeleteComment(commentId);
          }
        }
        break;
      default:
        break;
    }
  }

  /// Clear the pending sync flag for any entity type.
  /// Prevents entities from being permanently blocked from Realtime updates
  /// when a sync queue operation exhausts its retries without clearing the flag.
  Future<void> _clearPendingSync(String entityType, String entityId) async {
    final type = SyncEntityTypeExtension.fromString(entityType);
    switch (type) {
      case SyncEntityType.task:
        await _db.clearTaskPendingSync(entityId);
        break;
      case SyncEntityType.project:
        await _db.clearProjectPendingSync(entityId);
        break;
      case SyncEntityType.comment:
        await _db.clearCommentPendingSync(entityId);
        break;
    }
  }

  /// Apply a remote project to local database with conflict resolution.
  ///
  /// [trustRemote] skips the timestamp comparison and is used by
  /// [performFullSync]: the snapshot is fetched after pending local changes
  /// are pushed, so it is authoritative. This also self-heals rows whose
  /// local timestamp got ahead of the server (older app versions uploaded
  /// local time as if it were UTC, so remote changes made within the
  /// timezone offset were skipped as "older" and devices stayed stale).
  Future<void> _applyRemoteProject(
    Map<String, dynamic> remoteData, {
    bool trustRemote = false,
    List<SyncQueueData>? knownPendingOps,
  }) async {
    final remoteId = remoteData['id'] as String;
    final remoteUpdatedAt = remoteData['updated_at'] != null
        ? DateTime.parse(remoteData['updated_at'] as String)
        : null;

    // Check if we have a pending sync for this entity.
    // Check the sync queue rather than the isPendingSync flag, which can get
    // stuck as true when a sync operation exhausts its retries.
    final pendingOps = knownPendingOps ?? await _db.getPendingSyncOperations();
    final hasPendingForThis = pendingOps.any(
      (op) =>
          op.entityType == SyncEntityType.project.value &&
          op.entityId == remoteId,
    );

    if (hasPendingForThis) {
      // CRITICAL: Never overwrite pending local changes with remote updates.
      // The user's local action should be preserved until it's synced.
      // After sync, the server's timestamp will be authoritative.
      return;
    }

    // Even if not pending sync, check the current local state to prevent
    // race conditions where clearProjectPendingSync was called before realtime arrived
    if (!trustRemote) {
      final localProjects2 =
          await _db.getProjects(remoteData['user_id'] as String);
      final localProject =
          localProjects2.where((p) => p.id == remoteId).firstOrNull;
      if (localProject != null &&
          localProject.updatedAt != null &&
          remoteUpdatedAt != null) {
        // Skip if remote data is older or same as what we have locally
        if (remoteUpdatedAt.isBefore(localProject.updatedAt!) ||
            remoteUpdatedAt.isAtSameMomentAs(localProject.updatedAt!)) {
          return;
        }
      }
    }

    // Apply remote update
    await _db.upsertProject(ProjectsCompanion(
      id: Value(remoteId),
      userId: Value(remoteData['user_id'] as String),
      name: Value(remoteData['name'] as String? ?? ''),
      color: Value(remoteData['color'] as String? ?? '#6B7280'),
      icon: Value(remoteData['icon'] as String?),
      isInbox: Value(remoteData['is_inbox'] as bool? ?? false),
      sortOrder: Value(remoteData['sort_order'] as int? ?? 0),
      createdAt: Value(remoteData['created_at'] != null
          ? DateTime.parse(remoteData['created_at'] as String)
          : null),
      updatedAt: Value(remoteUpdatedAt),
      isPendingSync: const Value(false),
      isDeleted: const Value(false),
    ));
  }

  /// Apply a remote task to local database with conflict resolution.
  /// See [_applyRemoteProject] for the meaning of [trustRemote].
  Future<void> _applyRemoteTask(
    Map<String, dynamic> remoteData, {
    bool trustRemote = false,
    List<SyncQueueData>? knownPendingOps,
  }) async {
    final remoteId = remoteData['id'] as String;
    final remoteUpdatedAt = remoteData['updated_at'] != null
        ? DateTime.parse(remoteData['updated_at'] as String)
        : null;

    // Check if we have a pending sync for this entity.
    // Check the actual sync queue rather than the isPendingSync flag, which can
    // get stuck as true if a previous sync operation exhausted its retries
    // without clearing the flag (see processPendingOperations).
    final pendingOps = knownPendingOps ?? await _db.getPendingSyncOperations();
    final hasPendingForThis = pendingOps.any(
      (op) =>
          op.entityType == SyncEntityType.task.value && op.entityId == remoteId,
    );

    // CRITICAL: Never overwrite pending local changes with remote updates.
    // The user's local action should be preserved until it's synced.
    // After sync, the server's timestamp will be authoritative.
    if (hasPendingForThis) {
      return;
    }

    // Even if not pending sync, check the current local state to prevent
    // race conditions where clearTaskPendingSync was called before realtime arrived
    if (!trustRemote) {
      final localTask = await _db.getTask(remoteId);
      if (localTask != null &&
          localTask.updatedAt != null &&
          remoteUpdatedAt != null) {
        // Skip only if remote data is strictly older than what we have locally.
        // Mismo timestamp NO significa mismo contenido — cambios externos (MCP API,
        // otro dispositivo) pueden tener el mismo timestamp pero datos diferentes.
        if (remoteUpdatedAt.isBefore(localTask.updatedAt!)) {
          return;
        }
      }
    }

    // Apply remote update
    await _db.upsertTask(TasksCompanion(
      id: Value(remoteId),
      projectId: Value(remoteData['project_id'] as String),
      userId: Value(remoteData['user_id'] as String),
      parentId: Value(remoteData['parent_id'] as String?),
      title: Value(remoteData['title'] as String? ?? ''),
      description: Value(remoteData['description'] as String?),
      dueDate: Value(remoteData['due_date'] != null
          ? DateTime.parse(remoteData['due_date'] as String)
          : null),
      dueTime: Value(remoteData['due_time'] as String?),
      priority: Value(remoteData['priority'] as int? ?? 0),
      isCompleted: Value(remoteData['is_completed'] as bool? ?? false),
      completedAt: Value(remoteData['completed_at'] != null
          ? DateTime.parse(remoteData['completed_at'] as String)
          : null),
      sortOrder: Value(remoteData['sort_order'] as int? ?? 0),
      recurrenceRule: Value(remoteData['recurrence_rule'] as String?),
      recurrenceParentId: Value(remoteData['recurrence_parent_id'] as String?),
      recurrenceAnchorDate: Value(remoteData['recurrence_anchor_date'] != null
          ? DateTime.parse(remoteData['recurrence_anchor_date'] as String)
          : null),
      assignedTo: Value(remoteData['assigned_to'] as String? ?? 'manuel'),
      createdAt: Value(remoteData['created_at'] != null
          ? DateTime.parse(remoteData['created_at'] as String)
          : null),
      updatedAt: Value(remoteUpdatedAt),
      isPendingSync: const Value(false),
      isDeleted: const Value(false),
    ));
  }

  /// Apply a remote comment to local database with conflict resolution.
  /// See [_applyRemoteProject] for the meaning of [trustRemote].
  Future<void> _applyRemoteComment(
    Map<String, dynamic> remoteData, {
    bool trustRemote = false,
    List<SyncQueueData>? knownPendingOps,
  }) async {
    final remoteId = remoteData['id'] as String;
    final remoteUpdatedAt = remoteData['updated_at'] != null
        ? DateTime.parse(remoteData['updated_at'] as String)
        : null;

    // Check if we have a pending sync for this entity.
    // Check the actual sync queue rather than the isPendingSync flag, which can
    // get stuck as true if a previous sync operation exhausted its retries.
    final pendingOps = knownPendingOps ?? await _db.getPendingSyncOperations();
    final hasPendingForThis = pendingOps.any(
      (op) =>
          op.entityType == SyncEntityType.comment.value &&
          op.entityId == remoteId,
    );

    // CRITICAL: Never overwrite pending local changes with remote updates.
    if (hasPendingForThis) {
      return;
    }

    // Even if not pending sync, check the current local state to prevent
    // race conditions where clearCommentPendingSync was called before realtime arrived
    if (!trustRemote) {
      final localComment = await _db.getComment(remoteId);
      if (localComment != null &&
          localComment.updatedAt != null &&
          remoteUpdatedAt != null) {
        // Skip if remote data is older or same as what we have locally
        if (remoteUpdatedAt.isBefore(localComment.updatedAt!) ||
            remoteUpdatedAt.isAtSameMomentAs(localComment.updatedAt!)) {
          return;
        }
      }
    }

    // Apply remote update
    final remoteImages = remoteData['images'];
    String imagesJson;
    if (remoteImages is String) {
      imagesJson = remoteImages;
    } else if (remoteImages is List) {
      imagesJson = jsonEncode(remoteImages);
    } else {
      imagesJson = '[]';
    }

    await _db.upsertComment(CommentsCompanion(
      id: Value(remoteId),
      taskId: Value(remoteData['task_id'] as String),
      userId: Value(remoteData['user_id'] as String),
      content: Value(remoteData['content'] as String? ?? ''),
      images: Value(imagesJson),
      createdAt: Value(remoteData['created_at'] != null
          ? DateTime.parse(remoteData['created_at'] as String)
          : null),
      updatedAt: Value(remoteUpdatedAt),
      isPendingSync: const Value(false),
      isDeleted: const Value(false),
    ));
  }

  // ==================== Initial Sync ====================

  /// Perform initial full sync from Supabase
  Future<void> performFullSync(String userId) async {
    if (_isSyncing) {
      // Already syncing — wait for it to finish instead of silently ignoring
      await _syncCompleter?.future;
      return;
    }
    if (!await _connectivity.isOnline) return;

    _isSyncing = true;
    _syncCompleter = Completer<void>();
    try {
      // Fetch all data from Supabase in parallel. Timeout so a hung request
      // can't leave the app stuck on the startup loading screen (the router
      // waits on this future) or block every later performFullSync caller.
      final results = await Future.wait([
        _supabase.from('projects').select().eq('user_id', userId),
        _supabase.from('tasks').select().eq('user_id', userId),
        _supabase.from('comments').select().eq('user_id', userId),
      ]).timeout(_networkTimeout);

      final projectsResponse = results[0];
      final tasksResponse = results[1];
      final commentsResponse = results[2];

      // Apply all changes in a single transaction so Drift stream listeners
      // fire once (not per-item), eliminating UI flicker during sync
      await _db.transaction(() async {
        // Fetch the pending queue once for the whole snapshot; querying it
        // per-row made full sync O(n²) and janked the UI on large datasets.
        final pendingOps = await _db.getPendingSyncOperations();

        // Sync projects
        for (final projectData in projectsResponse) {
          await _applyRemoteProject(projectData,
              trustRemote: true, knownPendingOps: pendingOps);
        }

        // Delete local projects that don't exist on server
        final remoteProjectIds =
            projectsResponse.map((p) => p['id'] as String).toSet();
        final localProjects = await _db.getProjects(userId);
        final pendingProjects = await _db.getPendingSyncProjects();
        final pendingProjectIds = pendingProjects.map((p) => p.id).toSet();

        for (final localProject in localProjects) {
          if (!remoteProjectIds.contains(localProject.id) &&
              !pendingProjectIds.contains(localProject.id)) {
            await _db.hardDeleteProject(localProject.id);
          }
        }

        // Sync tasks
        for (final taskData in tasksResponse) {
          await _applyRemoteTask(taskData,
              trustRemote: true, knownPendingOps: pendingOps);
        }

        // Delete local tasks that don't exist on server
        final remoteTaskIds =
            tasksResponse.map((t) => t['id'] as String).toSet();
        final localTasks = await _db.getTasks(userId);
        final pendingTasks = await _db.getPendingSyncTasks();
        final pendingTaskIds = pendingTasks.map((t) => t.id).toSet();

        for (final localTask in localTasks) {
          if (!remoteTaskIds.contains(localTask.id) &&
              !pendingTaskIds.contains(localTask.id)) {
            await _db.hardDeleteTask(localTask.id);
          }
        }

        // Sync comments
        for (final commentData in commentsResponse) {
          await _applyRemoteComment(commentData,
              trustRemote: true, knownPendingOps: pendingOps);
        }

        // Delete local comments that don't exist on server
        final remoteCommentIds =
            commentsResponse.map((c) => c['id'] as String).toSet();
        final pendingComments = await _db.getPendingSyncComments();
        final pendingCommentIds = pendingComments.map((c) => c.id).toSet();

        // Get all local comments (across all tasks) for cleanup
        final localComments = await _db.getAllComments();
        for (final localComment in localComments) {
          if (!remoteCommentIds.contains(localComment.id) &&
              !pendingCommentIds.contains(localComment.id)) {
            await _db.hardDeleteComment(localComment.id);
          }
        }
      });

      // Store last sync timestamp
      await _db.setSyncMetadata(
          'lastFullSync', DateTime.now().toIso8601String());
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  /// Check if initial sync is needed
  Future<bool> needsInitialSync() async {
    final lastSync = await _db.getSyncMetadata('lastFullSync');
    return lastSync == null;
  }
}
