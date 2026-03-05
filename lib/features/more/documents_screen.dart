import 'package:flutter/material.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final List<String> _documents = [
    'Bills',
    'ID Proofs',
    'Tax & Income Docs',
  ];

  Future<void> _addDocument() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document name',
            hintText: 'Enter document title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              setState(() => _documents.add(value));
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            onPressed: _addDocument,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _documents.isEmpty
          ? const Center(child: Text('No documents yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  leading: const Icon(Icons.description),
                  title: Text(_documents[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _documents.removeAt(index)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDocument,
        child: const Icon(Icons.add),
      ),
    );
  }
}
