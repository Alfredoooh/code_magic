// lib/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/note_service.dart';
import '../models/note_model.dart';
import 'unified_editor_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();
  late Note _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Aula':
        return const Color(0xFF2196F3);
      case 'Trabalho':
        return const Color(0xFF9C27B0);
      case 'Pessoal':
        return const Color(0xFF4CAF50);
      case 'Ideias':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Aula':
        return '📚';
      case 'Trabalho':
        return '💼';
      case 'Pessoal':
        return '👤';
      case 'Ideias':
        return '💡';
      default:
        return '📝';
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

  Future<void> _togglePin() async {
    try {
      await _noteService.toggleNotePin(_note.id, _note.isPinned);
      setState(() {
        _note = _note.copyWith(isPinned: !_note.isPinned);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_note.isPinned ? 'Anotação fixada' : 'Anotação desafixada'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao fixar anotação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
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
          'Excluir anotação?',
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
        await _noteService.deleteNote(_note.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anotação excluída com sucesso'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir anotação'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedEditorScreen(
          userId: _note.userId,
          editorType: EditorType.note,
          note: _note,
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
                    'Editar anotação',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editNote();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: const Color(0xFFFF9800),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _note.isPinned ? 'Desafixar anotação' : 'Fixar anotação',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _togglePin();
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
                    'Excluir anotação',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteNote();
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

  List<TextSpan> _parseFormattedText(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|_[^_]+_|__[^_]+__|~~[^~]+~~|`[^`]+`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: textColor),
        ));
      }

      final matchedText = match.group(0)!;
      String innerText;
      TextStyle style = TextStyle(color: textColor);

      if (matchedText.startsWith('**')) {
        innerText = matchedText.substring(2, matchedText.length - 2);
        style = TextStyle(fontWeight: FontWeight.bold, color: textColor);
      } else if (matchedText.startsWith('*')) {
        innerText = matchedText.substring(1, matchedText.length - 1);
        style = TextStyle(fontWeight: FontWeight.bold, color: textColor);
      } else if (matchedText.startsWith('__')) {
        innerText = matchedText.substring(2, matchedText.length - 2);
        style = TextStyle(decoration: TextDecoration.underline, color: textColor);
      } else if (matchedText.startsWith('_')) {
        innerText = matchedText.substring(1, matchedText.length - 1);
        style = TextStyle(fontStyle: FontStyle.italic, color: textColor);
      } else if (matchedText.startsWith('~~')) {
        innerText = matchedText.substring(2, matchedText.length - 2);
        style = TextStyle(decoration: TextDecoration.lineThrough, color: textColor);
      } else if (matchedText.startsWith('`')) {
        innerText = matchedText.substring(1, matchedText.length - 1);
        style = TextStyle(
          fontFamily: 'monospace',
          backgroundColor: textColor.withOpacity(0.1),
          color: const Color(0xFF1877F2),
        );
      } else {
        innerText = matchedText;
      }

      spans.add(TextSpan(text: innerText, style: style));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: textColor),
      ));
    }

    return spans.isEmpty 
        ? [TextSpan(text: text, style: TextStyle(color: textColor))] 
        : spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final categoryColor = _getCategoryColor(_note.category);

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
                icon: Icon(
                  _note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _note.isPinned ? const Color(0xFFFF9800) : textColor,
                  size: 26,
                ),
                onPressed: _togglePin,
              ),
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
                // Categoria
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryIcon(_note.category),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _note.category,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_note.isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.push_pin, size: 14, color: Color(0xFFFF9800)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Fixada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ],
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
                  _note.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Conteúdo
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      height: 1.7,
                      letterSpacing: 0.3,
                    ),
                    children: _parseFormattedText(_note.content, textColor),
                  ),
                ),

                // Tags
                if (_note.tags.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _note.tags.map((tag) {
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
                            'Criado em ${_formatFullDate(_note.createdAt)}',
                            style: TextStyle(fontSize: 13, color: secondaryColor),
                          ),
                        ],
                      ),
                      if (_note.updatedAt.difference(_note.createdAt).inSeconds > 60) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Atualizado em ${_formatFullDate(_note.updatedAt)}',
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
}