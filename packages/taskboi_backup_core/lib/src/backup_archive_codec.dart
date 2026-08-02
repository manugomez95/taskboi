import 'dart:convert';

import 'backup_archive.dart';
import 'backup_archive_metadata.dart';

final class BackupArchiveCodec {
  const BackupArchiveCodec();

  String encode(BackupArchive archive) =>
      const JsonEncoder.withIndent('  ').convert(_archiveToJson(archive));

  BackupArchive decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid backup JSON: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object.');
    }
    final version = _string(decoded, 'version', r'$');
    if (!BackupArchiveMetadata.supports(version)) {
      throw UnsupportedBackupVersionException(version);
    }
    return BackupArchive(
      version: version,
      exportedAt: _dateTime(decoded, 'exportedAt', r'$'),
      appVersion: _string(decoded, 'appVersion', r'$'),
      projects: _objectList(decoded, 'projects', r'$')
          .indexed
          .map((entry) => _project(entry.$2, r'$.projects' '[${entry.$1}]'))
          .toList(),
    );
  }
}

Map<String, Object?> _archiveToJson(BackupArchive archive) => {
      'version': archive.version,
      'exportedAt': archive.exportedAt.toIso8601String(),
      'appVersion': archive.appVersion,
      'projects': archive.projects.map(_projectToJson).toList(),
    };

Map<String, Object?> _projectToJson(BackupProject project) => {
      'id': project.id,
      'name': project.name,
      'color': project.color,
      'icon': project.icon,
      'is_inbox': project.isInbox,
      'sort_order': project.sortOrder,
      'tasks': project.tasks.map(_taskToJson).toList(),
    };

Map<String, Object?> _taskToJson(BackupTask task) => {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'due_date': task.dueDate,
      'priority': task.priority,
      'is_completed': task.isCompleted,
      'completed_at': task.completedAt?.toIso8601String(),
      'sort_order': task.sortOrder,
      'recurrence_rule': task.recurrenceRule,
      'recurrence_anchor_date': task.recurrenceAnchorDate,
      'subtasks': task.subtasks.map(_taskToJson).toList(),
      'comments': task.comments.map(_commentToJson).toList(),
    };

Map<String, Object?> _commentToJson(BackupComment comment) => {
      'id': comment.id,
      'content': comment.content,
      'created_at': comment.createdAt.toIso8601String(),
    };

BackupProject _project(Map<String, dynamic> json, String path) => BackupProject(
      id: _string(json, 'id', path),
      name: _string(json, 'name', path),
      color: _string(json, 'color', path),
      icon: _string(json, 'icon', path),
      isInbox: _optional<bool>(json, 'is_inbox', path) ?? false,
      sortOrder: _optionalInt(json, 'sort_order', path) ?? 0,
      tasks: _optionalObjectList(json, 'tasks', path)
          .indexed
          .map((entry) => _task(entry.$2, '$path.tasks[${entry.$1}]'))
          .toList(),
    );

BackupTask _task(Map<String, dynamic> json, String path) => BackupTask(
      id: _string(json, 'id', path),
      title: _string(json, 'title', path),
      description: _optional<String>(json, 'description', path),
      dueDate: _optional<String>(json, 'due_date', path),
      priority: _optionalInt(json, 'priority', path) ?? 0,
      isCompleted: _optional<bool>(json, 'is_completed', path) ?? false,
      completedAt: _optionalDateTime(json, 'completed_at', path),
      sortOrder: _optionalInt(json, 'sort_order', path) ?? 0,
      recurrenceRule: _optional<String>(json, 'recurrence_rule', path),
      recurrenceAnchorDate:
          _optional<String>(json, 'recurrence_anchor_date', path),
      subtasks: _optionalObjectList(json, 'subtasks', path)
          .indexed
          .map((entry) => _task(entry.$2, '$path.subtasks[${entry.$1}]'))
          .toList(),
      comments: _optionalObjectList(json, 'comments', path)
          .indexed
          .map((entry) => _comment(entry.$2, '$path.comments[${entry.$1}]'))
          .toList(),
    );

BackupComment _comment(Map<String, dynamic> json, String path) => BackupComment(
      id: _string(json, 'id', path),
      content: _string(json, 'content', path),
      createdAt: _dateTime(json, 'created_at', path),
    );

String _string(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$path.$key must be a string.');
}

T? _optional<T>(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value == null) return null;
  if (value is T) return value;
  throw FormatException('$path.$key has an invalid type.');
}

int? _optionalInt(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('$path.$key must be an integer.');
}

DateTime _dateTime(Map<String, dynamic> json, String key, String path) {
  final value = _string(json, key, path);
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
  throw FormatException('$path.$key must be an ISO-8601 date-time.');
}

DateTime? _optionalDateTime(
    Map<String, dynamic> json, String key, String path) {
  if (json[key] == null) return null;
  return _dateTime(json, key, path);
}

List<Map<String, dynamic>> _objectList(
    Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('$path.$key must be a list.');
  }
  return value.indexed.map((entry) {
    if (entry.$2 is Map<String, dynamic>) {
      return entry.$2 as Map<String, dynamic>;
    }
    throw FormatException('$path.$key[${entry.$1}] must be an object.');
  }).toList();
}

List<Map<String, dynamic>> _optionalObjectList(
        Map<String, dynamic> json, String key, String path) =>
    json[key] == null ? const [] : _objectList(json, key, path);
