// lib/screens/diary_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/diary_service.dart';
import '../models/diary_entry_model.dart';
import '../widgets/custom_icons.dart';

enum EditorType { diary, task }

class DiaryEditorScreen extends StatefulWidget {
  final String userId;
  final DiaryEntry? entry;
  final EditorType editorType;

  const DiaryEditorScreen({
    super.key,
    required this.userId,
    this.entry,
    this.editorType = EditorType.diary,
  });

  @override
  State<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends State<DiaryEditorScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

  late TabController _tabController;
  DiaryMood _selectedMood = DiaryMood.happy;
  List<String> _tags = [];
  bool _isSaving = false;
  String _selectedFont = 'System';
  
  final List<String> _availableFonts = [
    'System',
    'Serif',
    'Monospace',
    'Cursive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.editorType == EditorType.diary ? 0 : 1;
    
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _tags = List.from(widget.entry!.tags);
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

  // Formatação de texto estilo WhatsApp
  void _applyFormatting(String marker) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (!selection.isValid || selection.start == selection.end) return;
    
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$marker$selectedText$marker',
    );
    
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.end + marker.length * 2,
      ),
    );
  }

  void _showFontPicker() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Escolher fonte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              ..._availableFonts.map((font) {
                return ListTile(
                  title: Text(
                    'Aa',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: _getFontFamily(font),
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    font,
                    style: TextStyle(color: textColor.withOpacity(0.6)),
                  ),
                  trailing: _selectedFont == font
                      ? const Icon(Icons.check, color: Color(0xFF007AFF))
                      : null,
                  onTap: () {
                    setState(() => _selectedFont = font);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String? _getFontFamily(String font) {
    switch (font) {
      case 'Serif':
        return 'serif';
      case 'Monospace':
        return 'monospace';
      case 'Cursive':
        return 'cursive';
      default:
        return null;
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || 
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título e conteúdo são obrigatórios')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.entry == null) {
        final entry = DiaryEntry(
          id: '',
          userId: widget.userId,
          date: DateTime.now(),
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          tags: _tags,
          createdAt: DateTime.now(),
        );
        await _diaryService.createEntry(entry);
      } else {
        final updatedEntry = widget.entry!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          mood: _selectedMood,
          tags: _tags,
          updatedAt: DateTime.now(),
        );
        await _diaryService.updateEntry(updatedEntry);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry == null 
                ? 'Entrada criada com sucesso!' 
                : 'Entrada atualizada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar entrada: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar entrada')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(
            svgString: CustomIcons.close,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.entry == null 
              ? (_tabController.index == 0 ? 'Nova Entrada' : 'Nova Tarefa')
              : 'Editar',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007AFF),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: textColor,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Diário'),
                Tab(text: 'Tarefa'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: _tabController.index == 0 
                            ? 'Título da entrada' 
                            : 'Título da tarefa',
                        hintStyle: TextStyle(color: secondaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seletor de humor (apenas para diário)
                  if (_tabController.index == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '😊',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Como você está se sentindo?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: DiaryMood.values.map((mood) {
                              final isSelected = _selectedMood == mood;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMood = mood),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF007AFF).withOpacity(0.15)
                                        : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF007AFF)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getMoodEmoji(mood),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getMoodLabel(mood),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF007AFF)
                                              : textColor,
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
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Conteúdo com formatação
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _contentController,
                          focusNode: _contentFocus,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            height: 1.5,
                            fontFamily: _getFontFamily(_selectedFont),
                          ),
                          decoration: InputDecoration(
                            hintText: _tabController.index == 0
                                ? 'Escreva seus pensamentos aqui...'
                                : 'Descreva sua tarefa...',
                            hintStyle: TextStyle(color: secondaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: null,
                          minLines: 10,
                        ),
                        // Barra de formatação
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildFormatButton(
                                icon: Icons.format_bold,
                                label: 'Bold',
                                onTap: () => _applyFormatting('*'),
                                textColor: textColor,
                              ),
                              _buildFormatButton(
                                icon: Icons.format_italic,
                                label: 'Italic',
                                onTap: () => _applyFormatting('_'),
                                textColor: textColor,
                              ),
                              _buildFormatButton(
                                icon: Icons.format_strikethrough,
                                label: 'Strike',
                                onTap: () => _applyFormatting('~'),
                                textColor: textColor,
                              ),
                              _buildFormatButton(
                                icon: Icons.code,
                                label: 'Code',
                                onTap: () => _applyFormatting('`'),
                                textColor: textColor,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.font_download, color: textColor),
                                onPressed: _showFontPicker,
                                tooltip: 'Fonte',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgIcon(
                              svgString: CustomIcons.tag,
                              color: textColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tags',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                  fillColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) => _addTag(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _addTag,
                                icon: const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF007AFF),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$tag',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeTag(tag),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Color(0xFF007AFF),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        color: textColor,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}