import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/category_icon.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    // Get the latest version of the task
    final currentTask = provider.allTasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(taskToEdit: currentTask),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash_2, size: 20),
            onPressed: () => _confirmDelete(context, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion toggle
            GestureDetector(
              onTap: () => provider.toggleTaskCompletion(currentTask.id),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: currentTask.isCompleted
                          ? currentTask.category.color
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentTask.isCompleted
                            ? currentTask.category.color
                            : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                    ),
                    child: currentTask.isCompleted
                        ? const Icon(LucideIcons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currentTask.isCompleted
                        ? 'Concluída'
                        : 'Marcar como concluída',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: currentTask.isCompleted
                          ? currentTask.category.color
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              currentTask.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: currentTask.isCompleted
                    ? (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF9CA3AF))
                    : (isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF111827)),
                decoration: currentTask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),

            if (currentTask.description != null &&
                currentTask.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                currentTask.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Metadata
            _MetaRow(
              icon: LucideIcons.tag,
              label: 'Categoria',
              child: Row(
                children: [
                  CategoryIcon(
                      category: currentTask.category,
                      size: 14,
                      showBackground: false),
                  const SizedBox(width: 6),
                  Text(
                    currentTask.category.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentTask.category.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _MetaRow(
              icon: LucideIcons.flag,
              label: 'Prioridade',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: currentTask.priority.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentTask.priority.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentTask.priority.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _MetaRow(
              icon: LucideIcons.calendar,
              label: 'Criada em',
              child: Text(
                AppDateUtils.formatFullDate(currentTask.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),

            if (currentTask.dueDate != null) ...[
              const SizedBox(height: 12),
              _MetaRow(
                icon: LucideIcons.calendar_clock,
                label: 'Prazo',
                child: Text(
                  AppDateUtils.formatFullDate(currentTask.dueDate!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppDateUtils.isOverdue(currentTask.dueDate) &&
                            !currentTask.isCompleted
                        ? const Color(0xFFEF4444)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ],

            // Sub-tasks
            if (currentTask.subTasks.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(LucideIcons.list_checks,
                      size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 8),
                  Text(
                    'Sub-tarefas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentTask.subTasks.where((s) => s.isCompleted).length}/${currentTask.subTasks.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...currentTask.subTasks.map(
                (subTask) => _SubTaskTile(
                  subTask: subTask,
                  taskId: currentTask.id,
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Apagar tarefa'),
        content: const Text(
            'Tem a certeza que deseja apagar esta tarefa? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SubTaskTile extends StatelessWidget {
  final SubTask subTask;
  final String taskId;

  const _SubTaskTile({
    required this.subTask,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => provider.toggleSubTask(taskId, subTask.id),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subTask.isCompleted
                    ? const Color(0xFF6366F1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: subTask.isCompleted
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: subTask.isCompleted
                  ? const Icon(LucideIcons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subTask.title,
                style: TextStyle(
                  fontSize: 14,
                  color: subTask.isCompleted
                      ? (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF9CA3AF))
                      : (isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF111827)),
                  decoration: subTask.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
