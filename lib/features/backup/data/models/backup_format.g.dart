// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_format.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupDataImpl _$$BackupDataImplFromJson(Map<String, dynamic> json) =>
    _$BackupDataImpl(
      version: json['version'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      appVersion: json['appVersion'] as String,
      projects: (json['projects'] as List<dynamic>)
          .map((e) => BackupProject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BackupDataImplToJson(_$BackupDataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'exportedAt': instance.exportedAt.toIso8601String(),
      'appVersion': instance.appVersion,
      'projects': instance.projects,
    };

_$BackupProjectImpl _$$BackupProjectImplFromJson(Map<String, dynamic> json) =>
    _$BackupProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      isInbox: json['is_inbox'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => BackupTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BackupProjectImplToJson(_$BackupProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
      'is_inbox': instance.isInbox,
      'sort_order': instance.sortOrder,
      'tasks': instance.tasks,
    };

_$BackupTaskImpl _$$BackupTaskImplFromJson(Map<String, dynamic> json) =>
    _$BackupTaskImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceAnchorDate: json['recurrence_anchor_date'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => BackupTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => BackupComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BackupTaskImplToJson(_$BackupTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'due_date': instance.dueDate,
      'priority': instance.priority,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt?.toIso8601String(),
      'sort_order': instance.sortOrder,
      'recurrence_rule': instance.recurrenceRule,
      'recurrence_anchor_date': instance.recurrenceAnchorDate,
      'subtasks': instance.subtasks,
      'comments': instance.comments,
    };

_$BackupCommentImpl _$$BackupCommentImplFromJson(Map<String, dynamic> json) =>
    _$BackupCommentImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$BackupCommentImplToJson(_$BackupCommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
    };
