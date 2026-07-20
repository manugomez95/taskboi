// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_format.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BackupData _$BackupDataFromJson(Map<String, dynamic> json) {
  return _BackupData.fromJson(json);
}

/// @nodoc
mixin _$BackupData {
  String get version => throw _privateConstructorUsedError;
  DateTime get exportedAt => throw _privateConstructorUsedError;
  String get appVersion => throw _privateConstructorUsedError;
  List<BackupProject> get projects => throw _privateConstructorUsedError;

  /// Serializes this BackupData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupDataCopyWith<BackupData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupDataCopyWith<$Res> {
  factory $BackupDataCopyWith(
          BackupData value, $Res Function(BackupData) then) =
      _$BackupDataCopyWithImpl<$Res, BackupData>;
  @useResult
  $Res call(
      {String version,
      DateTime exportedAt,
      String appVersion,
      List<BackupProject> projects});
}

/// @nodoc
class _$BackupDataCopyWithImpl<$Res, $Val extends BackupData>
    implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportedAt = null,
    Object? appVersion = null,
    Object? projects = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportedAt: null == exportedAt
          ? _value.exportedAt
          : exportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      projects: null == projects
          ? _value.projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<BackupProject>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupDataImplCopyWith<$Res>
    implements $BackupDataCopyWith<$Res> {
  factory _$$BackupDataImplCopyWith(
          _$BackupDataImpl value, $Res Function(_$BackupDataImpl) then) =
      __$$BackupDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      DateTime exportedAt,
      String appVersion,
      List<BackupProject> projects});
}

/// @nodoc
class __$$BackupDataImplCopyWithImpl<$Res>
    extends _$BackupDataCopyWithImpl<$Res, _$BackupDataImpl>
    implements _$$BackupDataImplCopyWith<$Res> {
  __$$BackupDataImplCopyWithImpl(
      _$BackupDataImpl _value, $Res Function(_$BackupDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportedAt = null,
    Object? appVersion = null,
    Object? projects = null,
  }) {
    return _then(_$BackupDataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportedAt: null == exportedAt
          ? _value.exportedAt
          : exportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      projects: null == projects
          ? _value._projects
          : projects // ignore: cast_nullable_to_non_nullable
              as List<BackupProject>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupDataImpl implements _BackupData {
  const _$BackupDataImpl(
      {required this.version,
      required this.exportedAt,
      required this.appVersion,
      required final List<BackupProject> projects})
      : _projects = projects;

  factory _$BackupDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupDataImplFromJson(json);

  @override
  final String version;
  @override
  final DateTime exportedAt;
  @override
  final String appVersion;
  final List<BackupProject> _projects;
  @override
  List<BackupProject> get projects {
    if (_projects is EqualUnmodifiableListView) return _projects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_projects);
  }

  @override
  String toString() {
    return 'BackupData(version: $version, exportedAt: $exportedAt, appVersion: $appVersion, projects: $projects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupDataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.exportedAt, exportedAt) ||
                other.exportedAt == exportedAt) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            const DeepCollectionEquality().equals(other._projects, _projects));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, exportedAt, appVersion,
      const DeepCollectionEquality().hash(_projects));

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupDataImplCopyWith<_$BackupDataImpl> get copyWith =>
      __$$BackupDataImplCopyWithImpl<_$BackupDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupDataImplToJson(
      this,
    );
  }
}

abstract class _BackupData implements BackupData {
  const factory _BackupData(
      {required final String version,
      required final DateTime exportedAt,
      required final String appVersion,
      required final List<BackupProject> projects}) = _$BackupDataImpl;

  factory _BackupData.fromJson(Map<String, dynamic> json) =
      _$BackupDataImpl.fromJson;

