// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Taskboi';

  @override
  String get tagline => 'Stay organized. Get things done.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToGetStarted => 'Sign up to get started';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get or => 'or';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get accountCreatedVerifyEmail =>
      'Account created! Please check your email to verify.';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get pleaseEnterAPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutSubtitle => 'Sign out of your account';

  @override
  String get user => 'User';

  @override
  String get inbox => 'Inbox';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get thisWeekend => 'This Weekend';

  @override
  String get nextWeek => 'Next Week';

  @override
  String get projects => 'Projects';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get createProject => 'Create project';

  @override
  String get editProject => 'Edit Project';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String deleteProjectConfirmation(String projectName) {
    return 'Are you sure you want to delete \"$projectName\"? All tasks in this project will also be deleted.';
  }

  @override
  String get projectName => 'Project name';

  @override
  String get enterProjectName => 'Enter project name';

  @override
  String get pleaseEnterProjectName => 'Please enter a project name';

  @override
  String get color => 'Color';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get done => 'Done';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. If you leave now, they will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get settings => 'Settings';

  @override
  String get integrations => 'Integrations';

  @override
  String get apiKeys => 'API Keys';

  @override
  String get mcpIntegration => 'MCP Integration';

  @override
  String get apiKeysSubtitle => 'MCP Integration for AI assistants';

  @override
  String get generateNewKey => 'Generate New Key';

  @override
  String get generateApiKey => 'Generate API Key';

  @override
  String get mcpIntegrationDescription =>
      'Generate an API key to connect Taskboi with AI assistants like Claude or Cursor using the Model Context Protocol (MCP).';

  @override
  String get newApiKeyCreated => 'New API Key Created';

  @override
  String get copyKeyNow => 'Copy this key now - it won\'t be shown again!';

  @override
  String get apiKeyCopied => 'API key copied to clipboard';

  @override
  String get apiKeyDeleted => 'API key deleted';

  @override
  String get apiKeyDeleteFailed =>
      'API key could not be deleted. Please try again.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get noApiKeysYet => 'No API keys yet';

  @override
  String get createOneToConnect => 'Create one to connect with MCP clients';

  @override
  String get deleteApiKey => 'Delete API Key';

  @override
  String deleteApiKeyConfirmation(String keyName) {
    return 'Are you sure you want to delete \"$keyName\"?\n\nAny applications using this key will lose access.';
  }

  @override
  String get keyName => 'Key Name';

  @override
  String get keyNameHint => 'e.g., Claude Desktop, Cursor';

  @override
  String get giveKeyName => 'Give this key a name to identify it later.';

  @override
  String get generate => 'Generate';

  @override
  String createdDate(String date) {
    return 'Created $date';
  }

  @override
  String lastUsedDate(String date) {
    return 'Last used $date';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get mode => 'Mode';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose your preferred language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get data => 'Data';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupSubtitle => 'Save all data to a JSON file';

  @override
  String get exporting => 'Exporting...';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importBackupSubtitle => 'Restore data from a JSON file';

  @override
  String get importing => 'Importing...';

  @override
  String get importBackupWarning =>
      'This will replace all your existing data with the backup data. This action cannot be undone.\n\nAre you sure you want to continue?';

  @override
  String get replaceData => 'Replace Data';

  @override
  String get backupExportedSuccessfully => 'Backup exported successfully';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String importedProjectsAndTasks(int projectCount, int taskCount) {
    return 'Imported $projectCount projects and $taskCount tasks';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get account => 'Account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get couldNotOpenDeleteAccountPage =>
      'Could not open delete account page';

  @override
  String get about => 'About';

  @override
  String get aboutTaskboi => 'About Taskboi';

  @override
  String get aboutSubtitle => 'Version, privacy policy, and more';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get appDescription =>
      'A simple, beautiful task management app to help you stay organized and productive.';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String allRightsReserved(int year) {
    return '© $year Taskboi. All rights reserved.';
  }

  @override
  String get newTask => 'New Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get newSubtask => 'New Subtask';

  @override
  String get editSubtask => 'Edit Subtask';

  @override
  String get taskName => 'Task name';

  @override
  String get subtaskName => 'Subtask name';

  @override
  String get description => 'Description';

  @override
  String get pleaseEnterTaskName => 'Please enter a task name';

  @override
  String get project => 'Project';

  @override
  String get dueDate => 'Due date';

  @override
  String get addDueDate => 'Add due date';

  @override
  String get date => 'Date';

  @override
  String get pickADate => 'Pick a date';

  @override
  String get pickATime => 'Pick a time';

  @override
  String get removeTime => 'Remove time';

  @override
  String get removeDateAndRecurrence => 'Remove date & recurrence';

  @override
  String get priority => 'Priority';

  @override
  String get addPriority => 'Add priority';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNone => 'None';

  @override
  String priorityN(int n) {
    return 'Priority $n';
  }

  @override
  String get deleteTask => 'Delete task';

  @override
  String get deleteSubtask => 'Delete subtask';

  @override
  String deleteTaskConfirmation(String taskTitle) {
    return 'Are you sure you want to delete \"$taskTitle\"?';
  }

  @override
  String deleteTaskWithSubtasks(String taskTitle, int subtaskCount) {
    return 'Are you sure you want to delete \"$taskTitle\"?\n\nThis will also delete $subtaskCount subtask(s).';
  }

  @override
  String taskDeleted(String taskTitle) {
    return '\"$taskTitle\" deleted';
  }

  @override
  String taskCompleted(String taskTitle) {
    return '\"$taskTitle\" completed';
  }

  @override
  String taskMarkedIncomplete(String taskTitle) {
    return '\"$taskTitle\" marked incomplete';
  }

  @override
  String taskMovedTo(String taskTitle, String projectName) {
    return '\"$taskTitle\" moved to $projectName';
  }

  @override
  String get undo => 'Undo';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get moveToProject => 'Move to Project';

  @override
  String get setPriority => 'Set Priority';

  @override
  String get addSubtask => 'Add Subtask';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get markIncomplete => 'Mark Incomplete';

  @override
  String deleteWithSubtasks(int count) {
    return 'Delete ($count subtasks)';
  }

  @override
  String get subtasks => 'Subtasks';

  @override
  String subtasksCount(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get addASubtask => 'Add a subtask';

  @override
  String get parentTask => 'Parent Task';

  @override
  String get errorLoadingProjects => 'Error loading projects';

  @override
  String get comments => 'Comments';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get addComment => 'Add a comment...';

  @override
  String get commentCreateFailed =>
      'Couldn\'t add the comment. Please try again.';

  @override
  String get commentAttachmentFailed =>
      'The comment was added, but its images couldn\'t be uploaded. Try again to finish adding them.';

  @override
  String get imagePickerFailed =>
      'Couldn\'t open the image picker. Please try again.';

  @override
  String get editComment => 'Edit comment...';

  @override
  String get sortTasks => 'Sort tasks';

  @override
  String get sortManual => 'Manual';

  @override
  String get sortPriority => 'Priority';

  @override
  String get sortDueDate => 'Due date';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortDateAdded => 'Date added';

  @override
  String get showCompleted => 'Show completed';

  @override
  String get hideCompleted => 'Hide completed';

  @override
  String completedCount(int count) {
    return 'Completed ($count)';
  }

  @override
  String get noTasksDueToday => 'No tasks due today';

  @override
  String get noUpcomingTasks => 'No upcoming tasks';

  @override
  String get yourInboxIsEmpty => 'Your inbox is empty';

  @override
  String get noTasksInProject => 'No tasks in this project';

  @override
  String get tapToAddTask => 'Tap + to add a task';

  @override
  String get loading => 'Loading...';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get recurrenceNone => 'None';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceWeekdays => 'Weekdays';

  @override
  String recurrenceEveryNDays(int n) {
    return 'Every $n days';
  }

  @override
  String recurrenceEveryNWeeks(int n) {
    return 'Every $n weeks';
  }

  @override
  String recurrenceEveryNMonths(int n) {
    return 'Every $n months';
  }

  @override
  String recurrenceWeeklyOn(String days) {
    return 'Weekly on $days';
  }

  @override
  String get recurring => 'Recurring';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String syncing(int count) {
    return 'Syncing $count';
  }

  @override
  String get allChangesSynced => 'All changes synced';

  @override
  String changesPendingSync(int count) {
    return '$count changes pending sync';
  }

  @override
  String get checking => 'Checking...';

  @override
  String get changesWillSyncWhenOnline =>
      'Changes will sync when you go online';

  @override
  String get noDate => 'No Date';

  @override
  String todayYesterday(String time) {
    return 'Today $time';
  }

  @override
  String yesterdayTime(String time) {
    return 'Yesterday $time';
  }

  @override
  String get getTheApp => 'Get the app';

  @override
  String get androidAppAvailable =>
      'Taskboi is available on Android for a better mobile experience!';

  @override
  String pageNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';
}
