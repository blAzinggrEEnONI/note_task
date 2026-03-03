import 'package:flutter/material.dart';
import 'package:notetask_pro/app/theme/color_scheme.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool compact;
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  Color get _color => switch (priority) {
        TaskPriority.low => AppColorScheme.priorityLow,
        TaskPriority.medium => AppColorScheme.priorityMedium,
        TaskPriority.high => AppColorScheme.priorityHigh,
        TaskPriority.urgent => AppColorScheme.priorityUrgent,
      };

  String get _label => switch (priority) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
        TaskPriority.urgent => 'Urgent',
      };

  IconData get _icon => switch (priority) {
        TaskPriority.low => Icons.arrow_downward,
        TaskPriority.medium => Icons.remove,
        TaskPriority.high => Icons.arrow_upward,
        TaskPriority.urgent => Icons.priority_high,
      };

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(_label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onDeleted;
  const TagChip({super.key, required this.label, this.color, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = color != null
        ? Color(color!.value).withOpacity(0.15)
        : cs.primaryContainer;
    final fg = color != null ? Color(color!.value) : cs.onPrimaryContainer;

    return Container(
      padding:
          EdgeInsets.only(left: 8, right: onDeleted != null ? 2 : 8, top: 3, bottom: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$label',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
          if (onDeleted != null)
            GestureDetector(
              onTap: onDeleted,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.close, size: 12, color: fg),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
