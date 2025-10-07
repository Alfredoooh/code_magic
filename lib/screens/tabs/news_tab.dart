import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

// news_tab.dart
class NewsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _news = [
    {
      'title': 'IA revoluciona desenvolvimento de apps',
      'description': 'Novas ferramentas de inteligência artificial aceleram criação de aplicativos móveis',
      'time': '1h atrás',
      'category': 'Tecnologia',
      'icon': CupertinoIcons.device_phone_portrait,
      'color': Color(0xFF1877F2),
    },
    {
      'title': 'Carros elétricos batem recorde',
      'description': 'Baterias de 800V e carregamento rápido mudam cenário da mobilidade elétrica',
      'time': '3h atrás',
      'category': 'Inovação',
      'icon': CupertinoIcons.bolt_fill,
      'color': Color(0xFF34C759),
    },
    {
      'title': 'Outubro Rosa mobiliza país',
      'description': 'Campanha de conscientização sobre saúde feminina ganha destaque',
      'time': '5h atrás',
      'category': 'Saúde',
      'icon': CupertinoIcons.heart_fill,
      'color': Color(0xFFFF2D55),
    },
    {
      'title': 'Streaming lança novidades',
      'description': 'HBO Max anuncia séries e filmes exclusivos para outubro',
      'time': '8h atrás',
      'category': 'Entretenimento',
      'icon': CupertinoIcons.play_rectangle_fill,
      'color': Color(0xFFAF52DE),
    },
    {
      'title': 'Mercado tech em crescimento',
      'description': 'Setor de tecnologia português registra expansão e novas oportunidades',
      'time': '12h atrás',
      'category': 'Negócios',
      'icon': CupertinoIcons.chart_bar_fill,
      'color': Color(0xFFFF9500),
    },
    {
      'title': 'Cibersegurança em foco',
      'description': 'Empresas investem em proteção de dados e privacidade digital',
      'time': '1d atrás',
      'category': 'Segurança',
      'icon': CupertinoIcons.lock_shield_fill,
      'color': Color(0xFF5856D6),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Atualidades',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.refresh,
              color: ThemeService.textColor,
            ),
            onPressed: () {
              // Ação de refresh
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de categoria
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Todas', true),
                _buildCategoryChip('Tecnologia', false),
                _buildCategoryChip('Saúde', false),
                _buildCategoryChip('Negócios', false),
                _buildCategoryChip('Entretenimento', false),
              ],
            ),
          ),
          
          // Lista de notícias
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _news.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final news = _news[index];
                return _buildNewsCard(news);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ThemeService.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (bool value) {},
        backgroundColor: ThemeService.cardColor,
        selectedColor: const Color(0xFF1877F2),
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF1877F2)
              : ThemeService.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Abrir detalhes da notícia
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: news['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        news['icon'],
                        color: news['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: news['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: news['color'].withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              news['category'],
                              style: TextStyle(
                                color: news['color'],
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            news['time'],
                            style: TextStyle(
                              color: ThemeService.textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  news['title'],
                  style: TextStyle(
                    color: ThemeService.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news['description'],
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_right_circle,
                      color: news['color'],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ler mais',
                      style: TextStyle(
                        color: news['color'],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
