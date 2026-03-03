import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high, urgent }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? parentId;
  final String? noteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Task> subtasks;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.deadline,
    this.reminderAt,
    this.isCompleted = false,
    this.completedAt,
    this.parentId,
    this.noteId,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
  });

  factory Task.create({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? deadline,
    DateTime? reminderAt,
    String? parentId,
    String? noteId,
  }) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      reminderAt: reminderAt,
      parentId: parentId,
      noteId: noteId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    DateTime? reminderAt,
    bool? isCompleted,
    DateTime? completedAt,
    String? parentId,
    String? noteId,
    List<Task>? subtasks,
    bool clearDeadline = false,
    bool clearReminder = false,
    bool clearNote = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      parentId: parentId ?? this.parentId,
      noteId: clearNote ? null : (noteId ?? this.noteId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subtasks: subtasks ?? this.subtasks,
    );
  }

  bool get isOverdue =>
      deadline != null && !isCompleted && deadline!.isBefore(DateTime.now());

  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
        deadline!.month == now.month &&
        deadline!.day == now.day;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.index,
        'deadline': deadline?.millisecondsSinceEpoch,
        'reminder_at': reminderAt?.millisecondsSinceEpoch,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'parent_id': parentId,
        'note_id': noteId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        priority: TaskPriority.values[map['priority'] as int],
        deadline: map['deadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
            : null,
        reminderAt: map['reminder_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['reminder_at'] as int)
            : null,
        isCompleted: (map['is_completed'] as int) == 1,
        completedAt: map['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
            : null,
        parentId: map['parent_id'] as String?,
        noteId: map['note_id'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
}
