// lib/widgets/diary_filter_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/diary_entry_model.dart';
import 'custom_icons.dart';

void showDiaryFilterModal({
  required BuildContext context,
  required DiaryMood? selectedMood,
  required bool showFavoritesOnly,
  required Function(DiaryMood?) onMoodSelected,
  required Function(bool) onFavoritesToggle,
  required VoidCallback onClear,
}) {
  final isDark = context.read<ThemeProvider>().isDarkMode;
  final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
  final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
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

                  // Header
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
                            svgString: CustomIcons.filter,
                            size: 24,
                            color: const Color(0xFF1877F2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            onClear();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgIcon(
                                svgString: CustomIcons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Limpar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle de favoritos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () {
                        setModalState(() {
                          onFavoritesToggle(!showFavoritesOnly);
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: showFavoritesOnly 
                              ? Colors.red.withOpacity(0.1)
                              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: showFavoritesOnly 
                                ? Colors.red 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: showFavoritesOnly
                                    ? Colors.red
                                    : (isDark ? const Color(0xFF242526) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SvgIcon(
                                svgString: CustomIcons.heart,
                                size: 20,
                                color: showFavoritesOnly 
                                    ? Colors.white 
                                    : secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apenas Favoritos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: showFavoritesOnly
                                          ? Colors.red
                                          : textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mostrar apenas entradas marcadas como favoritas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showFavoritesOnly)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: SvgIcon(
                                  svgString: CustomIcons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Separador
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Por Humor',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid de humores
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: DiaryMood.values.length,
                      itemBuilder: (context, index) {
                        final mood = DiaryMood.values[index];
                        final isSelected = selectedMood == mood;
                        final moodColor = _getMoodColor(mood);

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              onMoodSelected(isSelected ? null : mood);
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? moodColor.withOpacity(0.15) 
                                  : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? moodColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getMoodEmoji(mood),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _getMoodName(mood),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? moodColor : textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: moodColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: SvgIcon(
                                      svgString: CustomIcons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
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
      return const Color(0xFFFFC107);
    case DiaryMood.sad:
      return const Color(0xFF2196F3);
    case DiaryMood.motivated:
      return const Color(0xFFFF5722);
    case DiaryMood.calm:
      return const Color(0xFF00BCD4);
    case DiaryMood.stressed:
      return const Color(0xFFFF9800);
    case DiaryMood.excited:
      return const Color(0xFFE91E63);
    case DiaryMood.tired:
      return const Color(0xFF9C27B0);
    case DiaryMood.grateful:
      return const Color(0xFF4CAF50);
  }
}