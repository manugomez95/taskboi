import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart' hide Project;
import '../../../core/database/model_converters.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/supabase_serialization.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/project.dart';

// Stream from local Drift database - this is the source of truth for UI
final _localProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value([]);
  }

  return db.watchProjects(user.id).map((driftProjects) {
    return ModelConverters.projectsFromDrift(driftProjects);
  });
});

// Main projects stream provider - reads from local DB
final projectsStreamProvider = Provider<AsyncValue<List<Project>>>((ref) {
  return ref.watch(_localProjectsStreamProvider);
});

// Inbox project from local DB
final inboxProjectProvider = FutureProvider<Project?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return null;

  final driftProject = await db.getInboxProject(user.id);
  if (driftProject == null) return null;

  return ModelConverters.projectFromDrift(driftProject);
});

// Single project by ID from local DB
final projectProvider =
    FutureProvider.family<Project?, String>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  final projects =
      await db.getProjects(ref.watch(currentUserProvider)?.id ?? '');

  final driftProject = projects.where((p) => p.id == id).firstOrNull;
  if (driftProject == null) return null;

  return ModelConverters.projectFromDrift(driftProject);
});

class ProjectsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final SyncService _syncService;
  final String? _userId;

  ProjectsNotifier(this._db, this._syncService, this._userId)
      : super(const AsyncValue.data(null));

  Future<Project?> createProject({
    required String name,
    String color = '#6B7280',
    String? icon,
  }) async {
    if (_userId == null) return null;

    state = const AsyncValue.loading();
    try {
      // Generate ID locally
      final id = const Uuid().v4();
      final now = DateTime.now();

      // Get max sort order from local DB
      final existingProjects = await _db.getProjects(_userId);
      final maxSortOrder = existingProjects.isEmpty
          ? -1
          : existingProjects
              .map((p) => p.sortOrder)
              .reduce((a, b) => a > b ? a : b);

      final project = Project(
        id: id,
        userId: _userId,
        name: name,
        color: color,
        icon: icon ?? 'folder',
        isInbox: false,
        sortOrder: maxSortOrder + 1,
        createdAt: now,
        updatedAt: now,
      );

      // Write to local DB immediately
      await _db.upsertProject(ProjectsCompanion(
        id: Value(id),
        userId: Value(_userId),
        name: Value(name),
        color: Value(color),
        icon: Value(icon ?? 'folder'),
        isInbox: const Value(false),
        sortOrder: Value(maxSortOrder + 1),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPendingSync: const Value(true),
        isDeleted: const Value(false),
      ));

      // Queue sync operation
      await _syncService.queueCreate(
        SyncEntityType.project,
        id,
        project.toJson(),
      );

      // Try to sync immediately
      _syncService.processPendingOperations();

      state = const AsyncValue.data(null);
      return project;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateProject({
    required String id,
    String? name,
    String? color,
    String? icon,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // Build update payload
      final updates = <String, dynamic>{
        'id': id,
        'updated_at': utcIso(now),
      };
      if (name != null) updates['name'] = name;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;
      if (sortOrder != null) updates['sort_order'] = sortOrder;

      // Update local DB
      await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          color: color != null ? Value(color) : const Value.absent(),
          icon: icon != null ? Value(icon) : const Value.absent(),
          sortOrder:
              sortOrder != null ? Value(sortOrder) : const Value.absent(),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync operation
      await _syncService.queueUpdate(SyncEntityType.project, id, updates);

      // Try to sync immediately
      _syncService.processPendingOperations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(String id) async {
    state = const AsyncValue.loading();
    try {
      // Soft delete in local DB
      await _db.softDeleteProject(id);

      // Queue sync operation
      await _syncService.queueDelete(SyncEntityType.project, id);

      // Try to sync immediately
      _syncService.processPendingOperations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderProjects(List<Project> reorderedNonInbox) async {
    // Update sort orders in local DB
    final now = DateTime.now();
    for (int i = 0; i < reorderedNonInbox.length; i++) {
      final project = reorderedNonInbox[i];
      await (_db.update(_db.projects)..where((p) => p.id.equals(project.id)))
          .write(
        ProjectsCompanion(
          sortOrder: Value(i),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync for each project
      await _syncService.queueUpdate(
        SyncEntityType.project,
        project.id,
        {'id': project.id, 'sort_order': i, 'updated_at': utcIso(now)},
      );
    }

    // Try to sync immediately
    _syncService.processPendingOperations();
  }
}

final projectsNotifierProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  final userId = ref.watch(currentUserProvider)?.id;

  return ProjectsNotifier(db, syncService, userId);
});
