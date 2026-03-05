import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/note_providers.dart';

class NotebooksScreen extends ConsumerStatefulWidget {
  const NotebooksScreen({super.key});

  @override
  ConsumerState<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends ConsumerState<NotebooksScreen> {
  void _showNotebookDialog(BuildContext context, [Notebook? existingNotebook]) {
    final nameController = TextEditingController(text: existingNotebook?.name ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingNotebook == null ? 'New Notebook' : 'Edit Notebook'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Notebook Name',
              hintText: 'e.g., Personal, Work',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final nb = Notebook(
                    id: existingNotebook?.id ?? const Uuid().v4(),
                    name: name,
                    createdAt: existingNotebook?.createdAt ?? DateTime.now(),
                  );
                  if (existingNotebook == null) {
                    ref.read(notebookListProvider.notifier).addNotebook(nb);
                  } else {
                    ref.read(notebookListProvider.notifier).updateNotebook(nb);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _deleteNotebook(BuildContext context, Notebook notebook) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook'),
        content: Text("Are you sure you want to delete '\${notebook.name}'? Notes inside will become uncategorized."),
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

    if (confirm == true && context.mounted) {
      ref.read(notebookListProvider.notifier).deleteNotebook(notebook.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notebooksAsync = ref.watch(notebookListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notebooks'),
      ),
      body: notebooksAsync.when(
        data: (notebooks) {
          if (notebooks.isEmpty) {
            return const Center(child: Text('No notebooks created yet.'));
          }
          return ListView.builder(
            itemCount: notebooks.length,
            itemBuilder: (context, index) {
              final nb = notebooks[index];
              return ListTile(
                leading: Icon(IconData(nb.iconCode, fontFamily: 'MaterialIcons'), color: Color(int.parse(nb.colorHex, radix: 16))),
                title: Text(nb.name),
                subtitle: Text('Created on \${nb.createdAt.toString().substring(0, 10)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showNotebookDialog(context, nb),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteNotebook(context, nb),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: \$e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notebooksFAB',
        onPressed: () => _showNotebookDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
