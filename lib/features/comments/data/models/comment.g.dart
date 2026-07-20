// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentImpl _$$CommentImplFromJson(Map<String, dynamic> json) =>
    _$CommentImpl(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      images:
          json['images'] == null ? const [] : _imagesFromJson(json['images']),
    );

Map<String, dynamic> _$$CommentImplToJson(_$CommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'task_id': instance.taskId,
      'user_id': instance.userId,
      'content': instance.content,
      'created_at': utcIso(instance.createdAt),
      'updated_at': utcIso(instance.updatedAt),
      'images': _imagesToJson(instance.images),
    };