  @override
  String get version;
  @override
  DateTime get exportedAt;
  @override
  String get appVersion;
  @override
  List<BackupProject> get projects;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupDataImplCopyWith<_$BackupDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BackupProject _$BackupProjectFromJson(Map<String, dynamic> json) {
  return _BackupProject.fromJson(json);
}

/// @nodoc
mixin _$BackupProject {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_inbox')
  bool get isInbox => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  List<BackupTask> get tasks => throw _privateConstructorUsedError;

  /// Serializes this BackupProject to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupProjectCopyWith<BackupProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupProjectCopyWith<$Res> {
  factory $BackupProjectCopyWith(
          BackupProject value, $Res Function(BackupProject) then) =
      _$BackupProjectCopyWithImpl<$Res, BackupProject>;
  @useResult
  $Res call(
      {String id,
      String name,
      String color,
      String icon,
      @JsonKey(name: 'is_inbox') bool isInbox,
      @JsonKey(name: 'sort_order') int sortOrder,
      List<BackupTask> tasks});
}

/// @nodoc
class _$BackupProjectCopyWithImpl<$Res, $Val extends BackupProject>
    implements $BackupProjectCopyWith<$Res> {
  _$BackupProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? icon = null,
    Object? isInbox = null,
    Object? sortOrder = null,
    Object? tasks = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      isInbox: null == isInbox
          ? _value.isInbox
          : isInbox // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<BackupTask>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupProjectImplCopyWith<$Res>
    implements $BackupProjectCopyWith<$Res> {
  factory _$$BackupProjectImplCopyWith(
          _$BackupProjectImpl value, $Res Function(_$BackupProjectImpl) then) =
      __$$BackupProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String color,
      String icon,
      @JsonKey(name: 'is_inbox') bool isInbox,
      @JsonKey(name: 'sort_order') int sortOrder,
      List<BackupTask> tasks});
}

/// @nodoc
class __$$BackupProjectImplCopyWithImpl<$Res>
    extends _$BackupProjectCopyWithImpl<$Res, _$BackupProjectImpl>
    implements _$$BackupProjectImplCopyWith<$Res> {
  __$$BackupProjectImplCopyWithImpl(
      _$BackupProjectImpl _value, $Res Function(_$BackupProjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = null,
    Object? icon = null,
    Object? isInbox = null,
    Object? sortOrder = null,
    Object? tasks = null,
  }) {
    return _then(_$BackupProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      isInbox: null == isInbox
          ? _value.isInbox
          : isInbox // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<BackupTask>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupProjectImpl implements _BackupProject {
  const _$BackupProjectImpl(
      {required this.id,
      required this.name,
      required this.color,
      required this.icon,
      @JsonKey(name: 'is_inbox') this.isInbox = false,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      final List<BackupTask> tasks = const []})
      : _tasks = tasks;

  factory _$BackupProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String color;
  @override
  final String icon;
  @override
  @JsonKey(name: 'is_inbox')
  final bool isInbox;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  final List<BackupTask> _tasks;
  @override
  @JsonKey()
  List<BackupTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  String toString() {
    return 'BackupProject(id: $id, name: $name, color: $color, icon: $icon, isInbox: $isInbox, sortOrder: $sortOrder, tasks: $tasks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.isInbox, isInbox) || other.isInbox == isInbox) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, color, icon, isInbox,
      sortOrder, const DeepCollectionEquality().hash(_tasks));

  /// Create a copy of BackupProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupProjectImplCopyWith<_$BackupProjectImpl> get copyWith =>
      __$$BackupProjectImplCopyWithImpl<_$BackupProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupProjectImplToJson(
      this,
    );
  }
}

abstract class _BackupProject implements BackupProject {
  const factory _BackupProject(
      {required final String id,
      required final String name,
      required final String color,
      required final String icon,
      @JsonKey(name: 'is_inbox') final bool isInbox,
      @JsonKey(name: 'sort_order') final int sortOrder,
      final List<BackupTask> tasks}) = _$BackupProjectImpl;

  factory _BackupProject.fromJson(Map<String, dynamic> json) =
      _$BackupProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get color;
  @override
  String get icon;
  @override
  @JsonKey(name: 'is_inbox')
  bool get isInbox;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  List<BackupTask> get tasks;

  /// Create a copy of BackupProject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupProjectImplCopyWith<_$BackupProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BackupTask _$BackupTaskFromJson(Map<String, dynamic> json) {
  return _BackupTask.fromJson(json);
}

/// @nodoc
mixin _$BackupTask {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  String? get dueDate => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_anchor_date')
  String? get recurrenceAnchorDate => throw _privateConstructorUsedError;
  List<BackupTask> get subtasks => throw _privateConstructorUsedError;
  List<BackupComment> get comments => throw _privateConstructorUsedError;

  /// Serializes this BackupTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupTaskCopyWith<BackupTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupTaskCopyWith<$Res> {
  factory $BackupTaskCopyWith(
          BackupTask value, $Res Function(BackupTask) then) =
      _$BackupTaskCopyWithImpl<$Res, BackupTask>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      @JsonKey(name: 'due_date') String? dueDate,
      int priority,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_anchor_date') String? recurrenceAnchorDate,
      List<BackupTask> subtasks,
      List<BackupComment> comments});
}

