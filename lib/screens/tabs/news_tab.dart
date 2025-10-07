import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/theme_service.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({Key? key}) : super(key: key);

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  String _selectedCategory = 'Todos';
  final List<String> _categories = [
    'Todos',
    'Tecnologia',
    'Negócios',
    'Esportes',
    'Entretenimento',
    'Ciência',
  ];

  // Dados de exemplo - em produção viriam de uma API
  final List<Map<String, dynamic>> _newsItems = [
    {
      'title': 'Nova atualização do Flutter traz melhorias de performance',
      'category': 'Tecnologia',
      'date': 'Há 2 horas',
      'image': 'https://via.placeholder.com/400x200',
    },
    {
      'title': 'Mercado de ações fecha em alta nesta terça-feira',
      'category': 'Negócios',
      'date': 'Há 3 horas',
      'image': 'https://via.placeholder.com/400x200',
    },
    {
      'title': 'Time nacional conquista importante vitória',
      'category': 'Esportes',
      'date': 'Há 5 horas',
      'image': 'https://via.placeholder.com/400x200',
    },
    {
      'title': 'Novo filme bate recordes de bilheteria',
      'category': 'Entretenimento',
      'date': 'Há 1 dia',
      'image': 'https://via.placeholder.com/400x200',
    },
    {
      'title': 'Descoberta científica revoluciona medicina',
      'category': 'Ciência',
      'date': 'Há 2 dias',
      'image': 'https://via.placeholder.com/400x200',
    },
  ];

  List<Map<String, dynamic>> get _filteredNews {
    if (_selectedCategory == 'Todos') return _newsItems;
    return _newsItems
        .where((news) => news['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Atualidades'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(textColor),
          Expanded(
            child: _buildNewsList(textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(Color textColor) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1877F2)
                    : textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1877F2)
                      : textColor.withOpacity(0.15),
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsList(Color textColor) {
    final filteredNews = _filteredNews;

    if (filteredNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.news,
              size: 80,
              color: textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma notícia encontrada',
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNews.length,
      itemBuilder: (context, index) {
        final news = filteredNews[index];
        return _buildNewsCard(news, textColor);
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              height: 180,
              width: double.infinity,
              color: textColor.withOpacity(0.1),
              child: const Icon(
                CupertinoIcons.photo,
                size: 60,
                color: Color(0xFF1877F2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news['category'],
                        style: const TextStyle(
                          color: Color(0xFF1877F2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.time,
                      size: 14,
                      color: textColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      news['date'],
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  news['title'],
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        backgroundColor: const Color(0xFF1877F2).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ler mais',
                        style: TextStyle(
                          color: Color(0xFF1877F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
