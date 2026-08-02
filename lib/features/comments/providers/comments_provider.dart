import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart' hide Comment;
import '../../../core/database/model_converters.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_service.dart';
import 'package:taskboi_task_engine/taskboi_task_engine.dart' show utcIso8601;
import '../../auth/providers/auth_provider.dart';
import '../data/models/comment.dart';

enum CommentCreationStatus { created, notCreated, attachmentsPending }

class CommentCreationResult {
  final CommentCreationStatus status;
  final Comment? comment;

  const CommentCreationResult._(this.status, this.comment);

  const CommentCreationResult.created(Comment comment)
      : this._(CommentCreationStatus.created, comment);

  const CommentCreationResult.notCreated()
      : this._(CommentCreationStatus.notCreated, null);

  const CommentCreationResult.attachmentsPending(Comment comment)
      : this._(CommentCreationStatus.attachmentsPending, comment);
}

// Stream from local Drift database - comments for a specific task
final _localCommentsStreamProvider =
    StreamProvider.family<List<Comment>, String>((ref, taskId) {
  final db = ref.watch(appDatabaseProvider);

  return db.watchComments(taskId).map((driftComments) {
    return ModelConverters.commentsFromDrift(driftComments);
  });
});

// Holds IDs of comments pending deletion (for optimistic UI with undo)
final _pendingCommentDeletionProvider = StateProvider<Set<String>>((ref) => {});

// Main comments stream provider - reads from local DB, filters deleted
final commentsStreamProvider =
    Provider.family<AsyncValue<List<Comment>>, String>((ref, taskId) {
  final pendingDeletion = ref.watch(_pendingCommentDeletionProvider);
  final stream = ref.watch(_localCommentsStreamProvider(taskId));

  return stream.whenData((comments) {
    return comments.where((c) => !pendingDeletion.contains(c.id)).toList();
  });
});

// Count of comments for a task (for display in task list)
final commentCountProvider = Provider.family<AsyncValue<int>, String>((
  ref,
  taskId,
) {
  final commentsAsync = ref.watch(commentsStreamProvider(taskId));
  return commentsAsync.whenData((comments) => comments.length);
});

class CommentsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final SyncService _syncService;
  final String? _userId;
  final Ref _ref;
  final SupabaseClient _supabase;

  CommentsNotifier(this._db, this._syncService, this._userId, this._ref)
      : _supabase = Supabase.instance.client,
        super(const AsyncValue.data(null));

  /// Upload a single image through the authenticated Edge Function. The
  /// server validates the bytes and derives the object key and ownership.
  Future<String> _uploadImage(File imageFile, String commentId) async {
    if (_userId == null) throw Exception('User not authenticated');
    final bytes = await imageFile.readAsBytes();
    final sourceName = imageFile.uri.pathSegments.last;
    final extension = sourceName.contains('.')
        ? sourceName.split('.').last.toLowerCase()
        : 'unknown';
    final fileName = 'upload.$extension';
    final response = await _supabase.functions.invoke(
      'comment-images',
      body: bytes,
      headers: {
        'x-comment-id': commentId,
        'x-file-name': fileName,
        'content-length': bytes.length.toString(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<void> _deleteRemoteImages({
    String? imageId,
    String? legacyUrl,
    String? commentId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _supabase.functions.invoke(
      'comment-images',
      method: HttpMethod.delete,
      queryParameters: {
        if (imageId != null) 'id': imageId,
        if (legacyUrl != null) 'legacyUrl': legacyUrl,
        if (commentId != null) 'commentId': commentId,
      },
    );
  }

  /// Upload multiple images to Supabase Storage.
  /// Returns opaque image IDs; URLs are signed only when rendered.
  Future<List<String>> uploadImages(
    List<File> imageFiles,
    String commentId,
  ) async {
    final imageIds = <String>[];
    try {
      for (final file in imageFiles) {
        imageIds.add(await _uploadImage(file, commentId));
      }
    } catch (uploadError, uploadStack) {
      // A partial batch is not attached to the comment. Ask the server to
      // delete each accepted object; failed removals remain durably charged.
      final cleanupFailures = await _cleanupUnattachedImages(imageIds);
      if (cleanupFailures.isNotEmpty) {
        Error.throwWithStackTrace(
          Exception(
            'Image upload failed; cleanup also failed for: '
            '${cleanupFailures.join(', ')} ($uploadError)',
          ),
          uploadStack,
        );
      }
      Error.throwWithStackTrace(uploadError, uploadStack);
    }
    return imageIds;
  }

  Future<List<String>> _cleanupUnattachedImages(List<String> imageIds) async {
    final failures = <String>[];
    for (final imageId in imageIds) {
      try {
        // The function transitions metadata to cleanup_pending before trying
        // storage deletion, making this a durable cleanup request.
        await _deleteRemoteImages(imageId: imageId);
      } catch (_) {
        failures.add(imageId);
      }
    }
    return failures;
  }

  Future<CommentCreationResult> createComment({
    required String taskId,
    required String content,
    List<File> imageFiles = const [],
  }) async {
    if (_userId == null) return const CommentCreationResult.notCreated();

    state = const AsyncValue.loading();
    var unattachedImageIds = <String>[];
    Comment? createdComment;
    try {
      // Generate ID locally
      final id = const Uuid().v4();
      final now = DateTime.now();

      final comment = Comment(
        id: id,
        taskId: taskId,
        userId: _userId,
        content: content,
        createdAt: now,
        updatedAt: now,
        images: const [],
      );

      // Write to local DB immediately (optimistic)
      await _db.upsertComment(
        CommentsCompanion(
          id: Value(id),
          taskId: Value(taskId),
          userId: Value(_userId),
          content: Value(content),
          images: const Value('[]'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
          isDeleted: const Value(false),
        ),
      );

      // Queue sync operation
      try {
        await _syncService.queueCreate(
          SyncEntityType.comment,
          id,
          comment.toJson(),
        );
      } catch (error, stackTrace) {
        await _db.hardDeleteComment(id);
        Error.throwWithStackTrace(error, stackTrace);
      }
      createdComment = comment;

      // A secure upload can only be bound to a comment that already exists on
      // the server. Plain comments retain the existing offline-first behavior.
      await _syncService.processPendingOperations();

      var imageIds = <String>[];
      if (imageFiles.isNotEmpty) {
        final remoteComment = await _supabase
            .from('comments')
            .select('id')
            .eq('id', id)
            .maybeSingle();
        if (remoteComment == null) {
          throw Exception('Connect to sync the comment before adding images');
        }
        imageIds = await uploadImages(imageFiles, id);
        unattachedImageIds = imageIds;
        await (_db.update(_db.comments)..where((c) => c.id.equals(id))).write(
          CommentsCompanion(
            images: Value(jsonEncode(imageIds)),
            updatedAt: Value(now),
            isPendingSync: const Value(true),
          ),
        );
        await _syncService.queueUpdate(SyncEntityType.comment, id, {
          'id': id,
          'images': imageIds,
          'updated_at': utcIso8601(now),
        });
        await _syncService.processPendingOperations();
        unattachedImageIds = const [];
      }

      state = const AsyncValue.data(null);
      return CommentCreationResult.created(comment.copyWith(images: imageIds));
    } catch (e, st) {
      final cleanupFailures = await _cleanupUnattachedImages(
        unattachedImageIds,
      );
      final reported = cleanupFailures.isEmpty
          ? e
          : Exception('$e; cleanup failed for: ${cleanupFailures.join(', ')}');
      state = AsyncValue.error(reported, st);
      return createdComment == null
          ? const CommentCreationResult.notCreated()
          : CommentCreationResult.attachmentsPending(createdComment);
    }
  }

  Future<bool> retryCommentAttachments({
    required String commentId,
    required List<File> imageFiles,
  }) async {
    state = const AsyncValue.loading();
    var unattachedImageIds = <String>[];
    try {
      await _syncService.processPendingOperations();
      final remoteComment = await _supabase
          .from('comments')
          .select('id')
          .eq('id', commentId)
          .maybeSingle();
      if (remoteComment == null) {
        throw Exception('Comment is not synced');
      }

      final imageIds = await uploadImages(imageFiles, commentId);
      unattachedImageIds = imageIds;
      final now = DateTime.now();
      await (_db.update(
        _db.comments,
      )..where((c) => c.id.equals(commentId)))
          .write(
        CommentsCompanion(
          images: Value(jsonEncode(imageIds)),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );
      await _syncService.queueUpdate(SyncEntityType.comment, commentId, {
        'id': commentId,
        'images': imageIds,
        'updated_at': utcIso8601(now),
      });
      await _syncService.processPendingOperations();
      unattachedImageIds = const [];
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      final cleanupFailures = await _cleanupUnattachedImages(
        unattachedImageIds,
      );
      final reported = cleanupFailures.isEmpty
          ? error
          : Exception(
              '$error; cleanup failed for: ${cleanupFailures.join(', ')}',
            );
      state = AsyncValue.error(reported, stackTrace);
      return false;
    }
  }

  /// Resolve an opaque image ID to a URL that expires after 60 seconds.
  /// Legacy URLs remain readable during the migration window.
  Future<String> resolveImageUrl(String commentId, String image) async {
    final uri = Uri.tryParse(image);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      if (!uri.path.contains('/storage/v1/object/public/comment-images/')) {
        return image;
      }
    }
    final response = await _supabase.functions.invoke(
      'comment-images',
      method: HttpMethod.get,
      queryParameters: {
        if (uri?.hasScheme != true) 'id': image,
        if (uri?.hasScheme == true) 'legacyUrl': image,
        'commentId': commentId,
      },
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  Future<void> updateComment({
    required String id,
    required String content,
    List<String> images = const [],
    List<String> unattachedImageIds = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // Update local DB
      await (_db.update(_db.comments)..where((c) => c.id.equals(id))).write(
        CommentsCompanion(
          content: Value(content),
          images: Value(jsonEncode(images)),
          updatedAt: Value(now),
          isPendingSync: const Value(true),
        ),
      );

      // Queue sync operation
      await _syncService.queueUpdate(SyncEntityType.comment, id, {
        'id': id,
        'content': content,
        'images': images,
        'updated_at': utcIso8601(now),
      });

      // The server-side comment trigger durably queues removed opaque and
      // legacy objects in the same transaction as this reference update.
      // Cleanup reconciliation is intentionally downstream of persistence.
      await _syncService.processPendingOperations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      final cleanupFailures = await _cleanupUnattachedImages(
        unattachedImageIds,
      );
      final reported = cleanupFailures.isEmpty
          ? e
          : Exception('$e; cleanup failed for: ${cleanupFailures.join(', ')}');
      state = AsyncValue.error(reported, st);
    }
  }

  Future<void> deleteComment(String id) async {
    state = const AsyncValue.loading();
    try {
      // Soft delete in local DB
      await _db.softDeleteComment(id);

      // Queue sync operation
      await _syncService.queueDelete(SyncEntityType.comment, id);

      // The remote DELETE cascades through metadata and the database trigger
      // queues legacy objects, so cleanup failure cannot break live references.
      await _syncService.processPendingOperations();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark a comment as pending deletion (hides from UI immediately)
  void markPendingDeletion(String commentId) {
    final current = _ref.read(_pendingCommentDeletionProvider);
    _ref.read(_pendingCommentDeletionProvider.notifier).state = {
      ...current,
      commentId,
    };
  }

  /// Clear pending deletion status (comment reappears if not actually deleted)
  void clearPendingDeletion(String commentId) {
    final current = _ref.read(_pendingCommentDeletionProvider);
    _ref.read(_pendingCommentDeletionProvider.notifier).state =
        current.where((id) => id != commentId).toSet();
  }
}

final commentsNotifierProvider =
    StateNotifierProvider<CommentsNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  final userId = ref.watch(currentUserProvider)?.id;

  return CommentsNotifier(db, syncService, userId, ref);
});
