import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../services/theme_service.dart';

class AppItem {
  final String name;
  final String description;
  final String category;
  final String iconUrl;
  final Color color;
  final String url;
  final double rating;
  final String monthlyUsers;
  final String developer;
  final List<String> features;

  AppItem({
    required this.name,
    required this.description,
    required this.category,
    required this.iconUrl,
    required this.color,
    required this.url,
    this.rating = 4.5,
    required this.monthlyUsers,
    this.developer = 'Easify',
    required this.features,
  });
}

class HubTab extends StatefulWidget {
  @override
  State<HubTab> createState() => _HubTabState();
}

class _HubTabState extends State<HubTab> {
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
      description: 'Maior exchange de criptomoedas do mundo para trading avançado',
      category: 'Trading',
      iconUrl: 'https://cryptologos.cc/logos/bnb-bnb-logo.svg',
      color: const Color(0xFFF3BA2F),
      url: 'https://www.binance.com',
      rating: 4.7,
      monthlyUsers: '120M',
      developer: 'Binance Holdings Ltd',
      features: [
        'Trading de mais de 350 criptomoedas',
        'Staking com até 30% APY',
        'Futures e margin trading',
        'NFT marketplace integrado',
        'Cartão de débito crypto',
        'Academia Binance para aprendizagem',
      ],
    ),
    AppItem(
      name: 'eToro',
      description: 'Plataforma de trading social e investimentos globais',
      category: 'Trading',
      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/1d/Etoro-logo.svg',
      color: const Color(0xFF56BE8E),
      url: 'https://www.etoro.com',
      rating: 4.5,
      monthlyUsers: '30M',
      developer: 'eToro Group Ltd',
      features: [
        'Copy trading de investidores profissionais',
        'Ações e ETFs sem comissões',
        'Trading de crypto e forex',
        'Portfólio diversificado automaticamente',
        'Comunidade social de traders',
        'Conta demo gratuita para prática',
      ],
    ),
    AppItem(
      name: 'Coinbase',
      description: 'Compre, venda e ganhe criptomoedas com máxima segurança',
      category: 'Crypto',
      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/1a/Coinbase.svg',
      color: const Color(0xFF0052FF),
      url: 'https://www.coinbase.com',
      rating: 4.6,
      monthlyUsers: '108M',
      developer: 'Coinbase Inc',
      features: [
        'Interface intuitiva para iniciantes',
        'Earn crypto assistindo vídeos educativos',
        'Staking automático',
        'Carteira segura com seguro FDIC',
        'Cartão de débito com 4% cashback',
        'NFT marketplace',
      ],
    ),
    AppItem(
      name: 'Swagbucks',
      description: 'Ganhe dinheiro real assistindo vídeos e fazendo pesquisas online',
      category: 'Remuneração',
      iconUrl: 'https://www.swagbucks.com/images/swagbucks-logo.svg',
      color: const Color(0xFFFF6600),
      url: 'https://www.swagbucks.com',
      rating: 4.4,
      monthlyUsers: '20M',
      developer: 'Prodege LLC',
      features: [
        'Pesquisas pagas diariamente',
        'Cashback em compras online',
        'Assista vídeos e ganhe pontos',
        'Jogue jogos para recompensas',
        'Bônus de boas-vindas',
        'Pagamentos via PayPal ou cartões presente',
      ],
    ),
    AppItem(
      name: 'Revolut',
      description: 'Super app financeiro com trading, crypto e cashback',
      category: 'Investimento',
      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Revolut_logo.svg',
      color: const Color(0xFF0075EB),
      url: 'https://www.revolut.com',
      rating: 4.6,
      monthlyUsers: '35M',
      developer: 'Revolut Ltd',
      features: [
        'Conta bancária sem taxas',
        'Trading de ações e crypto',
        'Cashback de até 1% em compras',
        'Câmbio de moedas ao vivo',
        'Cofres para poupança',
        'Seguros de viagem e saúde',
      ],
    ),
    AppItem(
      name: 'Kraken',
      description: 'Exchange profissional com staking e trading avançado de crypto',
      category: 'Crypto',
      iconUrl: 'https://cryptologos.cc/logos/versions/kraken-kraken-logo-full.svg',
      color: const Color(0xFF5741D9),
      url: 'https://www.kraken.com',
      rating: 4.7,
      monthlyUsers: '9M',
      developer: 'Payward Inc',
      features: [
        'Mais de 200 criptomoedas disponíveis',
        'Staking com até 23% APY',
        'Futures e margin trading',
        'Segurança de nível bancário',
        'Trading OTC para grandes volumes',
        'API para trading automatizado',
      ],
    ),
    AppItem(
      name: 'Bet365',
      description: 'Líder mundial em apostas desportivas online e casino ao vivo',
      category: 'Apostas',
      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4b/Bet365_logo.svg',
      color: const Color(0xFF00843D),
      url: 'https://www.bet365.com',
      rating: 4.5,
      monthlyUsers: '80M',
      developer: 'Hillside Technology Ltd',
      features: [
        'Transmissão ao vivo de eventos',
        'Apostas em mais de 30 desportos',
        'Casino com dealers ao vivo',
        'Cash out durante eventos',
        'Bónus de boas-vindas 100%',
        'App móvel premiado',
      ],
    ),
    AppItem(
      name: 'Mistplay',
      description: 'Transforme tempo de jogo em dinheiro real e cartões presente',
      category: 'Remuneração',
      iconUrl: 'https://www.mistplay.com/assets/images/logo.svg',
      color: const Color(0xFF6C5CE7),
      url: 'https://www.mistplay.com',
      rating: 4.5,
      monthlyUsers: '15M',
      developer: 'Mistplay Inc',
      features: [
        'Jogue jogos gratuitos e ganhe',
        'Resgatar por cartões Google Play e Amazon',
        'Missões diárias com bónus',
        'Programa de níveis com benefícios',
        'Novos jogos adicionados semanalmente',
        'Comunidade de gamers',
      ],
    ),
  ];

  List<AppItem> get _filteredApps {
    if (_selectedCategory == 'Todos') return _apps;
    return _apps.where((app) => app.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: false,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: ThemeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Hub',
                      style: TextStyle(
                        color: ThemeService.textColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (context) => SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: ThemeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(
                            CupertinoIcons.search,
                            color: ThemeService.textColor.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Pesquisar no Google',
                            style: TextStyle(
                              color: ThemeService.textColor.withOpacity(0.5),
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                HubWidgetsSection(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 44,
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
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = category);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
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
                              borderRadius: BorderRadius.circular(22),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = _filteredApps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(app: app),
                  );
                },
                childCount: _filteredApps.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final AppItem app;

  const AppCard({Key? key, required this.app}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 64,
                height: 64,
                color: app.color.withOpacity(0.1),
                child: Center(
                  child: SvgPicture.network(
                    app.iconUrl,
                    width: 40,
                    height: 40,
                    placeholderBuilder: (context) => Icon(
                      CupertinoIcons.app_fill,
                      size: 40,
                      color: app.color,
                    ),
                  ),
                ),
              ),
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
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Color(0xFFFFCC00),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        app.rating.toString(),
                        style: TextStyle(
                          color: ThemeService.textColor.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.person_2_fill,
                        color: ThemeService.textColor.withOpacity(0.5),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${app.monthlyUsers}/mês',
                        style: TextStyle(
                          color: ThemeService.textColor.withOpacity(0.6),
                          fontSize: 13,
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            expandedHeight: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: ThemeService.isDarkMode
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(CupertinoIcons.back, color: ThemeService.textColor),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: app.color.withOpacity(0.1),
                      child: Center(
                        child: SvgPicture.network(
                          app.iconUrl,
                          width: 70,
                          height: 70,
                          placeholderBuilder: (context) => Icon(
                            CupertinoIcons.app_fill,
                            size: 70,
                            color: app.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    app.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    app.developer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat(
                        context,
                        app.rating.toString(),
                        'Avaliação',
                        CupertinoIcons.star_fill,
                      ),
                      const SizedBox(width: 32),
                      _buildStat(
                        context,
                        app.monthlyUsers,
                        'Usuários/mês',
                        CupertinoIcons.person_2_fill,
                      ),
                      const SizedBox(width: 32),
                      _buildStat(
                        context,
                        app.category,
                        'Categoria',
                        CupertinoIcons.square_grid_2x2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    app.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Funcionalidades',
                      style: TextStyle(
                        color: ThemeService.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...app.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: app.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  color: ThemeService.textColor.withOpacity(0.8),
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            fullscreenDialog: true,
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: app.color,
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: ThemeService.textColor.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    if (_controller.text.trim().isEmpty) return;
    
    final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(_controller.text)}';
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => WebViewScreen(
          url: searchUrl,
          title: 'Busca: ${_controller.text}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: const Color(0xFF1877F2),
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: TextStyle(color: ThemeService.textColor),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar no Google',
                        hintStyle: TextStyle(
                          color: ThemeService.textColor.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: ThemeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _search();
                    },
                    child: Text(
                      'Buscar',
                      style: TextStyle(
                        color: const Color(0xFF1877F2),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: ThemeService.isDarkMode
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              elevation: 0,
              leading: IconButton(
                icon: Icon(CupertinoIcons.xmark, color: ThemeService.textColor),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.reload();
                  },
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
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

// hub_widgets.dart - Widgets do Hub
class HubWidgetsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          HubWidget(
            title: 'Ganhos Hoje',
            value: '\$24.50',
            icon: CupertinoIcons.money_dollar_circle_fill,
            color: const Color(0xFF34C759),
            subtitle: '+12%',
          ),
          HubWidget(
            title: 'Trading Ativo',
            value: '5 posições',
            icon: CupertinoIcons.chart_bar_alt_fill,
            color: const Color(0xFF1877F2),
            subtitle: 'BTC, ETH...',
          ),
          HubWidget(
            title: 'Cashback',
            value: '€45.20',
            icon: CupertinoIcons.creditcard_fill,
            color: const Color(0xFFFF9500),
            subtitle: 'Este mês',
          ),
          HubWidget(
            title: 'Recompensas',
            value: '850 pontos',
            icon: CupertinoIcons.star_fill,
            color: const Color(0xFFAF52DE),
            subtitle: 'Disponível',
          ),
        ],
      ),
    );
  }
}

class HubWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const HubWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
