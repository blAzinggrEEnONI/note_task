import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:notetask_pro/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:notetask_pro/features/tasks/presentation/task_creation_sheet.dart';
import 'package:notetask_pro/shared/widgets/shared_widgets.dart';

final _taskDetailProvider =
    FutureProvider.family<Task?, String>((ref, taskId) {
  return ref.watch(taskDaoProvider).getById(taskId);
});

class TaskDetailPage extends ConsumerWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(_taskDetailProvider(taskId));
    final cs = Theme.of(context).colorScheme;

    return taskAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyStateWidget(
                icon: Icons.error_outline, title: 'Task not found'),
          );
        }
        return _TaskDetailView(task: task);
      },
    );
  }
}

class _TaskDetailView extends ConsumerStatefulWidget {
  final Task task;
  const _TaskDetailView({required this.task});

  @override
  ConsumerState<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends ConsumerState<_TaskDetailView> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _toggleComplete() async {
    await ref.read(tasksProvider.notifier).toggleComplete(_task);
    setState(() => _task = _task.copyWith(
        isCompleted: !_task.isCompleted,
        completedAt: !_task.isCompleted ? DateTime.now() : null));
  }

  Future<void> _addSubtask() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskCreationSheet(
        parentTask: _task,
        onSave: (subtask) async {
          await ref.read(tasksProvider.notifier).addSubtask(subtask);
          ref.invalidate(_taskDetailProvider(_task.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete task?'),
                  content:
                      const Text('This will also delete all subtasks.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(tasksProvider.notifier).deleteTask(_task.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title + complete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleComplete,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(top: 4),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _task.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                        color: _task.isCompleted ? Colors.green : cs.outline,
                        width: 2.5),
                  ),
                  child: _task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: _task.isCompleted
                          ? TextDecoration.lineThrough
                          : null),
                ),
              ),
            ],
          ),

          if (_task.description != null && _task.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_task.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: cs.onSurface.withOpacity(0.75))),
          ],

          const SizedBox(height: 20),

          // Meta chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PriorityBadge(priority: _task.priority),
              if (_task.deadline != null)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('EEE, MMM d yyyy').format(_task.deadline!),
                  color: _task.isOverdue ? Colors.red : cs.secondary,
                ),
              if (_task.reminderAt != null)
                _InfoChip(
                  icon: Icons.notifications_active_outlined,
                  label: DateFormat('MMM d, h:mm a').format(_task.reminderAt!),
                  color: cs.tertiary,
                ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Subtasks section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtasks',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: _addSubtask,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),

          if (_task.subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No subtasks yet',
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.45), fontSize: 14)),
            )
          else
            ..._task.subtasks.map((sub) => _SubtaskTile(
                  subtask: sub,
                  onToggle: () async {
                    await ref
                        .read(tasksProvider.notifier)
                        .toggleComplete(sub);
                    ref.invalidate(_taskDetailProvider(_task.id));
                  },
                )),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  final Task subtask;
  final VoidCallback onToggle;
  const _SubtaskTile({required this.subtask, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: subtask.isCompleted ? Colors.green : Colors.transparent,
            border: Border.all(
                color: subtask.isCompleted ? Colors.green : cs.outline,
                width: 1.5),
          ),
          child: subtask.isCompleted
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        subtask.title,
        style: TextStyle(
          fontSize: 14,
          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
          color: subtask.isCompleted
              ? cs.onSurface.withOpacity(0.45)
              : cs.onSurface,
        ),
      ),
    );
  }
}
