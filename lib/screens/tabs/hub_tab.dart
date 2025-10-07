import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/theme_service.dart';

class AppItem {
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final String url;
  final double rating;
  final String earnings;
  final String developer;

  AppItem({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.url,
    this.rating = 4.5,
    required this.earnings,
    this.developer = 'Easify',
  });
}

class HubTab extends StatefulWidget {
  @override
  State<HubTab> createState() => _HubTabState();
}

class _HubTabState extends State<HubTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  final List<String> _categories = [
    'Todos',
    'Trading',
    'Investimento',
    'Apostas',
    'Remuneração',
    'Crypto',
  ];

  final List<AppItem> _apps = [
    AppItem(
      name: 'Binance',
      description: 'Maior exchange de criptomoedas do mundo para trading',
      category: 'Trading',
      icon: CupertinoIcons.bitcoin_circle_fill,
      color: const Color(0xFFF3BA2F),
      url: 'https://www.binance.com',
      rating: 4.7,
      earnings: 'Até 30% APY',
      developer: 'Binance',
    ),
    AppItem(
      name: 'eToro',
      description: 'Plataforma de trading social e investimentos',
      category: 'Trading',
      icon: CupertinoIcons.chart_bar_square_fill,
      color: const Color(0xFF56BE8E),
      url: 'https://www.etoro.com',
      rating: 4.5,
      earnings: 'Copy Trading',
      developer: 'eToro',
    ),
    AppItem(
      name: 'Coinbase',
      description: 'Compre, venda e ganhe crypto com segurança',
      category: 'Crypto',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: const Color(0xFF0052FF),
      url: 'https://www.coinbase.com',
      rating: 4.6,
      earnings: 'Earn Crypto',
      developer: 'Coinbase',
    ),
    AppItem(
      name: 'Swagbucks',
      description: 'Ganhe dinheiro assistindo vídeos e fazendo pesquisas',
      category: 'Remuneração',
      icon: CupertinoIcons.play_rectangle_fill,
      color: const Color(0xFFFF6600),
      url: 'https://www.swagbucks.com',
      rating: 4.4,
      earnings: '\$5-50/dia',
      developer: 'Swagbucks',
    ),
    AppItem(
      name: 'Honeygain',
      description: 'Ganhe dinheiro passivo compartilhando internet',
      category: 'Remuneração',
      icon: CupertinoIcons.money_dollar,
      color: const Color(0xFF4B4B4B),
      url: 'https://www.honeygain.com',
      rating: 4.3,
      earnings: '\$20-45/mês',
      developer: 'Honeygain',
    ),
    AppItem(
      name: 'Bet365',
      description: 'Apostas desportivas online e jogos de casino',
      category: 'Apostas',
      icon: CupertinoIcons.sportscourt_fill,
      color: const Color(0xFF00843D),
      url: 'https://www.bet365.com',
      rating: 4.5,
      earnings: 'Bônus 100%',
      developer: 'Bet365',
    ),
    AppItem(
      name: 'Kraken',
      description: 'Exchange de crypto com staking e trading avançado',
      category: 'Crypto',
      icon: CupertinoIcons.arrow_2_squarepath,
      color: const Color(0xFF5741D9),
      url: 'https://www.kraken.com',
      rating: 4.7,
      earnings: 'Até 23% APY',
      developer: 'Kraken',
    ),
    AppItem(
      name: 'Revolut',
      description: 'Banco digital com trading de ações e crypto',
      category: 'Investimento',
      icon: CupertinoIcons.creditcard_fill,
      color: const Color(0xFF0075EB),
      url: 'https://www.revolut.com',
      rating: 4.6,
      earnings: 'Cashback 1%',
      developer: 'Revolut',
    ),
    AppItem(
      name: 'InboxDollars',
      description: 'Receba pagamento por ler emails e assistir vídeos',
      category: 'Remuneração',
      icon: CupertinoIcons.mail_solid,
      color: const Color(0xFFE84C3D),
      url: 'https://www.inboxdollars.com',
      rating: 4.2,
      earnings: '\$5-30/dia',
      developer: 'InboxDollars',
    ),
    AppItem(
      name: 'Mistplay',
      description: 'Ganhe dinheiro jogando jogos no celular',
      category: 'Remuneração',
      icon: CupertinoIcons.game_controller_solid,
      color: const Color(0xFF6C5CE7),
      url: 'https://www.mistplay.com',
      rating: 4.5,
      earnings: '\$10-40/mês',
      developer: 'Mistplay',
    ),
    AppItem(
      name: 'Robinhood',
      description: 'Trading de ações e crypto sem comissões',
      category: 'Trading',
      icon: CupertinoIcons.arrow_up_right_diamond_fill,
      color: const Color(0xFF00C805),
      url: 'https://robinhood.com',
      rating: 4.4,
      earnings: 'Ações Grátis',
      developer: 'Robinhood',
    ),
    AppItem(
      name: 'Honeyminer',
      description: 'Mine criptomoedas automaticamente com seu PC',
      category: 'Crypto',
      icon: CupertinoIcons.antenna_radiowaves_left_right,
      color: const Color(0xFFFFB800),
      url: 'https://honeyminer.com',
      rating: 4.3,
      earnings: '\$15-60/mês',
      developer: 'Honeyminer',
    ),
    AppItem(
      name: 'Crypto.com',
      description: 'Cartão de crédito crypto com cashback até 8%',
      category: 'Crypto',
      icon: CupertinoIcons.creditcard,
      color: const Color(0xFF103D7C),
      url: 'https://crypto.com',
      rating: 4.6,
      earnings: 'Até 8% Cashback',
      developer: 'Crypto.com',
    ),
    AppItem(
      name: 'Stake',
      description: 'Casino online e apostas desportivas com crypto',
      category: 'Apostas',
      icon: CupertinoIcons.suit_diamond_fill,
      color: const Color(0xFF00E701),
      url: 'https://stake.com',
      rating: 4.7,
      earnings: 'Bônus 200%',
      developer: 'Stake',
    ),
    AppItem(
      name: 'Nielsen',
      description: 'Ganhe recompensas apenas por usar a internet',
      category: 'Remuneração',
      icon: CupertinoIcons.wifi,
      color: const Color(0xFF0033A0),
      url: 'https://computermobile.nielsen.com',
      rating: 4.4,
      earnings: '\$60/ano',
      developer: 'Nielsen',
    ),
    AppItem(
      name: 'Uphold',
      description: 'Invista em 200+ ativos incluindo crypto e metais',
      category: 'Investimento',
      icon: CupertinoIcons.layers_alt_fill,
      color: const Color(0xFF00DCBE),
      url: 'https://uphold.com',
      rating: 4.5,
      earnings: 'Até 10% APY',
      developer: 'Uphold',
    ),
  ];

  List<AppItem> get _filteredApps {
    return _apps.where((app) {
      final matchesSearch = app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todos' || app.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _openGoogleSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => WebViewScreen(
          url: searchUrl,
          title: 'Busca: $query',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: ThemeService.backgroundColor,
            elevation: 0,
            floating: true,
            pinned: true,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Hub',
                style: TextStyle(
                  color: ThemeService.textColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeService.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: ThemeService.textColor),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar no Google',
                        hintStyle: TextStyle(
                          color: ThemeService.textColor.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: ThemeService.textColor.withOpacity(0.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            CupertinoIcons.arrow_right_circle_fill,
                            color: const Color(0xFF1877F2),
                          ),
                          onPressed: () {
                            _openGoogleSearch(_searchController.text);
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: _openGoogleSearch,
                    ),
                  ),
                ),
                _buildWidgetSection(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1877F2)
                                  : ThemeService.isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : ThemeService.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = _filteredApps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAppCard(app),
                  );
                },
                childCount: _filteredApps.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetSection() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildWidget(
            'Ganhos Hoje',
            '\$24.50',
            CupertinoIcons.money_dollar_circle_fill,
            const Color(0xFF34C759),
            '+12%',
          ),
          _buildWidget(
            'Trading Ativo',
            '5 posições',
            CupertinoIcons.chart_bar_alt_fill,
            const Color(0xFF1877F2),
            'BTC, ETH...',
          ),
          _buildWidget(
            'Cashback',
            '€45.20',
            CupertinoIcons.creditcard_fill,
            const Color(0xFFFF9500),
            'Este mês',
          ),
          _buildWidget(
            'Recompensas',
            '850 pontos',
            CupertinoIcons.star_fill,
            const Color(0xFFAF52DE),
            'Disponível',
          ),
        ],
      ),
    );
  }

  Widget _buildWidget(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: ThemeService.textColor.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(AppItem app) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => AppDetailScreen(app: app),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: app.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(app.icon, color: app.color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app.earnings,
                          style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Color(0xFFFFCC00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        app.rating.toString(),
                        style: TextStyle(
                          color: ThemeService.textColor.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: ThemeService.textColor.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AppDetailScreen extends StatelessWidget {
  final AppItem app;

  const AppDetailScreen({Key? key, required this.app}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: ThemeService.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: ThemeService.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: app.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(app.icon, color: app.color, size: 50),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.name,
                              style: TextStyle(
                                color: ThemeService.textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app.developer,
                              style: TextStyle(
                                color: ThemeService.textColor.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  color: Color(0xFFFFCC00),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${app.rating} ',
                                  style: TextStyle(
                                    color: ThemeService.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '• ${app.category}',
                                  style: TextStyle(
                                    color: ThemeService.textColor.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF34C759).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.money_dollar_circle_fill,
                          color: Color(0xFF34C759),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Potencial de Ganhos',
                              style: TextStyle(
                                color: ThemeService.textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.earnings,
                              style: const TextStyle(
                                color: Color(0xFF34C759),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sobre',
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.description,
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => WebViewScreen(
                              url: app.url,
                              title: app.name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Abrir App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: ThemeService.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.arrow_clockwise, color: ThemeService.textColor),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