/// @nodoc
class _$BackupTaskCopyWithImpl<$Res, $Val extends BackupTask>
    implements $BackupTaskCopyWith<$Res> {
  _$BackupTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? priority = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? sortOrder = null,
    Object? recurrenceRule = freezed,
    Object? recurrenceAnchorDate = freezed,
    Object? subtasks = null,
    Object? comments = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      recurrenceAnchorDate: freezed == recurrenceAnchorDate
          ? _value.recurrenceAnchorDate
          : recurrenceAnchorDate // ignore: cast_nullable_to_non_nullable
              as String?,
      subtasks: null == subtasks
          ? _value.subtasks
          : subtasks // ignore: cast_nullable_to_non_nullable
              as List<BackupTask>,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<BackupComment>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupTaskImplCopyWith<$Res>
    implements $BackupTaskCopyWith<$Res> {
  factory _$$BackupTaskImplCopyWith(
          _$BackupTaskImpl value, $Res Function(_$BackupTaskImpl) then) =
      __$$BackupTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      @JsonKey(name: 'due_date') String? dueDate,
      int priority,
      @JsonKey(name: 'is_completed') bool isCompleted,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
      @JsonKey(name: 'recurrence_anchor_date') String? recurrenceAnchorDate,
      List<BackupTask> subtasks,
      List<BackupComment> comments});
}

/// @nodoc
class __$$BackupTaskImplCopyWithImpl<$Res>
    extends _$BackupTaskCopyWithImpl<$Res, _$BackupTaskImpl>
    implements _$$BackupTaskImplCopyWith<$Res> {
  __$$BackupTaskImplCopyWithImpl(
      _$BackupTaskImpl _value, $Res Function(_$BackupTaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? dueDate = freezed,
    Object? priority = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? sortOrder = null,
    Object? recurrenceRule = freezed,
    Object? recurrenceAnchorDate = freezed,
    Object? subtasks = null,
    Object? comments = null,
  }) {
    return _then(_$BackupTaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
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
      recurrenceAnchorDate: freezed == recurrenceAnchorDate
          ? _value.recurrenceAnchorDate
          : recurrenceAnchorDate // ignore: cast_nullable_to_non_nullable
              as String?,
      subtasks: null == subtasks
          ? _value._subtasks
          : subtasks // ignore: cast_nullable_to_non_nullable
              as List<BackupTask>,
      comments: null == comments
          ? _value._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<BackupComment>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupTaskImpl implements _BackupTask {
  const _$BackupTaskImpl(
      {required this.id,
      required this.title,
      this.description,
      @JsonKey(name: 'due_date') this.dueDate,
      this.priority = 0,
      @JsonKey(name: 'is_completed') this.isCompleted = false,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
      @JsonKey(name: 'recurrence_anchor_date') this.recurrenceAnchorDate,
      final List<BackupTask> subtasks = const [],
      final List<BackupComment> comments = const []})
      : _subtasks = subtasks,
        _comments = comments;

  factory _$BackupTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupTaskImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'due_date')
  final String? dueDate;
  @override
  @JsonKey()
  final int priority;
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_anchor_date')
  final String? recurrenceAnchorDate;
  final List<BackupTask> _subtasks;
  @override
  @JsonKey()
  List<BackupTask> get subtasks {
    if (_subtasks is EqualUnmodifiableListView) return _subtasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subtasks);
  }

  final List<BackupComment> _comments;
  @override
  @JsonKey()
  List<BackupComment> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  @override
  String toString() {
    return 'BackupTask(id: $id, title: $title, description: $description, dueDate: $dueDate, priority: $priority, isCompleted: $isCompleted, completedAt: $completedAt, sortOrder: $sortOrder, recurrenceRule: $recurrenceRule, recurrenceAnchorDate: $recurrenceAnchorDate, subtasks: $subtasks, comments: $comments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
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
            (identical(other.recurrenceAnchorDate, recurrenceAnchorDate) ||
                other.recurrenceAnchorDate == recurrenceAnchorDate) &&
            const DeepCollectionEquality().equals(other._subtasks, _subtasks) &&
            const DeepCollectionEquality().equals(other._comments, _comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      dueDate,
      priority,
      isCompleted,
      completedAt,
      sortOrder,
      recurrenceRule,
      recurrenceAnchorDate,
      const DeepCollectionEquality().hash(_subtasks),
      const DeepCollectionEquality().hash(_comments));

  /// Create a copy of BackupTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupTaskImplCopyWith<_$BackupTaskImpl> get copyWith =>
      __$$BackupTaskImplCopyWithImpl<_$BackupTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupTaskImplToJson(
      this,
    );
  }
}

abstract class _BackupTask implements BackupTask {
  const factory _BackupTask(
      {required final String id,
      required final String title,
      final String? description,
      @JsonKey(name: 'due_date') final String? dueDate,
      final int priority,
      @JsonKey(name: 'is_completed') final bool isCompleted,
      @JsonKey(name: 'completed_at') final DateTime? completedAt,
      @JsonKey(name: 'sort_order') final int sortOrder,
      @JsonKey(name: 'recurrence_rule') final String? recurrenceRule,
      @JsonKey(name: 'recurrence_anchor_date')
      final String? recurrenceAnchorDate,
      final List<BackupTask> subtasks,
      final List<BackupComment> comments}) = _$BackupTaskImpl;

  factory _BackupTask.fromJson(Map<String, dynamic> json) =
      _$BackupTaskImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'due_date')
  String? get dueDate;
  @override
  int get priority;
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule;
  @override
  @JsonKey(name: 'recurrence_anchor_date')
  String? get recurrenceAnchorDate;
  @override
  List<BackupTask> get subtasks;
  @override
  List<BackupComment> get comments;

  /// Create a copy of BackupTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupTaskImplCopyWith<_$BackupTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BackupComment _$BackupCommentFromJson(Map<String, dynamic> json) {
  return _BackupComment.fromJson(json);
}

