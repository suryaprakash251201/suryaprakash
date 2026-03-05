import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<String> _goals = [
    'Walk 8,000 steps daily',
    'Read 20 minutes daily',
    'Track expenses every evening',
  ];

  Future<void> _addGoal() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Goal',
            hintText: 'Enter your personal goal',
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
              setState(() => _goals.add(value));
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
        title: const Text('Goals'),
        actions: [
          IconButton(
            onPressed: _addGoal,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _goals.isEmpty
          ? const Center(child: Text('No goals yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  leading: const Icon(Icons.flag),
                  title: Text(_goals[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _goals.removeAt(index)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
