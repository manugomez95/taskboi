import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskboi_task_engine/taskboi_task_engine.dart' show utcIso8601;

part 'comment.freezed.dart';
part 'comment.g.dart';

// Compatibility name embedded in existing Freezed output.
const utcIso = utcIso8601;

// ── JSON helpers for images ──────────────────────────────────────────
// Supabase stores images as TEXT[]; Drift stores them as a JSON string.
// Both arrive as a List<dynamic> or a JSON-encoded string.
List<String> _imagesFromJson(dynamic value) {
  if (value == null) return [];
  if (value is String) {
    if (value.isEmpty || value == '[]') return [];
    final decoded = jsonDecode(value);
    if (decoded is List) return decoded.cast<String>();
    return [];
  }
  if (value is List) return value.cast<String>();
  return [];
}

List<dynamic> _imagesToJson(List<String> images) => images;

@freezed
class Comment with _$Comment {
  const Comment._();

  const factory Comment({
    required String id,
    @JsonKey(name: 'task_id') required String taskId,
    @JsonKey(name: 'user_id') required String userId,
    required String content,
    @JsonKey(name: 'created_at', toJson: utcIso8601) DateTime? createdAt,
    @JsonKey(name: 'updated_at', toJson: utcIso8601) DateTime? updatedAt,
    @JsonKey(name: 'images', fromJson: _imagesFromJson, toJson: _imagesToJson)
    @Default([])
    List<String> images,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}
