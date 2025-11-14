// lib/screens/diary_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/diary_service.dart';
import '../models/diary_entry_model.dart';
import '../widgets/custom_icons.dart';
import 'unified_editor_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  final DiaryService _diaryService = DiaryService();
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
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

  Color _getMoodColor(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy: return const Color(0xFFFFC107);
      case DiaryMood.sad: return const Color(0xFF2196F3);
      case DiaryMood.motivated: return const Color(0xFFFF5722);
      case DiaryMood.calm: return const Color(0xFF4CAF50);
      case DiaryMood.stressed: return const Color(0xFFF44336);
      case DiaryMood.excited: return const Color(0xFFE91E63);
      case DiaryMood.tired: return const Color(0xFF9C27B0);
      case DiaryMood.grateful: return const Color(0xFF00BCD4);
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

  Future<void> _toggleFavorite() async {
    try {
      await _diaryService.toggleFavorite(_entry.id, _entry.isFavorite);
      setState(() {
        _entry = _entry.copyWith(isFavorite: !_entry.isFavorite);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_entry.isFavorite 
                ? 'Adicionado aos favoritos' 
                : 'Removido dos favoritos'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao favoritar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao favoritar entrada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
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
          'Excluir entrada?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
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
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _diaryService.deleteEntry(_entry.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrada excluída com sucesso'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Erro ao excluir: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao excluir entrada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedEditorScreen(
          userId: _entry.userId,
          editorType: EditorType.diary,
          diaryEntry: _entry,
        ),
      ),
    );

    final updatedEntry = await _diaryService.getEntry(_entry.id);
    if (updatedEntry != null && mounted) {
      setState(() {
        _entry = updatedEntry;
      });
    }
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
                    'Editar entrada',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editEntry();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    _entry.isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFavorite();
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
                    'Excluir entrada',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEntry();
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

  // Renderiza texto formatado
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
                  _entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _entry.isFavorite ? Colors.red : textColor,
                  size: 26,
                ),
                onPressed: _toggleFavorite,
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
                // Emoji e Humor
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getMoodColor(_entry.mood).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getMoodEmoji(_entry.mood),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMoodLabel(_entry.mood),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _getMoodColor(_entry.mood),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatFullDate(_entry.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
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
                  _entry.title,
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
                    children: _parseFormattedText(_entry.content, textColor),
                  ),
                ),

                // Tags
                if (_entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _entry.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF1877F2),
                            width: 1.5,
                          ),
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
                            'Criado em ${_formatFullDate(_entry.createdAt)}',
                            style: TextStyle(fontSize: 13, color: secondaryColor),
                          ),
                        ],
                      ),
                      if (_entry.updatedAt != null && 
                          _entry.updatedAt!.difference(_entry.createdAt).inSeconds > 60) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Atualizado em ${_formatFullDate(_entry.updatedAt!)}',
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