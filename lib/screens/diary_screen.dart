// lib/screens/diary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DiaryScreenState extends State<DiaryScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  DiaryMood? _selectedMood;
  bool _showFavoritesOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        setState(() => _selectedMood = mood);
      },
      onFavoritesToggle: (value) {
        setState(() => _showFavoritesOnly = value);
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

  String _getMoodName(DiaryMood mood) {
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

  String _getFilterText() {
    if (_showFavoritesOnly) return 'Favoritos';
    if (_selectedMood != null) return '${_getMoodEmoji(_selectedMood!)} ${_getMoodName(_selectedMood!)}';
    return 'Todas as entradas';
  }

  bool get _hasActiveFilters => _selectedMood != null || _showFavoritesOnly;

  // -------------------------
  // Extração de URL a partir da mensagem de erro
  // -------------------------
  String? _extractUrlFromError(Object? error) {
    if (error == null) return null;
    try {
      final s = error.toString();
      final urlRegex = RegExp(r'https?://[^\s\)\'"]+');
      final match = urlRegex.firstMatch(s);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }

  Widget _buildErrorWidgetWithLink(Object error, Color secondaryColor) {
    final url = _extractUrlFromError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Índice necessário',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O Firestore precisa criar índices para esta consulta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
            const SizedBox(height: 12),
            if (url != null) ...[
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(0xFF007AFF),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado para a área de transferência')),
                      );
                    }
                  } catch (_) {}
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar link do índice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cole esse link no navegador e crie o índice no Console do Firebase (Firestore → Indexes).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Verifique o console do Firebase para o link de criação do índice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Limpar filtros / Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    if (auth.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Faça login para acessar seu diário',
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ],
        ),
      );
    }

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Tabs Diário/Tarefas
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: textColor,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Diário'),
                Tab(text: 'Tarefas'),
              ],
            ),
          ),

          // Botão de filtro
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
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
                              ? const Color(0xFF007AFF).withOpacity(0.15)
                              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _hasActiveFilters
                              ? const Color(0xFF007AFF)
                              : secondaryColor,
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
                                ? const Color(0xFF007AFF)
                                : textColor,
                          ),
                        ),
                      ),
                      if (_hasActiveFilters)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiaryTab(auth, isDark, textColor, secondaryColor, cardColor),
                _buildTasksTab(isDark, textColor, secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryTab(AuthProvider auth, bool isDark, Color textColor, Color secondaryColor, Color cardColor) {
    return StreamBuilder<List<DiaryEntry>>(
      stream: _showFavoritesOnly
          ? _diaryService.getFavoriteEntries(auth.user!.uid)
          : (_selectedMood != null
              ? _diaryService.getEntriesByMood(auth.user!.uid, _selectedMood!)
              : _diaryService.getUserEntries(auth.user!.uid)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ Erro no DiaryScreen: ${snapshot.error}');
          return _buildErrorWidgetWithLink(snapshot.error!, secondaryColor);
        }

        var entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: secondaryColor),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters ? 'Nenhuma entrada encontrada' : 'Seu diário está vazio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters ? 'Tente usar outros filtros' : 'Comece a escrever suas memórias',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
                if (!_hasActiveFilters) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar primeira entrada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  Widget _buildTasksTab(bool isDark, Color textColor, Color secondaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: secondaryColor),
          const SizedBox(height: 16),
          Text(
            'Tarefas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em breve você poderá gerenciar suas tarefas aqui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: secondaryColor),
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
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                          style: TextStyle(fontSize: 13, color: secondaryColor),
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
                  color: secondaryColor,
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
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
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