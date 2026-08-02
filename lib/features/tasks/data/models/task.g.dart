// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      dueTime: json['due_time'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceParentId: json['recurrence_parent_id'] as String?,
      recurrenceAnchorDate: json['recurrence_anchor_date'] == null
          ? null
          : DateTime.parse(json['recurrence_anchor_date'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'user_id': instance.userId,
      'parent_id': instance.parentId,
      'title': instance.title,
      'description': instance.description,
      'due_date': civilDateIso8601(instance.dueDate),
      'due_time': instance.dueTime,
      'priority': instance.priority,
      'is_completed': instance.isCompleted,
      'completed_at': utcIso8601(instance.completedAt),
      'sort_order': instance.sortOrder,
      'recurrence_rule': instance.recurrenceRule,
      'recurrence_parent_id': instance.recurrenceParentId,
      'recurrence_anchor_date': civilDateIso8601(instance.recurrenceAnchorDate),
      'created_at': utcIso8601(instance.createdAt),
      'updated_at': utcIso8601(instance.updatedAt),
    };
