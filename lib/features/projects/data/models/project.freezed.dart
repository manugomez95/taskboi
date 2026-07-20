// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_inbox')
  bool get isInbox => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_assignee')
  String get defaultAssignee => throw _privateConstructorUsedError;
  @JsonKey(name: 'agent_webhook_url')
  String get agentWebhookUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', toJson: utcIso)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at', toJson: utcIso)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String name,
      String color,
      String? icon,
      @JsonKey(name: 'is_inbox') bool isInbox,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'default_assignee') String defaultAssignee,
      @JsonKey(name: 'agent_webhook_url') String agentWebhookUrl,
      @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt});
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? color = null,
    Object? icon = freezed,
    Object? isInbox = null,
    Object? sortOrder = null,
    Object? defaultAssignee = null,
    Object? agentWebhookUrl = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      isInbox: null == isInbox
          ? _value.isInbox
          : isInbox // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      defaultAssignee: null == defaultAssignee
          ? _value.defaultAssignee
          : defaultAssignee // ignore: cast_nullable_to_non_nullable
              as String,
      agentWebhookUrl: null == agentWebhookUrl
          ? _value.agentWebhookUrl
          : agentWebhookUrl // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
          _$ProjectImpl value, $Res Function(_$ProjectImpl) then) =
      __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      String name,
      String color,
      String? icon,
      @JsonKey(name: 'is_inbox') bool isInbox,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'default_assignee') String defaultAssignee,
      @JsonKey(name: 'agent_webhook_url') String agentWebhookUrl,
      @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt});
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
      _$ProjectImpl _value, $Res Function(_$ProjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? color = null,
    Object? icon = freezed,
    Object? isInbox = null,
    Object? sortOrder = null,
    Object? defaultAssignee = null,
    Object? agentWebhookUrl = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
      isInbox: null == isInbox
          ? _value.isInbox
          : isInbox // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      defaultAssignee: null == defaultAssignee
          ? _value.defaultAssignee
          : defaultAssignee // ignore: cast_nullable_to_non_nullable
              as String,
      agentWebhookUrl: null == agentWebhookUrl
          ? _value.agentWebhookUrl
          : agentWebhookUrl // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl implements _Project {
  const _$ProjectImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      required this.name,
      this.color = '#6B7280',
      this.icon = 'folder',
      @JsonKey(name: 'is_inbox') this.isInbox = false,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'default_assignee') this.defaultAssignee = 'manuel',
      @JsonKey(name: 'agent_webhook_url') this.agentWebhookUrl = '',
      @JsonKey(name: 'created_at', toJson: utcIso) this.createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) this.updatedAt});

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String name;
  @override
  @JsonKey()
  final String color;
  @override
  @JsonKey()
  final String? icon;
  @override
  @JsonKey(name: 'is_inbox')
  final bool isInbox;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'default_assignee')
  final String defaultAssignee;
  @override
  @JsonKey(name: 'agent_webhook_url')
  final String agentWebhookUrl;
  @override
  @JsonKey(name: 'created_at', toJson: utcIso)
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at', toJson: utcIso)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Project(id: $id, userId: $userId, name: $name, color: $color, icon: $icon, isInbox: $isInbox, sortOrder: $sortOrder, defaultAssignee: $defaultAssignee, agentWebhookUrl: $agentWebhookUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.isInbox, isInbox) || other.isInbox == isInbox) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.defaultAssignee, defaultAssignee) ||
                other.defaultAssignee == defaultAssignee) &&
            (identical(other.agentWebhookUrl, agentWebhookUrl) ||
                other.agentWebhookUrl == agentWebhookUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      name,
      color,
      icon,
      isInbox,
      sortOrder,
      defaultAssignee,
      agentWebhookUrl,
      createdAt,
      updatedAt);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(
      this,
    );
  }
}

abstract class _Project implements Project {
  const factory _Project(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      required final String name,
      final String color,
      final String? icon,
      @JsonKey(name: 'is_inbox') final bool isInbox,
      @JsonKey(name: 'sort_order') final int sortOrder,
      @JsonKey(name: 'default_assignee') final String defaultAssignee,
      @JsonKey(name: 'agent_webhook_url') final String agentWebhookUrl,
      @JsonKey(name: 'created_at', toJson: utcIso) final DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso)
      final DateTime? updatedAt}) = _$ProjectImpl;

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get name;
  @override
  String get color;
  @override
  String? get icon;
  @override
  @JsonKey(name: 'is_inbox')
  bool get isInbox;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'default_assignee')
  String get defaultAssignee;
  @override
  @JsonKey(name: 'agent_webhook_url')
  String get agentWebhookUrl;
  @override
  @JsonKey(name: 'created_at', toJson: utcIso)
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at', toJson: utcIso)
  DateTime? get updatedAt;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
