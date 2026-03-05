import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/journal_providers.dart';
import 'add_edit_journal_screen.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Journal', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(theme);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _JournalEntryCard(entry: entry, theme: theme, isDark: isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: \$err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditJournalScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Your journal is empty',
            style: theme.textTheme.bodyLarge?.copyWith(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends ConsumerWidget {
  final JournalEntry entry;
  final ThemeData theme;
  final bool isDark;

  const _JournalEntryCard({required this.entry, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddEditJournalScreen(existingEntry: entry)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(entry.date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildMoodBadge(entry.mood ?? 3, theme),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getTemplateName(entry.template),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (entry.content != null && entry.content!.isNotEmpty)
                Text(
                  entry.content!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTemplateName(String template) {
    if (template == 'gratitude') return 'Gratitude Journal';
    if (template == 'daily_review') return 'Daily Review';
    return 'Freeform Journal';
  }

  Widget _buildMoodBadge(int mood, ThemeData theme) {
    String emoji;
    Color color;
    String moodName;
    
    switch (mood) {
      case 5:
        emoji = '😄';
        color = Colors.green;
        moodName = 'Happy';
        break;
      case 4:
        emoji = '😌';
        color = Colors.teal;
        moodName = 'Calm';
        break;
      case 3:
        emoji = '😐';
        color = Colors.grey;
        moodName = 'Neutral';
        break;
      case 2:
        emoji = '😢';
        color = Colors.blue;
        moodName = 'Sad';
        break;
      case 1:
        emoji = '😠';
        color = Colors.red;
        moodName = 'Angry';
        break;
      default:
        emoji = '😐';
        color = Colors.grey;
        moodName = 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            moodName,
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
