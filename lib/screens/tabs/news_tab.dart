// news_tab.dart
class NewsTab extends StatelessWidget {
  final List<Map<String, String>> _news = [
    {
      'title': 'Tecnologia avança rapidamente',
      'description': 'Novas inovações estão transformando o mundo',
      'time': '2h atrás',
    },
    {
      'title': 'Mercado financeiro em alta',
      'description': 'Investimentos mostram crescimento positivo',
      'time': '5h atrás',
    },
    {
      'title': 'Ciência descobre nova espécie',
      'description': 'Pesquisadores encontram animal raro na floresta',
      'time': '1d atrás',
    },
    {
      'title': 'Esportes: Campeonato começa',
      'description': 'Times se preparam para a grande final',
      'time': '2d atrás',
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
          'Atualidade',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _news.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final news = _news[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeService.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeService.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.news_solid,
                        color: Color(0xFF1877F2),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            news['title']!,
                            style: TextStyle(
                              color: ThemeService.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news['time']!,
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
                  news['description']!,
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
