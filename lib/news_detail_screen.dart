// news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'markets_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(news.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir ${news.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0066FF).withOpacity(0.2),
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0066FF).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      news.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  Text(
                    news.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info da fonte
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            news.favicon,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.article,
                              color: Colors.white.withOpacity(0.5),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.source,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              news.time,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Divisor
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 24),
                  
                  // Conteúdo completo
                  Text(
                    news.summary,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Conteúdo adicional simulado
                  _buildContentSection(
                    'Contexto do Mercado',
                    'Os mercados financeiros globais continuam a demonstrar alta volatilidade em meio a incertezas econômicas. Analistas apontam que fatores macroeconômicos, incluindo políticas monetárias dos bancos centrais e indicadores de inflação, têm exercido pressão significativa sobre os ativos de risco.',
                  ),
                  
                  _buildContentSection(
                    'Análise Técnica',
                    'Do ponto de vista técnico, os principais índices apresentam padrões de consolidação, com resistências importantes sendo testadas. Traders experientes recomendam cautela e o uso adequado de stop-loss em posições atuais.',
                  ),
                  
                  _buildContentSection(
                    'Perspectivas Futuras',
                    'Para os próximos dias, espera-se que a volatilidade permaneça elevada, especialmente durante divulgações de dados econômicos importantes. Investidores devem manter-se atualizados sobre eventos macroeconômicos que podem impactar significativamente as cotações.',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botão Ler Mais
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchURL,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Ler Artigo Completo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.open_in_new, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notícias relacionadas
                  const SizedBox(height: 24),
                  const Text(
                    'Notícias Relacionadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildRelatedNewsCard(
                    'Volatilidade Atinge Níveis Recordes',
                    'Mercados globais registram maior movimento em meses',
                    'Bloomberg',
                    '1h atrás',
                  ),
                  const SizedBox(height: 12),
                  _buildRelatedNewsCard(
                    'Estratégias para Mercados Turbulentos',
                    'Especialistas compartilham dicas de gerenciamento de risco',
                    'MarketWatch',
                    '3h atrás',
                  ),
                  const SizedBox(height: 12),
                  _buildRelatedNewsCard(
                    'Índices Sintéticos Ganham Popularidade',
                    'Traders preferem mercados disponíveis 24/7',
                    'Finance Weekly',
                    '5h atrás',
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedNewsCard(String title, String summary, String source, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                source,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}