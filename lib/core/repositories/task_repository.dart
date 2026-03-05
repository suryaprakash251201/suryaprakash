import '../database/database_helper.dart';
import '../models/models.dart';

class TaskRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ─── Create ───
  Future<void> insertTask(Task task) async {
    final db = await _db.database;
    await db.insert('tasks', task.toMap());

    // Insert tags
    for (final tag in task.tags) {
      await db.insert('task_tags', {'task_id': task.id, 'tag': tag});
    }
  }

  // ─── Read ───
  Future<List<Task>> getAllTasks() async {
    final db = await _db.database;
    final maps = await db.query('tasks', orderBy: 'sort_order ASC, created_at DESC');
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> getTasksByStatus(String status) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'status = ? AND parent_task_id IS NULL',
      whereArgs: [status],
      orderBy: 'priority ASC, due_date ASC, sort_order ASC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> getInboxTasks() async {
    return getTasksByStatus('inbox');
  }

  Future<List<Task>> getTodayTasks() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    final tomorrowStr = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'due_date >= ? AND due_date < ? AND status != ? AND parent_task_id IS NULL',
      whereArgs: [todayStr, tomorrowStr, 'done'],
      orderBy: 'priority ASC, due_date ASC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> getUpcomingTasks() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    final weekLaterStr = DateTime(now.year, now.month, now.day + 7).toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'due_date >= ? AND due_date < ? AND status != ? AND parent_task_id IS NULL',
      whereArgs: [todayStr, weekLaterStr, 'done'],
      orderBy: 'due_date ASC, priority ASC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> getTasksByProject(String projectId) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'project_id = ? AND parent_task_id IS NULL',
      whereArgs: [projectId],
      orderBy: 'status ASC, priority ASC, sort_order ASC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> getSubtasks(String parentTaskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'parent_task_id = ?',
      whereArgs: [parentTaskId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => Task.fromMap({...m})).toList();
  }

  Future<List<Task>> getOverdueTasks() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();

    final maps = await db.query(
      'tasks',
      where: 'due_date < ? AND status != ? AND parent_task_id IS NULL',
      whereArgs: [todayStr, 'done'],
      orderBy: 'due_date ASC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    final tasks = <Task>[];
    for (final map in maps) {
      final tags = await _getTaskTags(map['id'] as String);
      tasks.add(Task.fromMap({...map}).copyWith(tags: tags));
    }
    return tasks;
  }

  Future<int> getCompletedTodayCount() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE completed_at >= ? AND status = ?',
      [todayStr, 'done'],
    );
    return result.first['count'] as int;
  }

  // ─── Update ───
  Future<void> updateTask(Task task) async {
    final db = await _db.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);

    // Update tags
    await db.delete('task_tags', where: 'task_id = ?', whereArgs: [task.id]);
    for (final tag in task.tags) {
      await db.insert('task_tags', {'task_id': task.id, 'tag': tag});
    }
  }

  Future<void> completeTask(String taskId) async {
    final db = await _db.database;
    await db.update(
      'tasks',
      {
        'status': 'done',
        'completed_at': DateTime.now().toIso8601String(),
        'modified_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> reopenTask(String taskId) async {
    final db = await _db.database;
    await db.update(
      'tasks',
      {
        'status': 'inbox',
        'completed_at': null,
        'modified_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ─── Delete ───
  Future<void> deleteTask(String taskId) async {
    final db = await _db.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // ─── Helpers ───
  Future<List<String>> _getTaskTags(String taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_tags',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    return maps.map((m) => m['tag'] as String).toList();
  }
}

// ─── Project Repository ───
class ProjectRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> insertProject(Project project) async {
    final db = await _db.database;
    await db.insert('projects', project.toMap());
  }

  Future<List<Project>> getAllProjects() async {
    final db = await _db.database;
    final maps = await db.query(
      'projects',
      where: 'is_archived = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  Future<void> updateProject(Project project) async {
    final db = await _db.database;
    await db.update('projects', project.toMap(), where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> deleteProject(String projectId) async {
    final db = await _db.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);
  }

  Future<void> archiveProject(String projectId) async {
    final db = await _db.database;
    await db.update('projects', {'is_archived': 1}, where: 'id = ?', whereArgs: [projectId]);
  }
}
