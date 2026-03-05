import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/backup_service.dart';
import '../../core/providers/vault_security_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../vault/vault_security_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);
    final vaultSecurity = ref.watch(vaultSecurityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ─── Appearance Section ───
          _sectionHeader(theme, 'Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _themeOption(
                  ref,
                  theme,
                  title: 'Light',
                  subtitle: 'Clean, bright interface',
                  icon: Icons.light_mode,
                  mode: AppThemeMode.light,
                  selected: currentTheme == AppThemeMode.light,
                ),
                const Divider(height: 1, indent: 56),
                _themeOption(
                  ref,
                  theme,
                  title: 'Dark',
                  subtitle: 'Easy on the eyes',
                  icon: Icons.dark_mode,
                  mode: AppThemeMode.dark,
                  selected: currentTheme == AppThemeMode.dark,
                ),
                const Divider(height: 1, indent: 56),
                _themeOption(
                  ref,
                  theme,
                  title: 'OLED Black',
                  subtitle: 'True black for AMOLED screens',
                  icon: Icons.brightness_2,
                  mode: AppThemeMode.oled,
                  selected: currentTheme == AppThemeMode.oled,
                ),
              ],
            ),
          ),

          // ─── Data Section ───
          _sectionHeader(theme, 'Data'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Export all data to a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleBackupData(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Import data from a backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleRestoreData(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Expenses'),
                  subtitle: const Text('Export to CSV or PDF'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleExportExpenses(context),
                ),
              ],
            ),
          ),

          // ─── Security Section ───
          _sectionHeader(theme, 'Security'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Lock'),
                  subtitle: const Text('Require authentication to open Vault'),
                  value: vaultSecurity.biometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final auth = LocalAuthentication();
                      final canCheck = await auth.canCheckBiometrics;
                      final supported = await auth.isDeviceSupported();
                      if (!canCheck && !supported) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometrics are not available on this device.')),
                        );
                        return;
                      }
                    }
                    await ref.read(vaultSecurityProvider.notifier).setBiometricEnabled(value);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Vault Security Settings'),
                  subtitle: const Text('Enroll PIN, face unlock, and lock options'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const VaultSecurityScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // ─── About Section ───
          _sectionHeader(theme, 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Suryaprakash'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('All data stays on your device'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themeOption(
    WidgetRef ref,
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemeMode mode,
    required bool selected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
    );
  }

  Future<void> _handleBackupData(BuildContext context) async {
    final backupPath = await BackupService().exportDatabase();
    if (!context.mounted) return;

    if (backupPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed. Please try again.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup created: ${p.basename(backupPath)}')),
    );
  }

  Future<void> _handleRestoreData(BuildContext context) async {
    final service = BackupService();
    final backups = await service.listBackupFiles();
    if (!context.mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backup files found. Create a backup first.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: backups.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final path = backups[index];
              return ListTile(
                leading: const Icon(Icons.storage),
                title: Text(p.basename(path)),
                subtitle: Text(path),
                onTap: () => Navigator.of(context).pop(path),
              );
            },
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('This will replace current local data with the selected backup. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await service.restoreDatabase(selected);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Data restored successfully. Please restart the app to reload all screens.'
              : 'Restore failed. Please try another backup.',
        ),
      ),
    );
  }

  Future<void> _handleExportExpenses(BuildContext context) async {
    final exportPath = await BackupService().exportExpensesCsv();
    if (!context.mounted) return;

    if (exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense export failed.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expenses exported: ${p.basename(exportPath)}')),
    );
  }
}
