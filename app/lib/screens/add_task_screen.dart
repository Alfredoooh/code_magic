import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/category_icon.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  final TaskCategory? defaultCategory;

  const AddTaskScreen({
    super.key,
    this.taskToEdit,
    this.defaultCategory,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskCategory _category;
  DateTime? _dueDate;
  final List<TextEditingController> _subTaskControllers = [];
  final List<bool> _subTaskCompleted = [];

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? widget.defaultCategory ?? TaskCategory.personal;
    _dueDate = task?.dueDate;

    if (task != null) {
      for (final subTask in task.subTasks) {
        _subTaskControllers.add(TextEditingController(text: subTask.title));
        _subTaskCompleted.add(subTask.isCompleted);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _subTaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saveTask,
              child: Text(_isEditing ? 'Guardar' : 'Criar'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Título da tarefa...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Insira um título' : null,
                maxLines: null,
              ),
              const SizedBox(height: 12),

              // Description field
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Adicionar descrição...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                minLines: 2,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Category selector
              _SectionLabel(
                icon: LucideIcons.tag,
                label: 'Categoria',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: TaskCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withOpacity(0.15)
                                : (isDark
                                    ? const Color(0xFF22222F)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color
                                  : (isDark
                                      ? const Color(0xFF2D2D3D)
                                      : const Color(0xFFE5E7EB)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryIcon(
                                  category: cat,
                                  size: 14,
                                  showBackground: false),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? cat.color
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Priority selector
              _SectionLabel(
                icon: LucideIcons.flag,
                label: 'Prioridade',
              ),
              const SizedBox(height: 10),
              Row(
                children: TaskPriority.values.map((p) {
                  final isSelected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.color.withOpacity(0.15)
                                : (isDark
                                    ? const Color(0xFF22222F)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? p.color
                                  : (isDark
                                      ? const Color(0xFF2D2D3D)
                                      : const Color(0xFFE5E7EB)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.flag,
                                size: 18,
                                color: isSelected
                                    ? p.color
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? p.color
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Due date
              _SectionLabel(
                icon: LucideIcons.calendar,
                label: 'Prazo',
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF22222F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2D2D3D)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: _dueDate != null
                            ? const Color(0xFF6366F1)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Selecionar data de prazo',
                          style: TextStyle(
                            fontSize: 15,
                            color: _dueDate != null
                                ? (isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF111827))
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sub-tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(
                    icon: LucideIcons.list_checks,
                    label: 'Sub-tarefas',
                  ),
                  TextButton.icon(
                    onPressed: _addSubTask,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Adicionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._subTaskControllers.asMap().entries.map(
                    (e) => _SubTaskField(
                      controller: e.value,
                      onRemove: () => _removeSubTask(e.key),
                    ),
                  ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _addSubTask() {
    setState(() {
      _subTaskControllers.add(TextEditingController());
      _subTaskCompleted.add(false);
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTaskControllers[index].dispose();
      _subTaskControllers.removeAt(index);
      _subTaskCompleted.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF6366F1),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    final subTasks = _subTaskControllers
        .asMap()
        .entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map(
          (e) => SubTask(
            id: _isEditing && e.key < (widget.taskToEdit?.subTasks.length ?? 0)
                ? widget.taskToEdit!.subTasks[e.key].id
                : provider.generateId(),
            title: e.value.text.trim(),
            isCompleted: _isEditing &&
                    e.key < _subTaskCompleted.length
                ? _subTaskCompleted[e.key]
                : false,
          ),
        )
        .toList();

    if (_isEditing) {
      final updated = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        subTasks: subTasks,
      );
      provider.updateTask(updated);
    } else {
      final task = Task(
        id: provider.generateId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _priority,
        category: _category,
        createdAt: DateTime.now(),
        dueDate: _dueDate,
        subTasks: subTasks,
      );
      provider.addTask(task);
    }

    Navigator.pop(context);
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

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
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _SubTaskField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onRemove;

  const _SubTaskField({
    required this.controller,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.grip_vertical,
            size: 16,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Sub-tarefa...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF2D2D3D)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF2D2D3D)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              LucideIcons.x,
              size: 18,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
