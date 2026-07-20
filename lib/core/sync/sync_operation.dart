/// Types of sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Entity types that can be synced
enum SyncEntityType {
  project,
  task,
  comment,
}

/// Extension to convert enum to/from string for database storage
extension SyncOperationTypeExtension on SyncOperationType {
  String get value {
    switch (this) {
      case SyncOperationType.create:
        return 'create';
      case SyncOperationType.update:
        return 'update';
      case SyncOperationType.delete:
        return 'delete';
    }
  }

  static SyncOperationType fromString(String value) {
    switch (value) {
      case 'create':
        return SyncOperationType.create;
      case 'update':
        return SyncOperationType.update;
      case 'delete':
        return SyncOperationType.delete;
      default:
        throw ArgumentError('Unknown sync operation type: $value');
    }
  }
}

extension SyncEntityTypeExtension on SyncEntityType {
  String get value {
    switch (this) {
      case SyncEntityType.project:
        return 'project';
      case SyncEntityType.task:
        return 'task';
      case SyncEntityType.comment:
        return 'comment';
    }
  }

  static SyncEntityType fromString(String value) {
    switch (value) {
      case 'project':
        return SyncEntityType.project;
      case 'task':
        return SyncEntityType.task;
      case 'comment':
        return SyncEntityType.comment;
      default:
        throw ArgumentError('Unknown sync entity type: $value');
    }
  }
}

/// Represents a pending sync operation
class SyncOperation {
  final int? id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncOperation({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  /// Maximum retry attempts before giving up
  static const int maxRetries = 5;

  /// Check if operation should be retried
  bool get shouldRetry => retryCount < maxRetries;

  /// Calculate backoff delay based on retry count
  Duration get backoffDelay {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    return Duration(seconds: 1 << retryCount);
  }
}
