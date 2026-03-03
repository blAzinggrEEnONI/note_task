import 'package:flutter/material.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:intl/intl.dart';

class TaskCreationSheet extends StatefulWidget {
  final Function(Task) onSave;
  final Task? parentTask;
  const TaskCreationSheet({super.key, required this.onSave, this.parentTask});

  @override
  State<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<TaskCreationSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _deadline;
  DateTime? _reminder;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() => _reminder = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final task = Task.create(
      title: title,
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      priority: _priority,
      deadline: _deadline,
      reminderAt: _reminder,
      parentId: widget.parentTask?.id,
    );
    widget.onSave(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.parentTask != null
                    ? 'Add Subtask to "${widget.parentTask!.title}"'
                    : 'New Task',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title *',
                  prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Priority selector
              Text('Priority',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = p == _priority;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(_priorityLabel(p), style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _priority = p),
                        selectedColor: _priorityColor(p).withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: isSelected
                                ? _priorityColor(p)
                                : null),
                        side: isSelected
                            ? BorderSide(color: _priorityColor(p))
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Deadline & reminder
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        _deadline == null
                            ? 'Deadline'
                            : DateFormat('MMM d').format(_deadline!),
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: _pickDeadline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_outlined, size: 16),
                      label: Text(
                        _reminder == null
                            ? 'Reminder'
                            : DateFormat('MMM d, h:mm a').format(_reminder!),
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: _pickReminder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Add Task'),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
        TaskPriority.urgent => 'Urgent',
      };

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.low => Colors.green,
        TaskPriority.medium => Colors.orange,
        TaskPriority.high => Colors.deepOrange,
        TaskPriority.urgent => Colors.red,
      };
}
