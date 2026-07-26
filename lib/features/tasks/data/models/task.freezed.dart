// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  String? get parentId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date', toJson: dateOnly)
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_time')
  String? get dueTime => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at', toJson: utcIso)
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_parent_id')
  String? get recurrenceParentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
  DateTime? get recurrenceAnchorDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at', toJson: utcIso)
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at', toJson: utcIso)
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'project_id') String projectId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'parent_id') String? parentId,
      String title,
      String? description,
      @JsonKey(name: 'due_date', toJson: dateOnly) DateTime? dueDate,
      @JsonKey(name: 'due_time') String? dueTime,
      int priority,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'completed_at', toJson: utcIso) DateTime? completedAt,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_parent_id') String? recurrenceParentId,
      @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
      DateTime? recurrenceAnchorDate,
      @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt});
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? userId = null,
    Object? parentId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? dueTime = freezed,
    Object? priority = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? sortOrder = null,
    Object? recurrenceRule = freezed,
    Object? recurrenceParentId = freezed,
    Object? recurrenceAnchorDate = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueTime: freezed == dueTime
          ? _value.dueTime
          : dueTime // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceParentId: freezed == recurrenceParentId
          ? _value.recurrenceParentId
          : recurrenceParentId // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceAnchorDate: freezed == recurrenceAnchorDate
          ? _value.recurrenceAnchorDate
          : recurrenceAnchorDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
          _$TaskImpl value, $Res Function(_$TaskImpl) then) =
      __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'project_id') String projectId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'parent_id') String? parentId,
      String title,
      String? description,
      @JsonKey(name: 'due_date', toJson: dateOnly) DateTime? dueDate,
      @JsonKey(name: 'due_time') String? dueTime,
      int priority,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'completed_at', toJson: utcIso) DateTime? completedAt,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_parent_id') String? recurrenceParentId,
      @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
      DateTime? recurrenceAnchorDate,
      @JsonKey(name: 'created_at', toJson: utcIso) DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) DateTime? updatedAt});
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? projectId = null,
    Object? userId = null,
    Object? parentId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? dueTime = freezed,
    Object? priority = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? sortOrder = null,
    Object? recurrenceRule = freezed,
    Object? recurrenceParentId = freezed,
    Object? recurrenceAnchorDate = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: null == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dueTime: freezed == dueTime
          ? _value.dueTime
          : dueTime // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceParentId: freezed == recurrenceParentId
          ? _value.recurrenceParentId
          : recurrenceParentId // ignore: cast_nullable_to_non_nullable
              as String?,
      recurrenceAnchorDate: freezed == recurrenceAnchorDate
          ? _value.recurrenceAnchorDate
          : recurrenceAnchorDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$TaskImpl extends _Task {
  const _$TaskImpl(
      {required this.id,
      @JsonKey(name: 'project_id') required this.projectId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'parent_id') this.parentId,
      required this.title,
      this.description,
      @JsonKey(name: 'due_date', toJson: dateOnly) this.dueDate,
      @JsonKey(name: 'due_time') this.dueTime,
      this.priority = 0,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'completed_at', toJson: utcIso) this.completedAt,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
      @JsonKey(name: 'recurrence_parent_id') this.recurrenceParentId,
      @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
      this.recurrenceAnchorDate,
      @JsonKey(name: 'created_at', toJson: utcIso) this.createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso) this.updatedAt})
      : super._();

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'project_id')
  final String projectId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'due_date', toJson: dateOnly)
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'due_time')
  final String? dueTime;
  @override
  @JsonKey()
  final int priority;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'completed_at', toJson: utcIso)
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_parent_id')
  final String? recurrenceParentId;
  @override
  @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
  final DateTime? recurrenceAnchorDate;
  @override
  @JsonKey(name: 'created_at', toJson: utcIso)
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at', toJson: utcIso)
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Task(id: $id, projectId: $projectId, userId: $userId, parentId: $parentId, title: $title, description: $description, dueDate: $dueDate, dueTime: $dueTime, priority: $priority, isCompleted: $isCompleted, completedAt: $completedAt, sortOrder: $sortOrder, recurrenceRule: $recurrenceRule, recurrenceParentId: $recurrenceParentId, recurrenceAnchorDate: $recurrenceAnchorDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.dueTime, dueTime) || other.dueTime == dueTime) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.recurrenceParentId, recurrenceParentId) ||
                other.recurrenceParentId == recurrenceParentId) &&
            (identical(other.recurrenceAnchorDate, recurrenceAnchorDate) ||
                other.recurrenceAnchorDate == recurrenceAnchorDate) &&
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
      projectId,
      userId,
      parentId,
      title,
      description,
      dueDate,
      dueTime,
      priority,
      isCompleted,
      completedAt,
      sortOrder,
      recurrenceRule,
      recurrenceParentId,
      recurrenceAnchorDate,
      createdAt,
      updatedAt);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(
      this,
    );
  }
}

abstract class _Task extends Task {
  const factory _Task(
      {required final String id,
      @JsonKey(name: 'project_id') required final String projectId,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'parent_id') final String? parentId,
      required final String title,
      final String? description,
      @JsonKey(name: 'due_date', toJson: dateOnly) final DateTime? dueDate,
      @JsonKey(name: 'due_time') final String? dueTime,
      final int priority,
      @JsonKey(name: 'is_completed') final bool isCompleted,
      @JsonKey(name: 'completed_at', toJson: utcIso)
      final DateTime? completedAt,
      @JsonKey(name: 'sort_order') final int sortOrder,
      @JsonKey(name: 'recurrence_rule') final String? recurrenceRule,
      @JsonKey(name: 'recurrence_parent_id') final String? recurrenceParentId,
      @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
      final DateTime? recurrenceAnchorDate,
      @JsonKey(name: 'created_at', toJson: utcIso) final DateTime? createdAt,
      @JsonKey(name: 'updated_at', toJson: utcIso)
      final DateTime? updatedAt}) = _$TaskImpl;
  const _Task._() : super._();

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'project_id')
  String get projectId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'due_date', toJson: dateOnly)
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'due_time')
  String? get dueTime;
  @override
  int get priority;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'completed_at', toJson: utcIso)
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_parent_id')
  String? get recurrenceParentId;
  @override
  @JsonKey(name: 'recurrence_anchor_date', toJson: dateOnly)
  DateTime? get recurrenceAnchorDate;
  @override
  @JsonKey(name: 'created_at', toJson: utcIso)
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at', toJson: utcIso)
  DateTime? get updatedAt;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
