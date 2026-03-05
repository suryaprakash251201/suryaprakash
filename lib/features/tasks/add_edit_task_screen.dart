import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/models.dart';
import '../../core/providers/task_providers.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final Task? existingTask;

  const AddEditTaskScreen({super.key, this.existingTask});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  int _priority = 3;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _status = 'inbox';
  String? _projectId;
  int? _estimatedMinutes;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    if (t != null) {
      _priority = t.priority;
      _dueDate = t.dueDate;
      _status = t.status;
      _projectId = t.projectId;
      _estimatedMinutes = t.estimatedMinutes;
      _tags.addAll(t.tags);
      if (t.dueTime != null) {
        final parts = t.dueTime!.split(':');
        _dueTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteTask,
            ),
          FilledButton(
            onPressed: _saveTask,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Title ───
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const Divider(),

          // ─── Description ───
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add description...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 16),

          // ─── Priority ───
          Text('Priority', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _priorityChip('P0', 0, Colors.red),
              const SizedBox(width: 8),
              _priorityChip('P1', 1, Colors.orange),
              const SizedBox(width: 8),
              _priorityChip('P2', 2, Colors.blue),
              const SizedBox(width: 8),
              _priorityChip('P3', 3, Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Due Date ───
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(_dueDate != null ? DateFormat('EEE, d MMM yyyy').format(_dueDate!) : 'Set due date'),
            trailing: _dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _dueDate = null;
                      _dueTime = null;
                    }),
                  )
                : null,
            onTap: _pickDueDate,
          ),

          // ─── Due Time ───
          if (_dueDate != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(_dueTime != null ? _dueTime!.format(context) : 'Set time'),
              trailing: _dueTime != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _dueTime = null),
                    )
                  : null,
              onTap: _pickDueTime,
            ),

          // ─── Project ───
          projects.when(
            data: (projectList) {
              if (projectList.isEmpty) return const SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(_projectId != null
                    ? projectList.firstWhere((p) => p.id == _projectId, orElse: () => projectList.first).name
                    : 'No project'),
                onTap: () => _pickProject(projectList),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, st) => const SizedBox.shrink(),
          ),

          // ─── Status ───
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text('Status: ${_statusLabel(_status)}'),
            onTap: _pickStatus,
          ),

          // ─── Estimated Time ───
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: Text(_estimatedMinutes != null ? '$_estimatedMinutes min' : 'Estimated time'),
            onTap: _pickEstimatedTime,
          ),

          // ─── Tags ───
          const SizedBox(height: 8),
          Text('Tags', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => setState(() => _tags.remove(tag)),
                deleteIconColor: theme.colorScheme.error,
              )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add Tag'),
                onPressed: _addTag,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityChip(String label, int value, Color color) {
    final selected = _priority == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (s) => setState(() => _priority = value),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'inbox': return 'Inbox';
      case 'backlog': return 'Backlog';
      case 'in_progress': return 'In Progress';
      case 'done': return 'Done';
      default: return status;
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _pickDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _dueTime = time);
  }

  void _pickProject(List<Project> projects) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('No project'),
            onTap: () {
              setState(() => _projectId = null);
              Navigator.pop(context);
            },
          ),
          ...projects.map((p) => ListTile(
            leading: Icon(IconData(p.iconCode, fontFamily: 'MaterialIcons')),
            title: Text(p.name),
            selected: _projectId == p.id,
            onTap: () {
              setState(() => _projectId = p.id);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _pickStatus() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final s in ['inbox', 'backlog', 'in_progress', 'done'])
            ListTile(
              title: Text(_statusLabel(s)),
              selected: _status == s,
              onTap: () {
                setState(() => _status = s);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _pickEstimatedTime() {
    final options = [15, 30, 45, 60, 90, 120];
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('No estimate'),
            onTap: () {
              setState(() => _estimatedMinutes = null);
              Navigator.pop(context);
            },
          ),
          ...options.map((m) => ListTile(
            title: Text('$m minutes'),
            selected: _estimatedMinutes == m,
            onTap: () {
              setState(() => _estimatedMinutes = m);
              Navigator.pop(context);
            },
          )),
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

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title is required')),
      );
      return;
    }

    final now = DateTime.now();
    final task = Task(
      id: widget.existingTask?.id ?? const Uuid().v4(),
      title: title,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      dueTime: _dueTime != null
          ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      projectId: _projectId,
      parentTaskId: widget.existingTask?.parentTaskId,
      status: _status,
      estimatedMinutes: _estimatedMinutes,
      completedAt: widget.existingTask?.completedAt,
      sortOrder: widget.existingTask?.sortOrder ?? 0,
      tags: _tags,
      createdAt: widget.existingTask?.createdAt ?? now,
      modifiedAt: now,
    );

    if (_isEditing) {
      await ref.read(taskListProvider.notifier).updateTask(task);
    } else {
      await ref.read(taskListProvider.notifier).addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('This action cannot be undone. Delete this task?'),
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
    if (confirm == true && widget.existingTask != null) {
      await ref.read(taskListProvider.notifier).deleteTask(widget.existingTask!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
