final class BackupArchive {
  BackupArchive({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required List<BackupProject> projects,
  }) : projects = List.unmodifiable(projects);

  final String version;
  final DateTime exportedAt;
  final String appVersion;
  final List<BackupProject> projects;

  @override
  bool operator ==(Object other) =>
      other is BackupArchive &&
      version == other.version &&
      exportedAt == other.exportedAt &&
      appVersion == other.appVersion &&
      _listsEqual(projects, other.projects);

  @override
  int get hashCode =>
      Object.hash(version, exportedAt, appVersion, Object.hashAll(projects));
}

final class BackupProject {
  BackupProject({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isInbox = false,
    this.sortOrder = 0,
    List<BackupTask> tasks = const [],
  }) : tasks = List.unmodifiable(tasks);

  final String id;
  final String name;
  final String color;
  final String icon;
  final bool isInbox;
  final int sortOrder;
  final List<BackupTask> tasks;

  @override
  bool operator ==(Object other) =>
      other is BackupProject &&
      id == other.id &&
      name == other.name &&
      color == other.color &&
      icon == other.icon &&
      isInbox == other.isInbox &&
      sortOrder == other.sortOrder &&
      _listsEqual(tasks, other.tasks);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        color,
        icon,
        isInbox,
        sortOrder,
        Object.hashAll(tasks),
      );
}

final class BackupTask {
  BackupTask({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 0,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
    this.recurrenceRule,
    this.recurrenceAnchorDate,
    List<BackupTask> subtasks = const [],
    List<BackupComment> comments = const [],
  })  : subtasks = List.unmodifiable(subtasks),
        comments = List.unmodifiable(comments);

  final String id;
  final String title;
  final String? description;
  final String? dueDate;
  final int priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final String? recurrenceRule;
  final String? recurrenceAnchorDate;
  final List<BackupTask> subtasks;
  final List<BackupComment> comments;

  @override
  bool operator ==(Object other) =>
      other is BackupTask &&
      id == other.id &&
      title == other.title &&
      description == other.description &&
      dueDate == other.dueDate &&
      priority == other.priority &&
      isCompleted == other.isCompleted &&
      completedAt == other.completedAt &&
      sortOrder == other.sortOrder &&
      recurrenceRule == other.recurrenceRule &&
      recurrenceAnchorDate == other.recurrenceAnchorDate &&
      _listsEqual(subtasks, other.subtasks) &&
      _listsEqual(comments, other.comments);

  @override
  int get hashCode => Object.hash(
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
        Object.hashAll(subtasks),
        Object.hashAll(comments),
      );
}

final class BackupComment {
  const BackupComment({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is BackupComment &&
      id == other.id &&
      content == other.content &&
      createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, content, createdAt);
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
