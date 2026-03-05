import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_screen.dart';
import '../notes/notes_screen.dart';
import '../habits/habits_screen.dart';
import '../vault/vault_screen.dart';
import '../journal/journal_screen.dart';
import 'documents_screen.dart';
import 'goals_screen.dart';
import '../../core/services/backup_service.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _featureTile(
              context,
              icon: Icons.note_alt,
              label: 'Notes',
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.lock,
              label: 'Vault',
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VaultScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.loop,
              label: 'Habits',
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HabitsScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.book,
              label: 'Journal',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const JournalScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.flag,
              label: 'Goals',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GoalsScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.badge,
              label: 'Documents',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                );
              },
            ),
            _featureTile(
              context,
              icon: Icons.backup,
              label: 'Backup',
              color: Colors.blue,
              onTap: () async {
                final backupPath = await BackupService().exportDatabase();
                if (!context.mounted) return;

                if (backupPath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup saved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to backup database.', style: TextStyle(color: Colors.red))),
                  );
                }
              },
            ),
            _featureTile(
              context,
              icon: Icons.settings,
              label: 'Settings',
              color: Colors.grey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
