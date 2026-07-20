// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6B7280',
      icon: json['icon'] as String? ?? 'folder',
      isInbox: json['is_inbox'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      defaultAssignee: json['default_assignee'] as String? ?? 'manuel',
      agentWebhookUrl: json['agent_webhook_url'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
      'is_inbox': instance.isInbox,
      'sort_order': instance.sortOrder,
      'default_assignee': instance.defaultAssignee,
      'agent_webhook_url': instance.agentWebhookUrl,
      'created_at': utcIso(instance.createdAt),
      'updated_at': utcIso(instance.updatedAt),
    };
