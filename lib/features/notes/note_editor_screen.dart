import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/note_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? existingNote;

  const NoteEditorScreen({super.key, this.existingNote});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isPreview = false;
  bool _isPinned = false;
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  String? _selectedNotebookId;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existingNote;
    _titleController = TextEditingController(text: n?.title ?? '');
    _contentController = TextEditingController(text: n?.contentMarkdown ?? '');
    if (n != null) {
      _isPinned = n.isPinned;
      _tags.addAll(n.tags);
      _selectedNotebookId = n.notebookId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: _isPinned ? 'Unpin' : 'Pin',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            tooltip: _isPreview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _isPreview = !_isPreview),
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteNote,
            ),
          FilledButton(
            onPressed: _saveNote,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _titleController,
              autofocus: !_isEditing,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Note title',
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          
          // Notebook Selection
          Consumer(
            builder: (context, ref, _) {
              final notebooksAsync = ref.watch(notebookListProvider);
              if (notebooksAsync is! AsyncData || notebooksAsync.value!.isEmpty) {
                return const SizedBox.shrink();
              }
              final notebooks = notebooksAsync.value!;
              
              // Ensure selected notebook ID is valid if it exists
              if (_selectedNotebookId != null && !notebooks.any((nb) => nb.id == _selectedNotebookId)) {
                _selectedNotebookId = null;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedNotebookId,
                  decoration: const InputDecoration(
                    labelText: 'Notebook',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Notebook')),
                    ...notebooks.map((nb) => DropdownMenuItem(value: nb.id, child: Text(nb.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedNotebookId = val);
                  },
                ),
              );
            },
          ),

          // Tags row
          if (_tags.isNotEmpty || !_isPreview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
                    if (!_isPreview)
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 14),
                        label: const Text('Tag', style: TextStyle(fontSize: 11)),
                        onPressed: _addTag,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),

          const Divider(),

          // Content
          Expanded(
            child: _isPreview
                ? Markdown(
                    data: _contentController.text.isEmpty
                        ? '*No content yet*'
                        : _contentController.text,
                    selectable: true,
                    padding: const EdgeInsets.all(16),
                  )
                : Column(
                    children: [
                      // Markdown toolbar
                      _MarkdownToolbar(controller: _contentController, onChanged: () => setState(() {})),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              height: 1.6,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start writing... (Markdown supported)',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final tag = _tagController.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
              }
              _tagController.clear();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note title is required')),
      );
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.existingNote?.id ?? const Uuid().v4(),
      title: title,
      contentMarkdown: _contentController.text,
      notebookId: _selectedNotebookId,
      type: 'text',
      isPinned: _isPinned,
      isLocked: widget.existingNote?.isLocked ?? false,
      tags: _tags,
      createdAt: widget.existingNote?.createdAt ?? now,
      modifiedAt: now,
    );

    if (_isEditing) {
      await ref.read(noteListProvider.notifier).updateNote(note);
    } else {
      await ref.read(noteListProvider.notifier).addNote(note);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && widget.existingNote != null) {
      await ref.read(noteListProvider.notifier).deleteNote(widget.existingNote!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── Markdown Toolbar ───
class _MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _MarkdownToolbar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _toolButton(Icons.format_bold, '**', '**'),
          _toolButton(Icons.format_italic, '_', '_'),
          _toolButton(Icons.format_strikethrough, '~~', '~~'),
          const VerticalDivider(width: 16),
          _toolButton(Icons.title, '# ', ''),
          _toolButton(Icons.format_list_bulleted, '- ', ''),
          _toolButton(Icons.format_list_numbered, '1. ', ''),
          const VerticalDivider(width: 16),
          _toolButton(Icons.code, '`', '`'),
          _toolButton(Icons.link, '[', '](url)'),
          _toolButton(Icons.check_box, '- [ ] ', ''),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String prefix, String suffix) {
    return InkWell(
      onTap: () => _insertMarkdown(prefix, suffix),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;
    final selectedText = selection.isValid
        ? text.substring(selection.start, selection.end)
        : '';

    final newText = '$prefix$selectedText$suffix';
    controller.text = text.replaceRange(
      selection.isValid ? selection.start : text.length,
      selection.isValid ? selection.end : text.length,
      newText,
    );

    final newCursorPos = (selection.isValid ? selection.start : text.length) +
        prefix.length +
        selectedText.length;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
    onChanged();
  }
}
