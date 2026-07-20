// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApiKey _$ApiKeyFromJson(Map<String, dynamic> json) {
  return _ApiKey.fromJson(json);
}

/// @nodoc
mixin _$ApiKey {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'key_prefix')
  String get keyPrefix => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_used_at')
  DateTime? get lastUsedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ApiKey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApiKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApiKeyCopyWith<ApiKey> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiKeyCopyWith<$Res> {
  factory $ApiKeyCopyWith(ApiKey value, $Res Function(ApiKey) then) =
      _$ApiKeyCopyWithImpl<$Res, ApiKey>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'key_prefix') String keyPrefix,
      String name,
      @JsonKey(name: 'last_used_at') DateTime? lastUsedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$ApiKeyCopyWithImpl<$Res, $Val extends ApiKey>
    implements $ApiKeyCopyWith<$Res> {
  _$ApiKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApiKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? keyPrefix = null,
    Object? name = null,
    Object? lastUsedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      keyPrefix: null == keyPrefix
          ? _value.keyPrefix
          : keyPrefix // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedAt: freezed == lastUsedAt
          ? _value.lastUsedAt
          : lastUsedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApiKeyImplCopyWith<$Res> implements $ApiKeyCopyWith<$Res> {
  factory _$$ApiKeyImplCopyWith(
          _$ApiKeyImpl value, $Res Function(_$ApiKeyImpl) then) =
      __$$ApiKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'key_prefix') String keyPrefix,
      String name,
      @JsonKey(name: 'last_used_at') DateTime? lastUsedAt,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$ApiKeyImplCopyWithImpl<$Res>
    extends _$ApiKeyCopyWithImpl<$Res, _$ApiKeyImpl>
    implements _$$ApiKeyImplCopyWith<$Res> {
  __$$ApiKeyImplCopyWithImpl(
      _$ApiKeyImpl _value, $Res Function(_$ApiKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApiKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? keyPrefix = null,
    Object? name = null,
    Object? lastUsedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ApiKeyImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      keyPrefix: null == keyPrefix
          ? _value.keyPrefix
          : keyPrefix // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsedAt: freezed == lastUsedAt
          ? _value.lastUsedAt
          : lastUsedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApiKeyImpl implements _ApiKey {
  const _$ApiKeyImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'key_prefix') required this.keyPrefix,
      required this.name,
      @JsonKey(name: 'last_used_at') this.lastUsedAt,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$ApiKeyImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApiKeyImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'key_prefix')
  final String keyPrefix;
  @override
  final String name;
  @override
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ApiKey(id: $id, userId: $userId, keyPrefix: $keyPrefix, name: $name, lastUsedAt: $lastUsedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiKeyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.keyPrefix, keyPrefix) ||
                other.keyPrefix == keyPrefix) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.lastUsedAt, lastUsedAt) ||
                other.lastUsedAt == lastUsedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, userId, keyPrefix, name, lastUsedAt, createdAt);

  /// Create a copy of ApiKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiKeyImplCopyWith<_$ApiKeyImpl> get copyWith =>
      __$$ApiKeyImplCopyWithImpl<_$ApiKeyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApiKeyImplToJson(
      this,
    );
  }
}

abstract class _ApiKey implements ApiKey {
  const factory _ApiKey(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'key_prefix') required final String keyPrefix,
      required final String name,
      @JsonKey(name: 'last_used_at') final DateTime? lastUsedAt,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$ApiKeyImpl;

  factory _ApiKey.fromJson(Map<String, dynamic> json) = _$ApiKeyImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'key_prefix')
  String get keyPrefix;
  @override
  String get name;
  @override
  @JsonKey(name: 'last_used_at')
  DateTime? get lastUsedAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of ApiKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiKeyImplCopyWith<_$ApiKeyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
