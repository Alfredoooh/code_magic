// lib/screens/diary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final List<DiaryEntry> _entries = [
    DiaryEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      title: 'Meu primeiro dia',
      content: 'Hoje foi um dia incrível! Aprendi muitas coisas novas sobre desenvolvimento.',
      mood: DiaryMood.happy,
    ),
    DiaryEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      title: 'Desafios e aprendizados',
      content: 'Enfrentei alguns desafios técnicos, mas consegui superá-los com pesquisa e dedicação.',
      mood: DiaryMood.motivated,
    ),
  ];

  void _addNewEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewDiaryEntryModal(
        onSave: (entry) {
          setState(() {
            _entries.insert(0, entry);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Container(
      color: bgColor,
      child: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    svgString: CustomIcons.book,
                    size: 64,
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu diário está vazio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comece a registrar seus pensamentos',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                return _DiaryEntryCard(entry: _entries[index]);
              },
            ),
    );
  }
}

enum DiaryMood { happy, sad, motivated, calm, stressed }

class DiaryEntry {
  final DateTime date;
  final String title;
  final String content;
  final DiaryMood mood;

  DiaryEntry({
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
  });
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;

  const _DiaryEntryCard({required this.entry});

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

    return Container(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NewDiaryEntryModal extends StatefulWidget {
  final Function(DiaryEntry) onSave;

  const _NewDiaryEntryModal({required this.onSave});

  @override
  State<_NewDiaryEntryModal> createState() => _NewDiaryEntryModalState();
}

class _NewDiaryEntryModalState extends State<_NewDiaryEntryModal> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DiaryMood _selectedMood = DiaryMood.happy;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      return;
    }

    widget.onSave(DiaryEntry(
      date: DateTime.now(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
    ));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Nova Entrada',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Título',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                style: TextStyle(color: textColor),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Como você está se sentindo hoje?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}