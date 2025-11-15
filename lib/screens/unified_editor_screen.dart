// lib/screens/unified_editor_screen.dart (versão corrigida, corrigido _task_service para _taskService)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/diary_service.dart';
import '../services/task_service.dart';
import '../services/note_service.dart';
// Conditional import: use stub on web to avoid flutter_local_notifications / platform issues
import '../services/notification_service.dart'
    if (dart.library.html) '../services/notification_service_stub.dart';
import '../models/diary_entry_model.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../widgets/custom_icons.dart';
import '../widgets/rich_text_field.dart';

enum EditorType { diary, task, note }

class UnifiedEditorScreen extends StatefulWidget {
  final String userId;
  final EditorType editorType;
  final DiaryEntry? diaryEntry;
  final Task? task;
  final Note? note;

  const UnifiedEditorScreen({
    super.key,
    required this.userId,
    required this.editorType,
    this.diaryEntry,
    this.task,
    this.note,
  });

  @override
  State<UnifiedEditorScreen> createState() => _UnifiedEditorScreenState();
}

class _UnifiedEditorScreenState extends State<UnifiedEditorScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  final TaskService _taskService = TaskService();
  final NoteService _noteService = NoteService(); // Corrigido para _noteService (padronizado)
  final NotificationService _notificationService = NotificationService();

  // Controllers & keys
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();
  final GlobalKey<RichTextFieldState> _richTextKey = GlobalKey();

  late TabController _tabController;

  // Diary
  DiaryMood _selectedMood = DiaryMood.happy;
  List<String> _tags = [];

  // Task
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _hasReminder = false;
  DateTime? _reminderDateTime;
  TaskPriority _priority = TaskPriority.medium;
  bool _isCompleted = false;

  // Note
  String _noteCategory = 'Geral';
  bool _isPinned = false;

  bool _isSaving = false;
  String _selectedFont = 'System';

  final List<String> _availableFonts = ['System', 'Serif', 'Monospace', 'Cursive'];
  final List<String> _noteCategories = ['Geral', 'Aula', 'Trabalho', 'Pessoal', 'Ideias'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadExistingData();

    // Initialize notification service only on mobile (avoid web runtime errors)
    if (!kIsWeb) {
      try {
        _notificationService.initialize();
      } catch (e) {
        // Guard just in case the implementation throws on some platforms
        debugPrint('⚠️ Falha ao inicializar NotificationService: $e');
      }
    } else {
      debugPrint('ℹ️ NotificationService não inicializado no web (stub em uso).');
    }
  }

  void _loadExistingData() {
    switch (widget.editorType) {
      case EditorType.diary:
        if (widget.diaryEntry != null) {
          _titleController.text = widget.diaryEntry!.title;
          _contentController.text = widget.diaryEntry!.content;
          _selectedMood = widget.diaryEntry!.mood;
          _tags = List.from(widget.diaryEntry!.tags);
        }
        break;
      case EditorType.task:
        if (widget.task != null) {
          _titleController.text = widget.task!.title;
          _contentController.text = widget.task!.description ?? '';
          _dueDate = widget.task!.dueDate;
          _dueTime = widget.task!.dueTime;
          _hasReminder = widget.task!.hasReminder;
          _reminderDateTime = widget.task!.reminderDateTime;
          _priority = widget.task!.priority;
          _isCompleted = widget.task!.isCompleted;
          _tags = List.from(widget.task!.tags);
        }
        break;
      case EditorType.note:
        if (widget.note != null) {
          _titleController.text = widget.note!.title;
          _contentController.text = widget.note!.content;
          _noteCategory = widget.note!.category;
          _isPinned = widget.note!.isPinned;
          _tags = List.from(widget.note!.tags);
        }
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        DateTime tempDate = _dueDate ?? now;
        return Container(
          height: 300,
          color: context.read<ThemeProvider>().isDarkMode 
              ? Color(0xFF242526) 
              : Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmar'),
                    onPressed: () {
                      setState(() => _dueDate = tempDate);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: now,
                  onDateTimeChanged: (date) => tempDate = date,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectTime() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        TimeOfDay tempTime = _dueTime ?? TimeOfDay.now();
        return Container(
          height: 300,
          color: context.read<ThemeProvider>().isDarkMode 
              ? Color(0xFF242526) 
              : Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmar'),
                    onPressed: () {
                      setState(() => _dueTime = tempTime);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2024, 1, 1, tempTime.hour, tempTime.minute),
                  onDateTimeChanged: (date) {
                    tempTime = TimeOfDay(hour: date.hour, minute: date.minute);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectReminderDateTime() async {
    final now = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        DateTime tempDateTime = _reminderDateTime ?? now;
        return Container(
          height: 300,
          color: context.read<ThemeProvider>().isDarkMode 
              ? Color(0xFF242526) 
              : Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmar'),
                    onPressed: () {
                      setState(() {
                        _reminderDateTime = tempDateTime;
                        _hasReminder = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: tempDateTime,
                  minimumDate: now,
                  onDateTimeChanged: (date) => tempDateTime = date,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scheduleNotification() async {
    if (_reminderDateTime != null && _hasReminder) {
      await _notificationService.scheduleNotification(
        id: widget.task?.id.hashCode ?? DateTime.now().millisecondsSinceEpoch,
        title: 'Lembrete: ${_titleController.text}',
        body: _contentController.text.isNotEmpty 
            ? _contentController.text.substring(0, _contentController.text.length > 100 ? 100 : _contentController.text.length)
            : 'Você tem uma tarefa pendente',
        scheduledDate: _reminderDateTime!,
      );
    }
  }

  void _showFontPicker() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? Color(0xFF242526) : Colors.white;
    final textColor = isDark ? Color(0xFFE4E6EB) : Color(0xFF050505);

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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Escolher fonte',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._availableFonts.map((font) {
                  return ListTile(
                    leading: Text(
                      'Aa',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: _getFontFamily(font),
                        color: _selectedFont == font
                            ? Color(0xFF1877F2)
                            : textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    title: Text(
                      font,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: _selectedFont == font ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: _selectedFont == font
                        ? Icon(Icons.check_circle, color: Color(0xFF1877F2))
                        : null,
                    onTap: () {
                      setState(() => _selectedFont = font);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _getFontFamily(String font) {
    switch (font) {
      case 'Serif': return 'serif';
      case 'Monospace': return 'monospace';
      case 'Cursive': return 'cursive';
      default: return null;
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _richTextKey.currentState?.getFormattedText() ?? _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O título é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      switch (widget.editorType) {
        case EditorType.diary:
          await _saveDiary(title, content);
          break;
        case EditorType.task:
          await _saveTask(title, content);
          break;
        case EditorType.note:
          await _saveNote(title, content);
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage()),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDiary(String title, String content) async {
    final entry = DiaryEntry(
      id: widget.diaryEntry?.id ?? '',
      userId: widget.userId,
      date: DateTime.now(),
      title: title,
      content: content,
      mood: _selectedMood,
      tags: _tags,
      isFavorite: widget.diaryEntry?.isFavorite ?? false,
      createdAt: widget.diaryEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.diaryEntry == null) {
      await _diaryService.createEntry(entry);
    } else {
      await _diaryService.updateEntry(entry);
    }
  }

  Future<void> _saveTask(String title, String content) async {
    final task = Task(
      id: widget.task?.id ?? '',
      userId: widget.userId,
      title: title,
      description: content.isEmpty ? null : content,
      dueDate: _dueDate,
      dueTime: _dueTime,
      hasReminder: _hasReminder,
      reminderDateTime: _reminderDateTime,
      priority: _priority,
      isCompleted: _isCompleted,
      tags: _tags,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.task == null) {
      await _taskService.createTask(task); // Corrigido _task_service para _taskService
    } else {
      await _taskService.updateTask(task); // Corrigido
    }

    if (_hasReminder && _reminderDateTime != null) {
      await _scheduleNotification();
    }
  }

  Future<void> _saveNote(String title, String content) async {
    final note = Note(
      id: widget.note?.id ?? '',
      userId: widget.userId,
      title: title,
      content: content,
      category: _noteCategory,
      isPinned: _isPinned,
      tags: _tags,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.note == null) {
      await _noteService.createNote(note); // Corrigido para _noteService
    } else {
      await _noteService.updateNote(note); // Corrigido
    }
  }

  String _getSuccessMessage() {
    final isNew = (widget.editorType == EditorType.diary && widget.diaryEntry == null) ||
                  (widget.editorType == EditorType.task && widget.task == null) ||
                  (widget.editorType == EditorType.note && widget.note == null);

    switch (widget.editorType) {
      case EditorType.diary:
        return isNew ? 'Entrada criada!' : 'Entrada atualizada!';
      case EditorType.task:
        return isNew ? 'Tarefa criada!' : 'Tarefa atualizada!';
      case EditorType.note:
        return isNew ? 'Anotação criada!' : 'Anotação atualizada!';
    }
  }

  String _getTitle() {
    final isNew = (widget.editorType == EditorType.diary && widget.diaryEntry == null) ||
                  (widget.editorType == EditorType.task && widget.task == null) ||
                  (widget.editorType == EditorType.note && widget.note == null);

    switch (widget.editorType) {
      case EditorType.diary:
        return isNew ? 'Nova Entrada' : 'Editar Entrada';
      case EditorType.task:
        return isNew ? 'Nova Tarefa' : 'Editar Tarefa';
      case EditorType.note:
        return isNew ? 'Nova Anotação' : 'Editar Anotação';
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Color(0xFF4CAF50);
      case TaskPriority.medium:
        return Color(0xFFFFC107);
      case TaskPriority.high:
        return Color(0xFFFF5722);
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? Color(0xFF18191A) : Color(0xFFF0F2F5);
    final cardColor = isDark ? Color(0xFF242526) : Colors.white;
    final textColor = isDark ? Color(0xFFE4E6EB) : Color(0xFF050505);
    final secondaryColor = isDark ? Color(0xFFB0B3B8) : Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isSaving)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(cardColor, textColor, secondaryColor, isDark),
            const SizedBox(height: 16),

            if (widget.editorType == EditorType.diary)
              _buildMoodSelector(cardColor, textColor, secondaryColor, isDark),

            if (widget.editorType == EditorType.task) ...[
              _buildTaskFields(cardColor, textColor, secondaryColor, isDark),
              const SizedBox(height: 16),
            ],

            if (widget.editorType == EditorType.note)
              _buildNoteFields(cardColor, textColor, secondaryColor, isDark),

            _buildContentField(cardColor, textColor, secondaryColor, isDark),
            const SizedBox(height: 16),

            _buildTagsField(cardColor, textColor, secondaryColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Título',
          hintStyle: TextStyle(color: secondaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        maxLines: null,
      ),
    );
  }

  Widget _buildMoodSelector(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como você se sente?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: DiaryMood.values.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFF1877F2)
                        : (isDark ? Color(0xFF3A3A3C) : Color(0xFFF0F2F5)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getMoodEmoji(mood), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        _getMoodLabel(mood),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFields(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Column(
      children: [
        // Data e hora
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTaskOption(
                icon: Icons.calendar_today,
                label: 'Data de vencimento',
                value: _dueDate != null 
                    ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                    : 'Não definida',
                onTap: _selectDate,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
              const Divider(height: 32),
              _buildTaskOption(
                icon: Icons.access_time,
                label: 'Horário',
                value: _dueTime != null 
                    ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                    : 'Não definido',
                onTap: _selectTime,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
              const Divider(height: 32),
              _buildTaskOption(
                icon: Icons.notifications_active,
                label: 'Lembrete',
                value: _hasReminder && _reminderDateTime != null
                    ? '${_reminderDateTime!.day}/${_reminderDateTime!.month} às ${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}'
                    : 'Sem lembrete',
                onTap: _selectReminderDateTime,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prioridade
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prioridade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _priority == priority;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = priority),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getPriorityColor(priority)
                              : (isDark ? Color(0xFF3A3A3C) : Color(0xFFF0F2F5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPriorityLabel(priority),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskOption({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF1877F2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFF1877F2), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondaryColor),
        ],
      ),
    );
  }

  Widget _buildNoteFields(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _noteCategories.map((category) {
              final isSelected = _noteCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _noteCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFFFF9800)
                        : (isDark ? Color(0xFF3A3A3C) : Color(0xFFF0F2F5)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? Color(0xFFFF9800) : secondaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Fixar anotação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _isPinned,
                activeColor: Color(0xFFFF9800),
                onChanged: (value) => setState(() => _isPinned = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentField(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          RichTextField(
            key: _richTextKey,
            controller: _contentController,
            focusNode: _contentFocus,
            hintText: _getContentHint(),
            textColor: textColor,
            hintColor: secondaryColor,
            fontFamily: _getFontFamily(_selectedFont),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF18191A) : Color(0xFFF0F2F5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildFormatButton(
                  icon: Icons.format_bold,
                  onTap: () => _richTextKey.currentState?.applyFormatting(TextFormat.bold),
                  textColor: textColor,
                ),
                _buildFormatButton(
                  icon: Icons.format_italic,
                  onTap: () => _richTextKey.currentState?.applyFormatting(TextFormat.italic),
                  textColor: textColor,
                ),
                _buildFormatButton(
                  icon: Icons.format_underlined,
                  onTap: () => _richTextKey.currentState?.applyFormatting(TextFormat.underline),
                  textColor: textColor,
                ),
                _buildFormatButton(
                  icon: Icons.format_strikethrough,
                  onTap: () => _richTextKey.currentState?.applyFormatting(TextFormat.strikethrough),
                  textColor: textColor,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.text_fields, color: textColor),
                  onPressed: _showFontPicker,
                  tooltip: 'Fonte',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsField(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Adicionar tag...',
                    hintStyle: TextStyle(color: secondaryColor),
                    filled: true,
                    fillColor: isDark ? Color(0xFF18191A) : Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1877F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _addTag,
                  icon: Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1877F2).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF1877F2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1877F2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF1877F2),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return IconButton(
      icon: Icon(icon, size: 22),
      onPressed: onTap,
      color: textColor,
      padding: const EdgeInsets.all(8),
    );
  }

  String _getContentHint() {
    switch (widget.editorType) {
      case EditorType.diary:
        return 'Escreva seus pensamentos aqui...';
      case EditorType.task:
        return 'Descrição da tarefa (opcional)...';
      case EditorType.note:
        return 'Suas anotações...';
    }
  }

  String _getMoodEmoji(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy: return '😊';
      case DiaryMood.sad: return '😔';
      case DiaryMood.motivated: return '💪';
      case DiaryMood.calm: return '😌';
      case DiaryMood.stressed: return '😰';
      case DiaryMood.excited: return '🤩';
      case DiaryMood.tired: return '😴';
      case DiaryMood.grateful: return '🙏';
    }
  }

  String _getMoodLabel(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy: return 'Feliz';
      case DiaryMood.sad: return 'Triste';
      case DiaryMood.motivated: return 'Motivado';
      case DiaryMood.calm: return 'Calmo';
      case DiaryMood.stressed: return 'Estressado';
      case DiaryMood.excited: return 'Animado';
      case DiaryMood.tired: return 'Cansado';
      case DiaryMood.grateful: return 'Grato';
    }
  }
}