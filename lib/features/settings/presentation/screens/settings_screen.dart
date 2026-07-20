import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskboi/l10n/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/download_helper.dart' as download_helper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../backup/providers/backup_provider.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: l10n.integrations,
            children: [
              _SettingsTile(
                icon: Icons.vpn_key,
                title: l10n.apiKeys,
                subtitle: l10n.apiKeysSubtitle,
                onTap: () => context.go('/settings/api-keys'),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Agent Webhooks',
            children: [
              _AgentWebhookTile(),
            ],
          ),
          _SettingsSection(
            title: l10n.appearance,
            children: [
              Builder(
                builder: (context) {
                  final themeId = ref.watch(themeIdProvider);
                  final currentTheme = AppTheme.getThemeById(themeId);
                  return _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: l10n.theme,
                    subtitle: currentTheme.name,
                    onTap: () => context.go('/settings/theme'),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final themeModeId = ref.watch(themeModeIdProvider);
                  return _ThemeModeTile(
                    currentMode: themeModeId,
                    onModeChanged: (mode) {
                      ref
                          .read(themeModeNotifierProvider.notifier)
                          .setThemeMode(mode);
                    },
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final languageId = ref.watch(languageIdProvider);
                  final language = supportedLanguages.firstWhere(
                    (l) => l.id == languageId,
                    orElse: () => supportedLanguages.first,
                  );
                  String subtitle;
                  switch (language.id) {
                    case 'system':
                      subtitle = l10n.languageSystem;
                      break;
                    case 'en':
                      subtitle = l10n.languageEnglish;
                      break;
                    case 'es':
                      subtitle = l10n.languageSpanish;
                      break;
                    default:
                      subtitle = language.name;
                  }
                  return _SettingsTile(
                    icon: Icons.language,
                    title: l10n.language,
                    subtitle: subtitle,
                    onTap: () => context.go('/settings/language'),
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.data,
            children: [
              _SettingsTile(
                icon: Icons.upload_file,
                title: l10n.exportBackup,
                subtitle:
                    _isExporting ? l10n.exporting : l10n.exportBackupSubtitle,
                onTap: _isExporting ? () {} : _exportBackup,
              ),
              _SettingsTile(
                icon: Icons.download,
                title: l10n.importBackup,
                subtitle:
                    _isImporting ? l10n.importing : l10n.importBackupSubtitle,
                onTap: _isImporting ? () {} : _importBackup,
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.account,
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: l10n.signOut,
                subtitle: l10n.signOutSubtitle,
                onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: l10n.deleteAccount,
                subtitle: l10n.deleteAccountSubtitle,
                iconColor: Colors.red,
                onTap: () => _openDeleteAccountPage(context),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.about,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: l10n.aboutTaskboi,
                subtitle: l10n.aboutSubtitle,
                onTap: () => context.go('/settings/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isExporting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final backupService = ref.read(backupServiceProvider);
      final jsonContent = await backupService.exportToJson(user.id);

      // Generate filename with date
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'taskboi_backup_$dateStr.json';

      bool success = false;

      if (kIsWeb) {
        // Web: Use browser download API
        success = download_helper.downloadFile(jsonContent, fileName);
      } else {
        // Desktop: Use FilePicker to save
        // Mobile: Save to temp and share
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          final result = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (result != null) {
            final file = File(result);
            await file.writeAsString(jsonContent);
            success = true;
          }
        } else {
          // iOS/Android: Save to temp and share
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsString(jsonContent);

          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Taskboi Backup',
          );
          success = true;
        }
      }

      if (success && mounted) {
        final l10n = AppLocalizations.of(context)!;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.backupExportedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Capture scaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importBackup),
        content: Text(l10n.importBackupWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.replaceData),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      String jsonContent;
      if (kIsWeb) {
        // Web: Read from bytes
        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception('Could not read file');
        jsonContent = utf8.decode(bytes);
      } else {
        // Desktop/Mobile: Read from path
        final path = result.files.first.path;
        if (path == null) throw Exception('Could not read file');
        jsonContent = await File(path).readAsString();
      }

      final backupService = ref.read(backupServiceProvider);
      final importResult =
          await backupService.importFromJson(jsonContent, user.id);

      if (importResult.success && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.importedProjectsAndTasks(
                  importResult.projectCount, importResult.taskCount),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed(importResult.error ?? '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _openDeleteAccountPage(BuildContext context) async {
    final url = Uri.parse('https://taskboi.netlify.app/delete-account.html');
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenDeleteAccountPage)),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenDeleteAccountPage)),
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? theme.colorScheme.onSurface,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
      onTap: onTap,
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const _ThemeModeTile({
    required this.currentMode,
    required this.onModeChanged,
  });

  String _modeLabel(AppLocalizations l10n) {
    switch (currentMode) {
      case 'light':
        return l10n.light;
      case 'dark':
        return l10n.dark;
      default:
        return l10n.system;
    }
  }

  IconData get _modeIcon {
    switch (currentMode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(
        _modeIcon,
        color: theme.colorScheme.onSurface,
      ),
      title: Text(l10n.mode),
      subtitle: Text(
        _modeLabel(l10n),
        style: TextStyle(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'light',
            icon: Icon(Icons.light_mode, size: 18),
          ),
          ButtonSegment(
            value: 'system',
            icon: Icon(Icons.brightness_auto, size: 18),
          ),
          ButtonSegment(
            value: 'dark',
            icon: Icon(Icons.dark_mode, size: 18),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (selected) {
          onModeChanged(selected.first);
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _AgentWebhookTile extends StatefulWidget {
  @override
  State<_AgentWebhookTile> createState() => _AgentWebhookTileState();
}

class _AgentWebhookTileState extends State<_AgentWebhookTile> {
  final _repo = UserPreferencesRepository();
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWebhookUrl();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWebhookUrl() async {
    final url = await _repo.getAgentWebhookUrl();
    if (mounted) {
      _controller.text = url;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWebhookUrl() async {
    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setAgentWebhookUrl(_controller.text.trim());
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Webhook URL saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.webhook),
        title: Text('Agent Webhook URL'),
        subtitle: Text('Loading...'),
      );
    }

    if (!_isEditing) {
      final url = _controller.text;
      return ListTile(
        leading: const Icon(Icons.webhook),
        title: const Text('Agent Webhook URL'),
        subtitle: Text(
          url.isEmpty ? 'Not configured — tap to set' : url,
          style: TextStyle(
            color: url.isEmpty ? theme.colorScheme.outline : null,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        onTap: () {
          setState(() => _isEditing = true);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.webhook, size: 20),
              const SizedBox(width: 8),
              Text(
                'Agent Webhook URL',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'https://example.com/webhook',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _saveWebhookUrl(),
          ),
          const SizedBox(height: 4),
          Text(
            'Global URL for receiving agent task notifications. Can be overridden per project.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() => _isEditing = false);
                      },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _saveWebhookUrl,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
