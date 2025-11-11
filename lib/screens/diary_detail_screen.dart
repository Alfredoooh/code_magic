// lib/screens/diary_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/diary_service.dart';
import '../models/diary_entry_model.dart';
import '../widgets/custom_icons.dart';
import 'diary_editor_screen.dart';

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
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao favoritar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao favoritar entrada')),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Excluir entrada?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Esta ação não pode ser desfeita. Todos os dados desta entrada serão permanentemente excluídos.',
          style: TextStyle(color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
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
            const SnackBar(content: Text('Entrada excluída com sucesso')),
          );
        }
      } catch (e) {
        debugPrint('❌ Erro ao excluir: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir entrada')),
          );
        }
      }
    }
  }

  Future<void> _editEntry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorScreen(
          userId: _entry.userId,
          entry: _entry,
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
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
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
                ListTile(
                  leading: SvgIcon(
                    svgString: CustomIcons.edit,
                    color: const Color(0xFF007AFF),
                    size: 24,
                  ),
                  title: Text(
                    'Editar entrada',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editEntry();
                  },
                ),
                ListTile(
                  leading: Icon(
                    _entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 24,
                  ),
                  title: Text(
                    _entry.isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFavorite();
                  },
                ),
                ListTile(
                  leading: SvgIcon(
                    svgString: CustomIcons.delete,
                    color: Colors.red,
                    size: 24,
                  ),
                  title: const Text(
                    'Excluir entrada',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEntry();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Renderiza texto formatado (estilo WhatsApp)
  List<TextSpan> _parseFormattedText(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'(\*[^*]+\*|_[^_]+_|~[^~]+~|`[^`]+`)');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Adiciona texto normal antes da formatação
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: textColor),
        ));
      }

      final matchedText = match.group(0)!;
      final innerText = matchedText.substring(1, matchedText.length - 1);

      // Aplica formatação baseada no marcador
      if (matchedText.startsWith('*')) {
        // Bold
        spans.add(TextSpan(
          text: innerText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ));
      } else if (matchedText.startsWith('_')) {
        // Italic
        spans.add(TextSpan(
          text: innerText,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: textColor,
          ),
        ));
      } else if (matchedText.startsWith('~')) {
        // Strikethrough
        spans.add(TextSpan(
          text: innerText,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: textColor,
          ),
        ));
      } else if (matchedText.startsWith('`')) {
        // Code/Monospace
        spans.add(TextSpan(
          text: innerText,
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: textColor.withOpacity(0.1),
            color: const Color(0xFF007AFF),
          ),
        ));
      }

      lastIndex = match.end;
    }

    // Adiciona texto restante
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
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // AppBar com efeito blur
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: SvgIcon(
                svgString: CustomIcons.arrowBack,
                color: textColor,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _entry.isFavorite ? Colors.red : textColor,
                  size: 24,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: SvgIcon(
                  svgString: CustomIcons.moreVert,
                  color: textColor,
                  size: 24,
                ),
                onPressed: _showOptions,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card do Humor
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _getMoodEmoji(_entry.mood),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getMoodLabel(_entry.mood),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFullDate(_entry.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Text(
                      _entry.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Conteúdo com formatação
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 17,
                          color: textColor,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                        children: _parseFormattedText(_entry.content, textColor),
                      ),
                    ),
                  ),

                  // Tags
                  if (_entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                                color: secondaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _entry.tags.map((tag) {
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
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF007AFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Metadados
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
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
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: secondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Criado em ${_formatFullDate(_entry.createdAt)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_entry.updatedAt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: secondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Editado em ${_formatFullDate(_entry.updatedAt!)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}