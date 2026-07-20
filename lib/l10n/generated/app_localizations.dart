import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Taskboi'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Stay organized. Get things done.'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpToGetStarted;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @accountCreatedVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please check your email to verify.'**
  String get accountCreatedVerifyEmail;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutSubtitle;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This Weekend'**
  String get thisWeekend;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get editProject;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{projectName}\"? All tasks in this project will also be deleted.'**
  String deleteProjectConfirmation(String projectName);

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @enterProjectName.
  ///
  /// In en, this message translates to:
  /// **'Enter project name'**
  String get enterProjectName;

  /// No description provided for @pleaseEnterProjectName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a project name'**
  String get pleaseEnterProjectName;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. If you leave now, they will be lost.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @apiKeys.
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiKeys;

  /// No description provided for @mcpIntegration.
  ///
  /// In en, this message translates to:
  /// **'MCP Integration'**
  String get mcpIntegration;

  /// No description provided for @apiKeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'MCP Integration for AI assistants'**
  String get apiKeysSubtitle;

  /// No description provided for @generateNewKey.
  ///
  /// In en, this message translates to:
  /// **'Generate New Key'**
  String get generateNewKey;

  /// No description provided for @generateApiKey.
  ///
  /// In en, this message translates to:
  /// **'Generate API Key'**
  String get generateApiKey;

  /// No description provided for @mcpIntegrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate an API key to connect Taskboi with AI assistants like Claude or Cursor using the Model Context Protocol (MCP).'**
  String get mcpIntegrationDescription;

  /// No description provided for @newApiKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'New API Key Created'**
  String get newApiKeyCreated;

  /// No description provided for @copyKeyNow.
  ///
  /// In en, this message translates to:
  /// **'Copy this key now - it won\'t be shown again!'**
  String get copyKeyNow;

  /// No description provided for @apiKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'API key copied to clipboard'**
  String get apiKeyCopied;

  /// No description provided for @apiKeyDeleted.
  ///
  /// In en, this message translates to:
  /// **'API key deleted'**
  String get apiKeyDeleted;

  /// No description provided for @apiKeyDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'API key could not be deleted. Please try again.'**
  String get apiKeyDeleteFailed;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @noApiKeysYet.
  ///
  /// In en, this message translates to:
  /// **'No API keys yet'**
  String get noApiKeysYet;

  /// No description provided for @createOneToConnect.
  ///
  /// In en, this message translates to:
  /// **'Create one to connect with MCP clients'**
  String get createOneToConnect;

  /// No description provided for @deleteApiKey.
  ///
  /// In en, this message translates to:
  /// **'Delete API Key'**
  String get deleteApiKey;

  /// No description provided for @deleteApiKeyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{keyName}\"?\n\nAny applications using this key will lose access.'**
  String deleteApiKeyConfirmation(String keyName);

  /// No description provided for @keyName.
  ///
  /// In en, this message translates to:
  /// **'Key Name'**
  String get keyName;

  /// No description provided for @keyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Claude Desktop, Cursor'**
  String get keyNameHint;

  /// No description provided for @giveKeyName.
  ///
  /// In en, this message translates to:
  /// **'Give this key a name to identify it later.'**
  String get giveKeyName;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdDate(String date);

  /// No description provided for @lastUsedDate.
  ///
  /// In en, this message translates to:
  /// **'Last used {date}'**
  String lastUsedDate(String date);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all data to a JSON file'**
  String get exportBackupSubtitle;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a JSON file'**
  String get importBackupSubtitle;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @importBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace all your existing data with the backup data. This action cannot be undone.\n\nAre you sure you want to continue?'**
  String get importBackupWarning;

  /// No description provided for @replaceData.
  ///
  /// In en, this message translates to:
  /// **'Replace Data'**
  String get replaceData;

  /// No description provided for @backupExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupExportedSuccessfully;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @importedProjectsAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Imported {projectCount} projects and {taskCount} tasks'**
  String importedProjectsAndTasks(int projectCount, int taskCount);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @couldNotOpenDeleteAccountPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open delete account page'**
  String get couldNotOpenDeleteAccountPage;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTaskboi.
  ///
  /// In en, this message translates to:
  /// **'About Taskboi'**
  String get aboutTaskboi;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, privacy policy, and more'**
  String get aboutSubtitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple, beautiful task management app to help you stay organized and productive.'**
  String get appDescription;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© {year} Taskboi. All rights reserved.'**
  String allRightsReserved(int year);

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @newSubtask.
  ///
  /// In en, this message translates to:
  /// **'New Subtask'**
  String get newSubtask;

  /// No description provided for @editSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtask'**
  String get editSubtask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @subtaskName.
  ///
  /// In en, this message translates to:
  /// **'Subtask name'**
  String get subtaskName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @pleaseEnterTaskName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task name'**
  String get pleaseEnterTaskName;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @addDueDate.
  ///
  /// In en, this message translates to:
  /// **'Add due date'**
  String get addDueDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @pickADate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickADate;

  /// No description provided for @pickATime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get pickATime;

  /// No description provided for @removeTime.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get removeTime;

  /// No description provided for @removeDateAndRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Remove date & recurrence'**
  String get removeDateAndRecurrence;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @addPriority.
  ///
  /// In en, this message translates to:
  /// **'Add priority'**
  String get addPriority;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get priorityNone;

  /// No description provided for @priorityN.
  ///
  /// In en, this message translates to:
  /// **'Priority {n}'**
  String priorityN(int n);

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteSubtask.
  ///
  /// In en, this message translates to:
  /// **'Delete subtask'**
  String get deleteSubtask;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{taskTitle}\"?'**
  String deleteTaskConfirmation(String taskTitle);

  /// No description provided for @deleteTaskWithSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{taskTitle}\"?\n\nThis will also delete {subtaskCount} subtask(s).'**
  String deleteTaskWithSubtasks(String taskTitle, int subtaskCount);

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{taskTitle}\" deleted'**
  String taskDeleted(String taskTitle);

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'\"{taskTitle}\" completed'**
  String taskCompleted(String taskTitle);

  /// No description provided for @taskMarkedIncomplete.
  ///
  /// In en, this message translates to:
  /// **'\"{taskTitle}\" marked incomplete'**
  String taskMarkedIncomplete(String taskTitle);

  /// No description provided for @taskMovedTo.
  ///
  /// In en, this message translates to:
  /// **'\"{taskTitle}\" moved to {projectName}'**
  String taskMovedTo(String taskTitle, String projectName);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @moveToProject.
  ///
  /// In en, this message translates to:
  /// **'Move to Project'**
  String get moveToProject;

  /// No description provided for @setPriority.
  ///
  /// In en, this message translates to:
  /// **'Set Priority'**
  String get setPriority;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add Subtask'**
  String get addSubtask;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @markIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Incomplete'**
  String get markIncomplete;

  /// No description provided for @deleteWithSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Delete ({count} subtasks)'**
  String deleteWithSubtasks(int count);

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @subtasksCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total}'**
  String subtasksCount(int completed, int total);

  /// No description provided for @addASubtask.
  ///
  /// In en, this message translates to:
  /// **'Add a subtask'**
  String get addASubtask;

  /// No description provided for @parentTask.
  ///
  /// In en, this message translates to:
  /// **'Parent Task'**
  String get parentTask;

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addComment;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment...'**
  String get editComment;

  /// No description provided for @sortTasks.
  ///
  /// In en, this message translates to:
  /// **'Sort tasks'**
  String get sortTasks;

  /// No description provided for @sortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get sortManual;

  /// No description provided for @sortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get sortPriority;

  /// No description provided for @sortDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get sortDueDate;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortDateAdded;

  /// No description provided for @showCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get showCompleted;

  /// No description provided for @hideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get hideCompleted;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completedCount(int count);

  /// No description provided for @noTasksDueToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks due today'**
  String get noTasksDueToday;

  /// No description provided for @noUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks'**
  String get noUpcomingTasks;

  /// No description provided for @yourInboxIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your inbox is empty'**
  String get yourInboxIsEmpty;

  /// No description provided for @noTasksInProject.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this project'**
  String get noTasksInProject;

  /// No description provided for @tapToAddTask.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a task'**
  String get tapToAddTask;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get recurrenceWeekdays;

  /// No description provided for @recurrenceEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String recurrenceEveryNDays(int n);

  /// No description provided for @recurrenceEveryNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {n} weeks'**
  String recurrenceEveryNWeeks(int n);

  /// No description provided for @recurrenceEveryNMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {n} months'**
  String recurrenceEveryNMonths(int n);

  /// No description provided for @recurrenceWeeklyOn.
  ///
  /// In en, this message translates to:
  /// **'Weekly on {days}'**
  String recurrenceWeeklyOn(String days);

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count}'**
  String syncing(int count);

  /// No description provided for @allChangesSynced.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get allChangesSynced;

  /// No description provided for @changesPendingSync.
  ///
  /// In en, this message translates to:
  /// **'{count} changes pending sync'**
  String changesPendingSync(int count);

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @changesWillSyncWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Changes will sync when you go online'**
  String get changesWillSyncWhenOnline;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No Date'**
  String get noDate;

  /// No description provided for @todayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayYesterday(String time);

  /// No description provided for @yesterdayTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayTime(String time);

  /// No description provided for @getTheApp.
  ///
  /// In en, this message translates to:
  /// **'Get the app'**
  String get getTheApp;

  /// No description provided for @androidAppAvailable.
  ///
  /// In en, this message translates to:
  /// **'Taskboi is available on Android for a better mobile experience!'**
  String get androidAppAvailable;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {path}'**
  String pageNotFound(String path);

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
