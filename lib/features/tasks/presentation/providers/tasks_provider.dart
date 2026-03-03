import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetask_pro/core/database/database_helper.dart';
import 'package:notetask_pro/core/notifications/notification_service.dart';
import 'package:notetask_pro/features/tasks/data/task_dao.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- DAOs ----

final taskDaoProvider = Provider<TaskDao>(
    (ref) => TaskDao(DatabaseHelper.instance));

// ---- Tasks state ----

class TasksFilter {
  final bool showCompleted;
  final TaskPriority? priority;
  final String? query;

  const TasksFilter({
    this.showCompleted = false,
    this.priority,
    this.query,
  });

  TasksFilter copyWith({
    bool? showCompleted,
    TaskPriority? priority,
    String? query,
    bool clearPriority = false,
  }) =>
      TasksFilter(
        showCompleted: showCompleted ?? this.showCompleted,
        priority: clearPriority ? null : (priority ?? this.priority),
        query: query ?? this.query,
      );
}

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final TaskDao _dao;
  TasksFilter _filter = const TasksFilter();

  TasksNotifier(this._dao) : super(const AsyncValue.loading()) {
    _load();
  }

  TasksFilter get filter => _filter;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _dao.getTopLevel(
        completed: null, // Load all tasks
        priority: _filter.priority,
        query: _filter.query,
      );
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setFilter(TasksFilter filter) {
    _filter = filter;
    _load();
  }

  Future<void> createTask(Task task) async {
    await _dao.insert(task);
    if (task.reminderAt != null && task.reminderAt!.isAfter(DateTime.now())) {
      // Get default sound from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final soundPath = prefs.getString('default_sound_path');
      await NotificationService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledTime: task.reminderAt!,
        soundFilePath: soundPath,
        body: task.description,
      );
    }
    _load();
  }

  Future<void> updateTask(Task task) async {
    await _dao.update(task);
    // Cancel existing notification
    await NotificationService.cancelReminder(task.id);
    // Reschedule if reminder is set and in the future
    if (task.reminderAt != null && task.reminderAt!.isAfter(DateTime.now())) {
      // Get default sound from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final soundPath = prefs.getString('default_sound_path');
      await NotificationService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledTime: task.reminderAt!,
        soundFilePath: soundPath,
        body: task.description,
      );
    }
    _load();
  }

  Future<void> deleteTask(String id) async {
    await NotificationService.cancelReminder(id);
    await _dao.delete(id);
    _load();
  }

  Future<void> toggleComplete(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await _dao.update(updated);
    _load();
  }

  Future<void> addSubtask(Task subtask) async {
    await _dao.insert(subtask);
    _load();
  }

  Future<void> refresh() => _load();
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>(
        (ref) => TasksNotifier(ref.watch(taskDaoProvider)));

// ---- Tasks due today ----

final tasksDueTodayProvider = FutureProvider<List<Task>>((ref) {
  return ref.watch(taskDaoProvider).getTasksDueToday();
});
