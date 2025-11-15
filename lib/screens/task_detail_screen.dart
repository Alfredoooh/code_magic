// lib/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import 'unified_editor_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF4CAF50);
      case TaskPriority.medium:
        return const Color(0xFFFFC107);
      case TaskPriority.high:
        return const Color(0xFFFF5722);
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baixa';
      case TaskPriority.medium:
        return 'Média';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  String _formatFullDate(DateTime date) {
    final weekDays = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${weekDays[date.weekday % 7]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _toggleComplete() async {
    try {
      await _taskService.toggleTaskCompletion(_task.id, !_task.isCompleted);
      setState(() {
        _task = _task.copyWith(isCompleted: !_task.isCompleted);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_task.isCompleted ? 'Tarefa concluída!' : 'Tarefa reaberta'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar tarefa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Excluir tarefa?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        content: Text(
          'Esta ação não pode ser desfeita.',
          style: TextStyle(color: secondaryColor, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: const Color(0xFF1877F2),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(_task.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarefa excluída com sucesso'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir tarefa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedEditorScreen(
          userId: _task.userId,
          editorType: EditorType.task,
          task: _task,
        ),
      ),
    );
  }

  void _showOptions() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFF1877F2), size: 22),
                  ),
                  title: Text(
                    'Editar tarefa',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editTask();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _task.isCompleted ? Icons.replay : Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _task.isCompleted ? 'Marcar como pendente' : 'Marcar como concluída',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleComplete();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  ),
                  title: const Text(
                    'Excluir tarefa',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTask();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final priorityColor = _getPriorityColor(_task.priority);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.more_vert, color: textColor, size: 26),
                onPressed: _showOptions,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status e Prioridade
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleComplete,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _task.isCompleted
                              ? const Color(0xFF4CAF50)
                              : Colors.transparent,
                          border: Border.all(
                            color: _task.isCompleted
                                ? const Color(0xFF4CAF50)
                                : priorityColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _task.isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _task.isCompleted ? 'Concluída' : 'Pendente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _task.isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : priorityColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: priorityColor, width: 1.5),
                            ),
                            child: Text(
                              'Prioridade ${_getPriorityLabel(_task.priority)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  _task.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: -0.5,
                    decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Descrição
                if (_task.description != null && _task.description!.isNotEmpty) ...[
                  Text(
                    _task.description!,
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      height: 1.7,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Data de vencimento
                if (_task.dueDate != null) ...[
                  _buildInfoSection(
                    icon: Icons.calendar_today,
                    title: 'Data de vencimento',
                    content: _formatFullDate(_task.dueDate!),
                    color: secondaryColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                ],

                // Horário
                if (_task.dueTime != null) ...[
                  _buildInfoSection(
                    icon: Icons.access_time,
                    title: 'Horário',
                    content: '${_task.dueTime!.hour.toString().padLeft(2, '0')}:${_task.dueTime!.minute.toString().padLeft(2, '0')}',
                    color: secondaryColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                ],

                // Lembrete
                if (_task.hasReminder && _task.reminderDateTime != null) ...[
                  _buildInfoSection(
                    icon: Icons.notifications_active,
                    title: 'Lembrete',
                    content: _formatFullDate(_task.reminderDateTime!),
                    color: const Color(0xFFFF9800),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (_task.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _task.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1877F2), width: 1.5),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1877F2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Metadados
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: secondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Criado em ${_formatFullDate(_task.createdAt)}',
                            style: TextStyle(fontSize: 13, color: secondaryColor),
                          ),
                        ],
                      ),
                      if (_task.updatedAt.difference(_task.createdAt).inSeconds > 60) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Atualizado em ${_formatFullDate(_task.updatedAt)}',
                              style: TextStyle(fontSize: 13, color: secondaryColor),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}