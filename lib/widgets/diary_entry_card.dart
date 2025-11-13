// lib/screens/diary_entry_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/diary_entry_model.dart';
import 'custom_icons.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

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
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com emoji e título
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getMoodEmoji(entry.mood),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            SvgIcon(
                              svgString: CustomIcons.calendar,
                              size: 14,
                              color: secondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(entry.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (entry.isFavorite)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgIcon(
                        svgString: CustomIcons.heart,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),

              // Divisor
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
              ),
              const SizedBox(height: 12),

              // Conteúdo
              Text(
                entry.content,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryColor,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1877F2).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgIcon(
                            svgString: CustomIcons.tag,
                            size: 12,
                            color: const Color(0xFF1877F2),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1877F2),
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}