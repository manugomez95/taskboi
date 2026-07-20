import 'package:taskboi/l10n/generated/app_localizations.dart';

/// Available task sort options
enum TaskSortOption {
  manual,
  priority,
  dueDate,
  title,
  createdAt,
}

/// Extension to provide display labels for sort options
extension TaskSortOptionExtension on TaskSortOption {
  /// Get the localized label for this sort option
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case TaskSortOption.manual:
        return l10n.sortManual;
      case TaskSortOption.priority:
        return l10n.sortPriority;
      case TaskSortOption.dueDate:
        return l10n.sortDueDate;
      case TaskSortOption.title:
        return l10n.sortTitle;
      case TaskSortOption.createdAt:
        return l10n.sortDateAdded;
    }
  }
}
