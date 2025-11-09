// lib/screens/diary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/diary_service.dart';
import '../models/diary_entry_model.dart';
import '../widgets/custom_icons.dart';
import '../widgets/diary_filter_modal.dart';
import 'diary_editor_screen.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final DiaryService _diaryService = DiaryService();
  DiaryMood? _selectedMood;
  bool _showFavoritesOnly = false;

  void _createNewEntry() {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorScreen(userId: auth.user!.uid),
      ),
    );
  }

  void _showFilters() {
    showDiaryFilterModal(
      context: context,
      selectedMood: _selectedMood,
      showFavoritesOnly: _showFavoritesOnly,
      onMoodSelected: (mood) {
        setState(() {
          _selectedMood = mood;
        });
      },
      onFavoritesToggle: (value) {
        setState(() {
          _showFavoritesOnly = value;
        });
      },
      onClear: () {
        setState(() {
          _selectedMood = null;
          _showFavoritesOnly = false;
        });
      },
    );
  }

  String _getMoodEmoji(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy:
        return '😊';
      case DiaryMood.sad:
        return '😔';
      case DiaryMood.motivated:
        return '💪';
      case DiaryMood.calm:
        return '😌';
      case DiaryMood.stressed:
        return '😰';
      case DiaryMood.excited:
        return '🤩';
      case DiaryMood.tired:
        return '😴';
      case DiaryMood.grateful:
        return '🙏';
    }
  }

  String _getMoodName(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy:
        return 'Feliz';
      case DiaryMood.sad:
        return 'Triste';
      case DiaryMood.motivated:
        return 'Motivado';
      case DiaryMood.calm:
        return 'Calmo';
      case DiaryMood.stressed:
        return 'Estressado';
      case DiaryMood.excited:
        return 'Animado';
      case DiaryMood.tired:
        return 'Cansado';
      case DiaryMood.grateful:
        return 'Grato';
    }
  }

  String _getFilterText() {
    if (_showFavoritesOnly) {
      return 'Favoritos';
    } else if (_selectedMood != null) {
      return '${_getMoodEmoji(_selectedMood!)} ${_getMoodName(_selectedMood!)}';
    } else {
      return 'Todas as entradas';
    }
  }

  bool get _hasActiveFilters => _selectedMood != null || _showFavoritesOnly;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    if (auth.user == null) {
      return Center(
        child: Text(
          'Faça login para acessar seu diário',
          style: TextStyle(
            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Botão de filtro moderno
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              color: isDark ? const Color(0xFF242526) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: isDark ? 0 : 1,
              shadowColor: Colors.black.withOpacity(0.05),
              child: InkWell(
                onTap: _showFilters,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? (isDark ? const Color(0xFF0A84FF).withOpacity(0.15) : const Color(0xFF007AFF).withOpacity(0.1))
                              : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.string(
                          CustomIcons.filterList,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _hasActiveFilters
                                ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                                : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFilterText(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _hasActiveFilters
                                ? (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                                : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                          ),
                        ),
                      ),
                      if (_hasActiveFilters)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '1',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      SvgPicture.string(
                        CustomIcons.expandMore,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<DiaryEntry>>(
              stream: _showFavoritesOnly
                  ? _diaryService.getFavoriteEntries(auth.user!.uid)
                  : (_selectedMood != null
                      ? _diaryService.getEntriesByMood(auth.user!.uid, _selectedMood!)
                      : _diaryService.getUserEntries(auth.user!.uid)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar entradas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          CustomIcons.book,
                          width: 64,
                          height: 64,
                          colorFilter: ColorFilter.mode(
                            isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters 
                              ? 'Nenhuma entrada encontrada'
                              : 'Seu diário está vazio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasActiveFilters
                              ? 'Tente usar outros filtros'
                              : 'Comece a escrever suas memórias',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _DiaryEntryCard(
                      entry: entries[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryDetailScreen(entry: entries[index]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const _DiaryEntryCard({required this.entry, required this.onTap});

  String _getMoodEmoji(DiaryMood mood) {
    switch (mood) {
      case DiaryMood.happy:
        return '😊';
      case DiaryMood.sad:
        return '😔';
      case DiaryMood.motivated:
        return '💪';
      case DiaryMood.calm:
        return '😌';
      case DiaryMood.stressed:
        return '😰';
      case DiaryMood.excited:
        return '🤩';
      case DiaryMood.tired:
        return '😴';
      case DiaryMood.grateful:
        return '🙏';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getMoodEmoji(entry.mood),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(entry.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.isFavorite)
                    const Icon(Icons.favorite, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1877F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}