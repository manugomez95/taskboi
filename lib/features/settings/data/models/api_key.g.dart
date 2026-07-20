// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApiKeyImpl _$$ApiKeyImplFromJson(Map<String, dynamic> json) => _$ApiKeyImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      keyPrefix: json['key_prefix'] as String,
      name: json['name'] as String,
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ApiKeyImplToJson(_$ApiKeyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'key_prefix': instance.keyPrefix,
      'name': instance.name,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
