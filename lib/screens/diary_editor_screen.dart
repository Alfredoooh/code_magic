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

class _DiaryEditorScreenState extends State<DiaryEditorScreen> {
  final DiaryService _diaryService = DiaryService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();

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
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

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
                    color: secondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgIcon(
                          svgString: CustomIcons.text,
                          size: 24,
                          color: const Color(0xFF1877F2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Escolher fonte',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._availableFonts.map((font) {
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedFont == font
                            ? const Color(0xFF1877F2).withOpacity(0.1)
                            : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: _getFontFamily(font),
                            color: _selectedFont == font
                                ? const Color(0xFF1877F2)
                                : textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: SvgIcon(
                              svgString: CustomIcons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedFont = font);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
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
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    debugPrint('🔍 Tentando salvar entrada...');
    debugPrint('   - Título: $title');
    debugPrint('   - Conteúdo: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
    debugPrint('   - Humor: $_selectedMood');
    debugPrint('   - Tags: $_tags');

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Título e conteúdo são obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.entry == null) {
        // CRIAR NOVA ENTRADA
        debugPrint('✨ Criando nova entrada...');
        final entry = DiaryEntry(
          id: '', // Firestore vai gerar
          userId: widget.userId,
          date: DateTime.now(),
          title: title,
          content: content,
          mood: _selectedMood,
          tags: _tags,
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _diaryService.createEntry(entry);
        debugPrint('✅ Entrada criada com sucesso!');
      } else {
        // ATUALIZAR ENTRADA EXISTENTE
        debugPrint('📝 Atualizando entrada existente...');
        final updatedEntry = DiaryEntry(
          id: widget.entry!.id,
          userId: widget.entry!.userId,
          date: widget.entry!.date,
          title: title,
          content: content,
          mood: _selectedMood,
          tags: _tags,
          isFavorite: widget.entry!.isFavorite,
          createdAt: widget.entry!.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _diaryService.updateEntry(updatedEntry);
        debugPrint('✅ Entrada atualizada com sucesso!');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry == null 
                ? 'Entrada criada com sucesso!' 
                : 'Entrada atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERRO ao salvar entrada: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
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
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

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
          widget.entry == null ? 'Nova Entrada' : 'Editar Entrada',
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
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1877F2),
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
            // Título
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Título da entrada',
                  hintStyle: TextStyle(color: secondaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(height: 16),

            // Seletor de humor
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                  width: 1,
                ),
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
                                ? const Color(0xFF1877F2).withOpacity(0.15)
                                : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1877F2)
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
                                      ? const Color(0xFF1877F2)
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

            // Conteúdo
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                  width: 1,
                ),
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
                      hintText: 'Escreva seus pensamentos aqui...',
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
                      color: isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5),
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
                border: Border.all(
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                  width: 1,
                ),
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
                            fillColor: isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5),
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
                          color: const Color(0xFF1877F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _addTag,
                          icon: SvgIcon(
                            svgString: CustomIcons.plus,
                            size: 20,
                            color: Colors.white,
                          ),
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
                            color: const Color(0xFF1877F2).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1877F2),
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
                                  color: Color(0xFF1877F2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeTag(tag),
                                child: SvgIcon(
                                  svgString: CustomIcons.close,
                                  size: 14,
                                  color: const Color(0xFF1877F2),
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