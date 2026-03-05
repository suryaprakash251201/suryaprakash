import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/note_providers.dart';
import 'note_editor_screen.dart';
import 'notebooks_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _selectedNotebookId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;
    final notes = ref.watch(noteListProvider);
    final notebooksAsync = ref.watch(notebookListProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: _NoteSearchDelegate(ref),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'notebooks', child: Text('Manage Notebooks')),
            ],
            onSelected: (value) {
              if (value == 'notebooks') _manageNotebooks(context, ref);
            },
          ),
        ],
      ),
      body: notes.when(
        data: (noteList) {
          if (noteList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.note_alt, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No notes yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first note\nMarkdown is supported!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                  ),
                ],
              ),
            );
          }

          // Filter by selected notebook
          final filteredList = _selectedNotebookId == null
              ? noteList
              : noteList.where((n) => n.notebookId == _selectedNotebookId).toList();

          final pinned = filteredList.where((n) => n.isPinned).toList();
          final unpinned = filteredList.where((n) => !n.isPinned).toList();

          return Column(
            children: [
              // Notebook Filter Bar
              if (notebooksAsync is AsyncData && notebooksAsync.value!.isNotEmpty)
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Notes'),
                          selected: _selectedNotebookId == null,
                          onSelected: (s) {
                            if (s) setState(() => _selectedNotebookId = null);
                          },
                        ),
                      ),
                      ...notebooksAsync.value!.map((nb) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                Icon(IconData(nb.iconCode, fontFamily: 'MaterialIcons'), size: 14, color: Color(int.parse(nb.colorHex, radix: 16))),
                                const SizedBox(width: 4),
                                Text(nb.name),
                              ],
                            ),
                            selected: _selectedNotebookId == nb.id,
                            onSelected: (s) {
                              if (s) setState(() => _selectedNotebookId = nb.id);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
              if (pinned.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'PINNED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                ...pinned.map((note) => _NoteCard(note: note)),
              ],
              if (unpinned.isNotEmpty) ...[
                if (pinned.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                    child: Text(
                      'OTHERS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ...unpinned.map((note) => _NoteCard(note: note)),
              ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesFAB',
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context, {Note? note}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(existingNote: note),
      ),
    );
  }

  void _manageNotebooks(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotebooksScreen()),
    );
  }
}

// ─── Note Card ───
class _NoteCard extends ConsumerWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final preview = _getPreview(note.contentMarkdown ?? '');

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(noteListProvider.notifier).deleteNote(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${note.title} deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(existingNote: note),
            ),
          ),
          onLongPress: () {
            ref.read(noteListProvider.notifier).togglePin(note.id, !note.isPinned);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
                      ),
                    Expanded(
                      child: Text(
                        note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDate(note.modifiedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ],
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: note.tags.take(4).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPreview(String markdown) {
    // Strip markdown formatting for preview
    return markdown
        .replaceAll(RegExp(r'[#*_~`\[\]()]'), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }
}

// ─── Note Search Delegate ───
class _NoteSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  _NoteSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) => _build();

  @override
  Widget buildSuggestions(BuildContext context) => _build();

  Widget _build() {
    if (query.isEmpty) return const Center(child: Text('Type to search notes'));
    return Consumer(
      builder: (context, ref, _) {
        ref.read(noteSearchQueryProvider.notifier).set(query);
        final results = ref.watch(noteSearchResultsProvider);
        return results.when(
          data: (notes) {
            if (notes.isEmpty) return const Center(child: Text('No notes found'));
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) => _NoteCard(note: notes[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
    );
  }
}
