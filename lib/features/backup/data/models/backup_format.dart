import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_format.freezed.dart';
part 'backup_format.g.dart';

/// Root backup object containing all user data
@freezed
class BackupData with _$BackupData {
  const factory BackupData({
    required String version,
    required DateTime exportedAt,
    required String appVersion,
    required List<BackupProject> projects,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}

/// Project with nested tasks
@freezed
class BackupProject with _$BackupProject {
  const factory BackupProject({
    required String id,
    required String name,
    required String color,
    required String icon,
    @JsonKey(name: 'is_inbox') @Default(false) bool isInbox,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @Default([]) List<BackupTask> tasks,
  }) = _BackupProject;

  factory BackupProject.fromJson(Map<String, dynamic> json) =>
      _$BackupProjectFromJson(json);
}

/// Task with nested subtasks and comments
@freezed
class BackupTask with _$BackupTask {
  const factory BackupTask({
    required String id,
    required String title,
    String? description,
    @JsonKey(name: 'due_date') String? dueDate,
    @Default(0) int priority,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'recurrence_anchor_date') String? recurrenceAnchorDate,
    @Default([]) List<BackupTask> subtasks,
    @Default([]) List<BackupComment> comments,
  }) = _BackupTask;

  factory BackupTask.fromJson(Map<String, dynamic> json) =>
      _$BackupTaskFromJson(json);
}

/// Comment on a task
@freezed
class BackupComment with _$BackupComment {
  const factory BackupComment({
    required String id,
    required String content,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _BackupComment;

  factory BackupComment.fromJson(Map<String, dynamic> json) =>
      _$BackupCommentFromJson(json);
}
