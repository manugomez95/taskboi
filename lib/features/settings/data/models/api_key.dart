import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key.freezed.dart';
part 'api_key.g.dart';

@freezed
class ApiKey with _$ApiKey {
  const factory ApiKey({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'key_prefix') required String keyPrefix,
    required String name,
    @JsonKey(name: 'last_used_at') DateTime? lastUsedAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ApiKey;

  factory ApiKey.fromJson(Map<String, dynamic> json) => _$ApiKeyFromJson(json);
}
