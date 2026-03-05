import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/task_providers.dart';
import 'add_edit_task_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['Inbox', 'Today', 'Upcoming', 'Projects'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddTask(context),
            tooltip: 'New Task',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'matrix', child: Text('Eisenhower Matrix')),
              const PopupMenuItem(value: 'overdue', child: Text('Show Overdue')),
            ],
            onSelected: (value) {
              if (value == 'overdue') _showOverdue(context);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InboxTab(),
          _TodayTab(),
          _UpcomingTab(),
          _ProjectsTab(),
        ],
      ),
    );
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _TaskSearchDelegate(ref));
  }

  void _showOverdue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, _) {
              final overdue = ref.watch(overdueTasksProvider);
              return overdue.when(
                data: (tasks) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Overdue Tasks (${tasks.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Expanded(
                      child: tasks.isEmpty
                          ? const Center(child: Text('No overdue tasks! 🎉'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: tasks.length,
                              itemBuilder: (context, index) =>
                                  TaskListTile(task: tasks[index]),
                            ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Inbox Tab ───
class _InboxTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(inboxTasksProvider);
    return _TaskListView(
      asyncTasks: tasks,
      emptyIcon: Icons.inbox,
      emptyTitle: 'Inbox is empty',
      emptySubtitle: 'Capture tasks here to triage later',
    );
  }
}

// ─── Today Tab ───
class _TodayTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider);
    return _TaskListView(
      asyncTasks: tasks,
      emptyIcon: Icons.today,
      emptyTitle: 'Nothing due today',
      emptySubtitle: 'You\'re all caught up! 🎉',
    );
  }
}

// ─── Upcoming Tab ───
class _UpcomingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(upcomingTasksProvider);
    return _TaskListView(
      asyncTasks: tasks,
      emptyIcon: Icons.upcoming,
      emptyTitle: 'No upcoming tasks',
      emptySubtitle: 'Plan ahead by adding due dates',
    );
  }
}

// ─── Projects Tab ───
class _ProjectsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final theme = Theme.of(context);

    return projects.when(
      data: (projectList) {
        if (projectList.isEmpty) {
          return _EmptyState(
            icon: Icons.folder_open,
            title: 'No projects yet',
            subtitle: 'Organize tasks into projects',
            action: FilledButton.icon(
              onPressed: () => _addProject(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...projectList.map((project) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse('0x${project.colorHex}')).withValues(alpha: 0.2),
                  child: Icon(
                    IconData(project.iconCode, fontFamily: 'MaterialIcons'),
                    color: Color(int.parse('0x${project.colorHex}')),
                  ),
                ),
                title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: project.description != null ? Text(project.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openProject(context, project),
              ),
            )),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _addProject(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _addProject(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final project = Project(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  colorHex: 'FF3F51B5',
                  iconCode: Icons.folder.codePoint,
                  createdAt: DateTime.now(),
                );
                ref.read(projectListProvider.notifier).addProject(project);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ProjectDetailScreen(project: project),
      ),
    );
  }
}

// ─── Project Detail Screen ───
class _ProjectDetailScreen extends ConsumerWidget {
  final Project project;
  const _ProjectDetailScreen({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(projectTasksProvider(project.id));
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Backlog'),
              Tab(text: 'In Progress'),
              Tab(text: 'Done'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditTaskScreen(
                    existingTask: Task(
                      id: '',
                      title: '',
                      projectId: project.id,
                      status: 'backlog',
                      createdAt: DateTime.now(),
                      modifiedAt: DateTime.now(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: tasks.when(
          data: (taskList) {
            final backlog = taskList.where((t) => t.status == 'backlog' || t.status == 'inbox').toList();
            final inProgress = taskList.where((t) => t.status == 'in_progress').toList();
            final done = taskList.where((t) => t.status == 'done').toList();

            return TabBarView(
              children: [
                _kanbanColumn(backlog, theme, 'No backlog tasks'),
                _kanbanColumn(inProgress, theme, 'No tasks in progress'),
                _kanbanColumn(done, theme, 'No completed tasks'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _kanbanColumn(List<Task> tasks, ThemeData theme, String emptyText) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskListTile(task: tasks[index]),
    );
  }
}

// ─── Reusable Task List View ───
class _TaskListView extends StatelessWidget {
  final AsyncValue<List<Task>> asyncTasks;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _TaskListView({
    required this.asyncTasks,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return asyncTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskListTile(task: tasks[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Task List Tile ───
class TaskListTile extends ConsumerWidget {
  final Task task;
  const TaskListTile({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityColor = _priorityColor(task.priority);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(taskListProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${task.title} deleted')),
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
              builder: (context) => AddEditTaskScreen(existingTask: task),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    if (task.isCompleted) {
                      ref.read(taskListProvider.notifier).reopenTask(task.id);
                    } else {
                      ref.read(taskListProvider.notifier).completeTask(task.id);
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted ? Colors.green : priorityColor,
                        width: 2,
                      ),
                      color: task.isCompleted ? Colors.green : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (task.dueDate != null || task.tags.isNotEmpty)
                        const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: task.isOverdue ? Colors.red : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: task.isOverdue ? Colors.red : theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ...task.tags.take(2).map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tag, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'P${task.priority}',
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 0: return Colors.red;
      case 1: return Colors.orange;
      case 2: return Colors.blue;
      default: return Colors.grey;
    }
  }
}

// ─── Empty State ───
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── Task Search Delegate ───
class _TaskSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  _TaskSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search tasks'));
    }
    return Consumer(
      builder: (context, ref, _) {
        ref.read(taskSearchQueryProvider.notifier).set(query);
        final results = ref.watch(taskSearchResultsProvider);
        return results.when(
          data: (tasks) {
            if (tasks.isEmpty) return const Center(child: Text('No tasks found'));
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskListTile(task: tasks[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
    );
  }
}