/// @nodoc
mixin _$BackupComment {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BackupComment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BackupComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BackupCommentCopyWith<BackupComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupCommentCopyWith<$Res> {
  factory $BackupCommentCopyWith(
          BackupComment value, $Res Function(BackupComment) then) =
      _$BackupCommentCopyWithImpl<$Res, BackupComment>;
  @useResult
  $Res call(
      {String id,
      String content,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$BackupCommentCopyWithImpl<$Res, $Val extends BackupComment>
    implements $BackupCommentCopyWith<$Res> {
  _$BackupCommentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BackupComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupCommentImplCopyWith<$Res>
    implements $BackupCommentCopyWith<$Res> {
  factory _$$BackupCommentImplCopyWith(
          _$BackupCommentImpl value, $Res Function(_$BackupCommentImpl) then) =
      __$$BackupCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String content,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$BackupCommentImplCopyWithImpl<$Res>
    extends _$BackupCommentCopyWithImpl<$Res, _$BackupCommentImpl>
    implements _$$BackupCommentImplCopyWith<$Res> {
  __$$BackupCommentImplCopyWithImpl(
      _$BackupCommentImpl _value, $Res Function(_$BackupCommentImpl) _then)
      : super(_value, _then);

  /// Create a copy of BackupComment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
  }) {
    return _then(_$BackupCommentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupCommentImpl implements _BackupComment {
  const _$BackupCommentImpl(
      {required this.id,
      required this.content,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$BackupCommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupCommentImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'BackupComment(id: $id, content: $content, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, createdAt);

  /// Create a copy of BackupComment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupCommentImplCopyWith<_$BackupCommentImpl> get copyWith =>
      __$$BackupCommentImplCopyWithImpl<_$BackupCommentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupCommentImplToJson(
      this,
    );
  }
}

abstract class _BackupComment implements BackupComment {
  const factory _BackupComment(
          {required final String id,
          required final String content,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$BackupCommentImpl;

  factory _BackupComment.fromJson(Map<String, dynamic> json) =
      _$BackupCommentImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of BackupComment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BackupCommentImplCopyWith<_$BackupCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
