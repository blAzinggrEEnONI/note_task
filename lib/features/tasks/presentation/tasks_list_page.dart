import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:notetask_pro/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:notetask_pro/features/tasks/presentation/task_creation_sheet.dart';
import 'package:notetask_pro/shared/widgets/shared_widgets.dart';

class TasksListPage extends ConsumerWidget {
  const TasksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final filter = ref.watch(tasksProvider.notifier).filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(filter.showCompleted 
                ? Icons.visibility_off_outlined 
                : Icons.visibility_outlined),
            tooltip: filter.showCompleted ? 'Hide completed' : 'Show completed',
            onPressed: () {
              ref.read(tasksProvider.notifier).setFilter(
                filter.copyWith(showCompleted: !filter.showCompleted),
              );
            },
          ),
          PopupMenuButton<_TaskSort>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (_) {},
            itemBuilder: (_) => const [
              PopupMenuItem(value: _TaskSort.deadline, child: Text('By deadline')),
              PopupMenuItem(value: _TaskSort.priority, child: Text('By priority')),
              PopupMenuItem(value: _TaskSort.created, child: Text('By created')),
            ],
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.check_circle_outline,
              title: 'No tasks yet',
              subtitle: 'Add tasks to stay on top of your day',
              action: FilledButton.icon(
                onPressed: () => _showCreateSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
              ),
            );
          }

          final today = tasks
              .where((t) => t.isDueToday && !t.isCompleted)
              .toList();
          final upcoming = tasks
              .where((t) => !t.isDueToday && t.deadline != null && !t.isCompleted)
              .toList();
          final noDeadline = tasks
              .where((t) => t.deadline == null && !t.isCompleted)
              .toList();
          final completed = filter.showCompleted 
              ? tasks.where((t) => t.isCompleted).toList()
              : <Task>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              if (today.isNotEmpty) ...[
                _SectionHeader(
                    title: 'Today',
                    count: today.length,
                    color: Theme.of(context).colorScheme.primary),
                ...today.map((t) => _TaskTile(task: t)),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming', count: upcoming.length),
                ...upcoming.map((t) => _TaskTile(task: t)),
                const SizedBox(height: 16),
              ],
              if (noDeadline.isNotEmpty) ...[
                _SectionHeader(title: 'No Date', count: noDeadline.length),
                ...noDeadline.map((t) => _TaskTile(task: t)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                    title: 'Completed',
                    count: completed.length,
                    color: Colors.green),
                ...completed.map((t) => _TaskTile(task: t)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskCreationSheet(
        onSave: (task) =>
            ref.read(tasksProvider.notifier).createTask(task),
      ),
    );
  }
}

enum _TaskSort { deadline, priority, created }

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;
  const _SectionHeader({required this.title, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? cs.onSurface.withOpacity(0.6),
                  letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: (color ?? cs.onSurface).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color ?? cs.onSurface.withOpacity(0.6))),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/tasks/${task.id}'),
          onLongPress: task.isCompleted ? () => _showDeleteDialog(context, ref) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => ref
                      .read(tasksProvider.notifier)
                      .toggleComplete(task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? Colors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? Colors.green
                            : cs.outline,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? cs.onSurface.withOpacity(0.45)
                              : cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          PriorityBadge(priority: task.priority),
                          if (task.deadline != null)
                            _DeadlineChip(deadline: task.deadline!, isOverdue: task.isOverdue),
                          if (task.reminderAt != null)
                            const Icon(Icons.notifications_active_outlined,
                                size: 14),
                          if (task.subtasks.isNotEmpty)
                            Text(
                              '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.5)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (task.isCompleted)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _showDeleteDialog(context, ref),
                    color: cs.error,
                  )
                else
                  Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This will permanently delete this task and all its subtasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
    }
  }
}

class _DeadlineChip extends StatelessWidget {
  final DateTime deadline;
  final bool isOverdue;
  const _DeadlineChip({required this.deadline, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? Colors.red : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 10, color: color),
          const SizedBox(width: 3),
          Text(DateFormat('MMM d').format(deadline),
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
