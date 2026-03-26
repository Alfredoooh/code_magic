import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  static const String _storageKey = 'tasks_data';
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskCategory? _filterCategory;
  TaskPriority? _filterPriority;
  bool _showCompleted = true;

  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => _tasks;
  String get searchQuery => _searchQuery;
  TaskCategory? get filterCategory => _filterCategory;
  TaskPriority? get filterPriority => _filterPriority;
  bool get showCompleted => _showCompleted;

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasks => _tasks.where((t) => !t.isCompleted).length;

  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  List<Task> get overdueTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      return t.dueDate!.isBefore(now);
    }).toList();
  }

  Map<TaskCategory, int> get tasksByCategory {
    final map = <TaskCategory, int>{};
    for (final category in TaskCategory.values) {
      map[category] = _tasks.where((t) => t.category == category).length;
    }
    return map;
  }

  List<Task> _getFilteredTasks() {
    List<Task> filtered = List.from(_tasks);

    if (!_showCompleted) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }

    if (_filterCategory != null) {
      filtered =
          filtered.where((t) => t.category == _filterCategory).toList();
    }

    if (_filterPriority != null) {
      filtered =
          filtered.where((t) => t.priority == _filterPriority).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.priority.index.compareTo(a.priority.index);
    });

    return filtered;
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((t) => Task.fromJson(t)).toList();
      notifyListeners();
    } else {
      _loadSampleTasks();
    }
  }

  void _loadSampleTasks() {
    final now = DateTime.now();
    _tasks = [
      Task(
        id: _uuid.v4(),
        title: 'Revisar relatório trimestral',
        description: 'Analisar os dados do Q1 e preparar apresentação para a equipa.',
        priority: TaskPriority.high,
        category: TaskCategory.work,
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 1)),
      ),
      Task(
        id: _uuid.v4(),
        title: 'Ir ao ginásio',
        description: 'Treino de força — 45 minutos.',
        priority: TaskPriority.medium,
        category: TaskCategory.health,
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Comprar mantimentos',
        description: 'Leite, ovos, pão, frutas e legumes.',
        priority: TaskPriority.low,
        category: TaskCategory.shopping,
        createdAt: now,
        dueDate: now.add(const Duration(days: 2)),
        subTasks: [
          SubTask(id: _uuid.v4(), title: 'Leite e ovos'),
          SubTask(id: _uuid.v4(), title: 'Pão integral'),
          SubTask(id: _uuid.v4(), title: 'Frutas da época'),
        ],
      ),
      Task(
        id: _uuid.v4(),
        title: 'Estudar Flutter avançado',
        description: 'Concluir o módulo de animações e state management.',
        priority: TaskPriority.high,
        category: TaskCategory.education,
        createdAt: now.subtract(const Duration(days: 3)),
        isCompleted: true,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Pagar fatura do cartão',
        priority: TaskPriority.high,
        category: TaskCategory.finance,
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 3)),
      ),
    ];
    _saveTasks();
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson =
        jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, tasksJson);
  }

  Future<void> addTask(Task task) async {
    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final subTaskIndex = _tasks[taskIndex]
          .subTasks
          .indexWhere((s) => s.id == subTaskId);
      if (subTaskIndex != -1) {
        _tasks[taskIndex].subTasks[subTaskIndex].isCompleted =
            !_tasks[taskIndex].subTasks[subTaskIndex].isCompleted;
        await _saveTasks();
        notifyListeners();
      }
    }
  }

  String generateId() => _uuid.v4();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(TaskCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategory = null;
    _filterPriority = null;
    _searchQuery = '';
    _showCompleted = true;
    notifyListeners();
  }
}
