import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProductivityTab extends StatefulWidget {
  const ProductivityTab({Key? key}) : super(key: key);

  @override
  State<ProductivityTab> createState() => _ProductivityTabState();
}

class _ProductivityTabState extends State<ProductivityTab> {
  final List<TodoItem> _todos = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addTodo() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _todos.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _textController.text.trim(),
        isCompleted: false,
        createdAt: DateTime.now(),
      ));
      _textController.clear();
    });
  }

  void _toggleTodo(String id) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
      }
    });
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _todos.where((t) => t.isCompleted).length;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        border: null,
        middle: const Text(
          'Produtividade',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_todos.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF007AFF).withOpacity(0.2),
                              const Color(0xFF1C1C1E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tarefas',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_todos.length}',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF34C759).withOpacity(0.2),
                              const Color(0xFF1C1C1E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Concluídas',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completedCount',
                              style: const TextStyle(
                                color: Color(0xFF34C759),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _todos.isEmpty
                  ? _buildEmptyState()
                  : _buildTodoList(),
            ),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              CupertinoIcons.checkmark_circle,
              size: 64,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma tarefa',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione uma nova tarefa abaixo',
            style: TextStyle(
              color: const Color(0xFF8E8E93),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return _buildTodoItem(todo);
      },
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 1,
        ),
      ),
      child: CupertinoListTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: GestureDetector(
          onTap: () => _toggleTodo(todo.id),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: todo.isCompleted
                    ? const Color(0xFF34C759)
                    : const Color(0xFF3A3A3C),
                width: 2,
              ),
              color: todo.isCompleted
                  ? const Color(0xFF34C759)
                  : Colors.transparent,
            ),
            child: todo.isCompleted
                ? const Icon(
                    CupertinoIcons.check_mark,
                    size: 16,
                    color: Color(0xFFFFFFFF),
                  )
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isCompleted
                ? const Color(0xFF8E8E93)
                : const Color(0xFFFFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: todo.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _deleteTodo(todo.id),
          child: const Icon(
            CupertinoIcons.delete,
            color: Color(0xFFFF3B30),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2C2C2E),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              placeholder: 'Nova tarefa...',
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
              ),
              placeholderStyle: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              onSubmitted: (_) => _addTodo(),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(12),
            onPressed: _addTodo,
            child: const Icon(
              CupertinoIcons.add,
              color: Color(0xFFFFFFFF),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}