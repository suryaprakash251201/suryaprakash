import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/task_repository.dart';

// ─── Repositories ───
final taskRepositoryProvider = Provider((ref) => TaskRepository());
final projectRepositoryProvider = Provider((ref) => ProjectRepository());

// ─── Task List Providers ───
class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return ref.read(taskRepositoryProvider).getAllTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(taskRepositoryProvider).getAllTasks());
  }

  Future<void> addTask(Task task) async {
    await ref.read(taskRepositoryProvider).insertTask(task);
    await refresh();
  }

  Future<void> updateTask(Task task) async {
    await ref.read(taskRepositoryProvider).updateTask(task);
    await refresh();
  }

  Future<void> completeTask(String taskId) async {
    await ref.read(taskRepositoryProvider).completeTask(taskId);
    await refresh();
  }

  Future<void> reopenTask(String taskId) async {
    await ref.read(taskRepositoryProvider).reopenTask(taskId);
    await refresh();
  }

  Future<void> deleteTask(String taskId) async {
    await ref.read(taskRepositoryProvider).deleteTask(taskId);
    await refresh();
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

// ─── Filtered Task Providers ───
final inboxTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(taskListProvider);
  return ref.read(taskRepositoryProvider).getInboxTasks();
});

final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(taskListProvider);
  return ref.read(taskRepositoryProvider).getTodayTasks();
});

final upcomingTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(taskListProvider);
  return ref.read(taskRepositoryProvider).getUpcomingTasks();
});

final overdueTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(taskListProvider);
  return ref.read(taskRepositoryProvider).getOverdueTasks();
});

// ─── Project Providers ───
class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    return ref.read(projectRepositoryProvider).getAllProjects();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(projectRepositoryProvider).getAllProjects());
  }

  Future<void> addProject(Project project) async {
    await ref.read(projectRepositoryProvider).insertProject(project);
    await refresh();
  }

  Future<void> updateProject(Project project) async {
    await ref.read(projectRepositoryProvider).updateProject(project);
    await refresh();
  }

  Future<void> deleteProject(String projectId) async {
    await ref.read(projectRepositoryProvider).deleteProject(projectId);
    await refresh();
  }
}

final projectListProvider = AsyncNotifierProvider<ProjectListNotifier, List<Project>>(
  ProjectListNotifier.new,
);

// ─── Tasks by project ───
final projectTasksProvider = FutureProvider.family<List<Task>, String>(
  (ref, projectId) async {
    ref.watch(taskListProvider);
    return ref.read(taskRepositoryProvider).getTasksByProject(projectId);
  },
);

// ─── Search ───
class TaskSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final taskSearchQueryProvider = NotifierProvider<TaskSearchQueryNotifier, String>(
  TaskSearchQueryNotifier.new,
);

final taskSearchResultsProvider = FutureProvider<List<Task>>((ref) async {
  final query = ref.watch(taskSearchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(taskRepositoryProvider).searchTasks(query);
});
