// lib/widgets/diary_filter_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/diary_entry_model.dart';

void showDiaryFilterModal({
  required BuildContext context,
  required DiaryMood? selectedMood,
  required bool showFavoritesOnly,
  required Function(DiaryMood?) onMoodSelected,
  required Function(bool) onFavoritesToggle,
  required VoidCallback onClear,
}) {
  final isDark = context.read<ThemeProvider>().isDarkMode;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            onClear();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Limpar',
                            style: TextStyle(
                              color: const Color(0xFFE91E63),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle de favoritos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        setModalState(() {
                          onFavoritesToggle(!showFavoritesOnly);
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: showFavoritesOnly 
                                ? const Color(0xFFE91E63) 
                                : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: showFavoritesOnly 
                              ? const Color(0xFFE91E63).withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                              color: showFavoritesOnly 
                                  ? const Color(0xFFE91E63) 
                                  : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Apenas Favoritos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: showFavoritesOnly
                                    ? const Color(0xFFE91E63)
                                    : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Por Humor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DiaryMood.values.map((mood) {
                        final isSelected = selectedMood == mood;
                        final moodColor = _getMoodColor(mood);
                        
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              onMoodSelected(isSelected ? null : mood);
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? moodColor : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: isSelected ? moodColor.withOpacity(0.15) : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getMoodEmoji(mood),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getMoodName(mood),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected 
                                        ? moodColor 
                                        : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
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

Color _getMoodColor(DiaryMood mood) {
  switch (mood) {
    case DiaryMood.happy:
      return const Color(0xFFFFC107); // Amarelo
    case DiaryMood.sad:
      return const Color(0xFF2196F3); // Azul
    case DiaryMood.motivated:
      return const Color(0xFFFF5722); // Laranja forte
    case DiaryMood.calm:
      return const Color(0xFF00BCD4); // Ciano
    case DiaryMood.stressed:
      return const Color(0xFFFF9800); // Laranja
    case DiaryMood.excited:
      return const Color(0xFFE91E63); // Rosa
    case DiaryMood.tired:
      return const Color(0xFF9C27B0); // Roxo
    case DiaryMood.grateful:
      return const Color(0xFF4CAF50); // Verde
  }
}