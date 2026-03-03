import 'package:notetask_pro/core/database/database_helper.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:sqflite/sqflite.dart';

class TaskDao {
  final DatabaseHelper _db;
  TaskDao(this._db);

  Future<Database> get _database => _db.database;

  Future<void> insert(Task task) async {
    final db = await _database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Task task) async {
    final db = await _database;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getById(String id) async {
    final db = await _database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final task = Task.fromMap(rows.first);
    return task.copyWith(subtasks: await _getSubtasks(db, id));
  }

  Future<List<Task>> getTopLevel({
    bool? completed,
    String? query,
    TaskPriority? priority,
  }) async {
    final db = await _database;
    String where = 'parent_id IS NULL';
    final args = <dynamic>[];

    if (completed != null) {
      where += ' AND is_completed = ?';
      args.add(completed ? 1 : 0);
    }

    if (priority != null) {
      where += ' AND priority = ?';
      args.add(priority.index);
    }

    if (query != null && query.isNotEmpty) {
      where += ' AND (title LIKE ? OR description LIKE ?)';
      args.addAll(['%$query%', '%$query%']);
    }

    final rows = await db.query('tasks',
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'is_completed ASC, priority DESC, CASE WHEN deadline IS NULL THEN 1 ELSE 0 END, deadline ASC');

    final tasks = <Task>[];
    for (final row in rows) {
      final task = Task.fromMap(row);
      tasks.add(task.copyWith(subtasks: await _getSubtasks(db, task.id)));
    }
    return tasks;
  }

  Future<List<Task>> getTasksDueToday() async {
    final db = await _database;
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await db.query(
      'tasks',
      where:
          'parent_id IS NULL AND is_completed = 0 AND deadline BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'priority DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getWithReminders() async {
    final db = await _database;
    final rows = await db.query('tasks',
        where: 'reminder_at IS NOT NULL AND is_completed = 0',
        orderBy: 'reminder_at ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> _getSubtasks(Database db, String parentId) async {
    final rows = await db.query('tasks',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'is_completed ASC, created_at ASC');
    return rows.map(Task.fromMap).toList();
  }

  // ---- Notification settings ----

  Future<String?> getSoundPath(String taskId) async {
    final db = await _database;
    final rows = await db.query('notification_settings',
        where: 'task_id = ?', whereArgs: [taskId]);
    if (rows.isEmpty) return null;
    return rows.first['sound_file_path'] as String?;
  }

  Future<void> setSoundPath(String taskId, String? filePath) async {
    final db = await _database;
    await db.insert(
        'notification_settings',
        {'task_id': taskId, 'sound_file_path': filePath},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
