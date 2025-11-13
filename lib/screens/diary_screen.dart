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
import '../widgets/diary_entry_card.dart';

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

  String? _extractUrlFromError(Object? error) {
    if (error == null) return null;
    try {
      final s = error.toString();
      final urlRegex = RegExp(r'https?://\S+');
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
            SvgIcon(
              svgString: CustomIcons.warning,
              size: 64,
              color: Colors.orange,
            ),
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
                        const SnackBar(content: Text('Link copiado')),
                      );
                    }
                  } catch (_) {}
                },
                icon: SvgIcon(
                  svgString: CustomIcons.copy,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('Copiar link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: SvgIcon(
                svgString: CustomIcons.refresh,
                size: 20,
                color: Colors.white,
              ),
              label: const Text('Tentar novamente'),
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
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (auth.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              svgString: CustomIcons.shield,
              size: 64,
              color: secondaryColor,
            ),
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
          // Tabs estilo Messages
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(28),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              indicator: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textColor,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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
                              ? const Color(0xFF1877F2).withOpacity(0.15)
                              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgIcon(
                          svgString: CustomIcons.filter,
                          size: 20,
                          color: _hasActiveFilters
                              ? const Color(0xFF1877F2)
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
                                ? const Color(0xFF1877F2)
                                : textColor,
                          ),
                        ),
                      ),
                      if (_hasActiveFilters)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1877F2),
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
                      SvgIcon(
                        svgString: CustomIcons.chevronDown,
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
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
                SvgIcon(
                  svgString: CustomIcons.book,
                  size: 64,
                  color: secondaryColor,
                ),
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
                    icon: SvgIcon(
                      svgString: CustomIcons.plus,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text('Criar primeira entrada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
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
            return DiaryEntryCard(
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
          SvgIcon(
            svgString: CustomIcons.checkCircle,
            size: 64,
            color: secondaryColor,
          ),
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