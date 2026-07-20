import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/supabase_serialization.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @Default('#6B7280') String color,
    @Default('folder') String? icon,
    @JsonKey(name: 'is_inbox') @Default(false) bool isInbox,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'default_assignee')
    @Default('manuel')
    String defaultAssignee,
    @JsonKey(name: 'agent_webhook_url') @Default('') String agentWebhookUrl,
    @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
    @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}
