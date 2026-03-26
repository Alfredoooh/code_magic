import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/date_utils.dart';
import 'category_icon.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          children: [
            SlidableAction(
              onPressed: (_) => provider.deleteTask(task.id),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              icon: LucideIcons.trash_2,
              label: 'Apagar',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF22222F)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2D2D3D)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCheckbox(context),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(context),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildDescription(context),
                        ],
                        const SizedBox(height: 10),
                        _buildMetaRow(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final provider = context.read<TaskProvider>();
    return GestureDetector(
      onTap: () => provider.toggleTaskCompletion(task.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? task.category.color
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: task.isCompleted
                ? task.category.color
                : const Color(0xFFD1D5DB),
            width: 2,
          ),
        ),
        child: task.isCompleted
            ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      task.title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: task.isCompleted
            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.4)
            : theme.textTheme.bodyLarge?.color,
        decoration:
            task.isCompleted ? TextDecoration.lineThrough : null,
        decorationColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      task.description!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        height: 1.4,
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        CategoryIcon(category: task.category, size: 12, showBackground: false),
        const SizedBox(width: 4),
        Text(
          task.category.label,
          style: TextStyle(
            fontSize: 12,
            color: task.category.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        _buildPriorityBadge(),
        const Spacer(),
        if (task.dueDate != null) _buildDueDate(context, isDark),
        if (task.subTasks.isNotEmpty) ...[
          const SizedBox(width: 8),
          _buildSubTaskProgress(context),
        ],
      ],
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: task.priority.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.priority.label,
        style: TextStyle(
          fontSize: 11,
          color: task.priority.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDueDate(BuildContext context, bool isDark) {
    final isOverdue = AppDateUtils.isOverdue(task.dueDate) && !task.isCompleted;
    final color = isOverdue
        ? const Color(0xFFEF4444)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.calendar, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          AppDateUtils.formatDate(task.dueDate!),
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSubTaskProgress(BuildContext context) {
    final completed = task.subTasks.where((s) => s.isCompleted).length;
    final total = task.subTasks.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.list_checks,
          size: 12,
          color: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 4),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
