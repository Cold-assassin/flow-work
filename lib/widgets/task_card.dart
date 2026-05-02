import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final List<ProjectMember> members;
  final VoidCallback? onTap;
  final void Function(String)? onStatusChange;
  final VoidCallback? onDelete;
  final bool canEdit;

  const TaskCard({
    super.key,
    required this.task,
    this.members = const [],
    this.onTap,
    this.onStatusChange,
    this.onDelete,
    this.canEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.priorityColor(task.priority);
    final statusColor = AppTheme.statusColor(task.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isOverdue
                ? AppTheme.danger.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: task.isOverdue
              ? [BoxShadow(color: AppTheme.danger.withOpacity(0.08), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: task.isDone ? AppTheme.onSurfaceMuted : AppTheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(TaskStatus.label(task.status),
                              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(task.description!,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (task.assignee != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppTheme.first.withOpacity(0.2),
                                child: Text(task.assignee!.initials,
                                    style: const TextStyle(fontSize: 9, color: AppTheme.first, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 5),
                              Text(task.assignee!.fullName.split(' ').first,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted)),
                            ],
                          ),
                        const Spacer(),
                        if (task.dueDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: task.isOverdue ? AppTheme.danger : AppTheme.onSurfaceMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${task.dueDate!.day}/${task.dueDate!.month}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: task.isOverdue ? AppTheme.danger : AppTheme.onSurfaceMuted,
                                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onDelete,
                            child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}