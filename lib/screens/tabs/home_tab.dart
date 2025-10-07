import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Escolhe símbolos principais (Binance style: e.g. BTCUSDT)
  final List<String> _symbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT'];
  Map<String, double> _prices = {};
  Map<String, List<double>> _klines = {}; // arrays de preços para mini-charts
  bool _isLoadingCrypto = true;
  bool _expandedMarkets = false;
  int _messageCount = 0;
  int _channelCount = 0;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingCrypto = true);
    await Future.wait([
      _loadCryptoDataFromBinance(),
      _loadChatStats(),
    ]);
    if (mounted) setState(() => _isLoadingCrypto = false);
  }

  /// Busca preços e klines da Binance (REST)
  /// Preço atual: GET /api/v3/ticker/price?symbol=BTCUSDT  (Binance Spot docs)
  /// Klines: GET /api/v3/klines?symbol=BTCUSDT&interval=1m&limit=60
  /// Documentação: Binance Spot API (market data endpoints). 2
  Future<void> _loadCryptoDataFromBinance() async {
    try {
      final tempPrices = <String, double>{};
      final tempKlines = <String, List<double>>{};

      for (final sym in _symbols) {
        // preço atual
        final priceResp = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$sym'));
        if (priceResp.statusCode == 200) {
          final p = json.decode(priceResp.body);
          tempPrices[sym] = double.tryParse(p['price'].toString()) ?? 0.0;
        }

        // kline (últimos 60 candles 1m) -> pegamos close prices
        final kResp = await http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=$sym&interval=1m&limit=60'));
        if (kResp.statusCode == 200) {
          final arr = json.decode(kResp.body) as List;
          final closes = arr.map((c) => double.tryParse(c[4].toString()) ?? 0.0).toList();
          tempKlines[sym] = closes;
        } else {
          tempKlines[sym] = [];
        }
      }

      _prices = tempPrices;
      _klines = tempKlines;
    } catch (e) {
      // falha silenciosa mas mantém UI estável
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados de cripto: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _loadChatStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final chatsSnapshot = await FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: user.uid).get();
      int messages = 0, channels = 0;
      for (var chat in chatsSnapshot.docs) {
        final data = chat.data();
        if (data['type'] == 'channel') channels++; else messages++;
      }
      if (mounted) setState(() { _messageCount = messages; _channelCount = channels; });
    } catch (e) {
      // apenas log
      debugPrint('Erro carregar estatísticas: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Future<void> _maybeShowWelcome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'welcome_shown_${user.uid}';
    final shown = prefs.getBool(key) ?? false;
    if (!shown) {
      // mostra um banner modal (não card). aparece apenas uma vez após login
      if (mounted) {
        showCupertinoModalPopup(
          context: context,
          builder: (ctx) => CupertinoActionSheet(
            title: Text('${_getGreeting()}, ${user.displayName?.split(' ').first ?? 'Usuário'}'),
            message: const Text('Bem-vindo! A tua área de mercado está pronta.'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text('Começar'),
              ),
            ],
          ),
        );
      }
      await prefs.setBool(key, true);
    }
  }

  // Wallet card actions (stub — conecta à tua lógica)
  void _onAdd() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionar — implementar integração'))); }
  void _onSend() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviar — implementar integração'))); }
  void _onConsult() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultar — implementar integração'))); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Usuário';

    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      // AppBar com blur effect (fundo translúcido)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: ClipRect(
          child: Container(
            // cor base transparente para respeitar tema
            color: ThemeService.backgroundColor.withOpacity(0.7),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Início',
                          style: TextStyle(color: ThemeService.textColor, fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                      ),
                      // botão perfil pequeno estilo iOS (sem botão de reiniciar)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(CupertinoIcons.person_circle, color: ThemeService.textColor, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, '/main'); // teu fluxo
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Wallet card grande (sem gradiente; cor sólida ajustada)
            _buildWalletCard(),
            const SizedBox(height: 20),
            // stats -> conversas/canais
            _buildStatsCard(),
            const SizedBox(height: 20),
            // Markets header
            _buildMarketsHeader(),
            const SizedBox(height: 12),
            // Markets cards (linha ou expandida)
            _isLoadingCrypto ? _buildCryptoLoading() : _buildMarketsList(),
            const SizedBox(height: 20),
            // Top assets list (expandable)
            _buildTopCryptos(),
            const SizedBox(height: 40)
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    // cor sólida parecida com cartões reais (não gradient)
    final cardColor = ThemeService.isDarkMode ? const Color(0xFF111214) : const Color(0xFF1E88E5);
    final textColorOnCard = Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header wallet
          Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(CupertinoIcons.creditcard, color: Colors.white)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Carteira Principal', style: TextStyle(color: textColorOnCard.withOpacity(0.95), fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Saldo: € 12.345,67', style: TextStyle(color: textColorOnCard.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const Spacer(),
              IconButton(
                icon: Icon(CupertinoIcons.info, color: textColorOnCard),
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detalhes da carteira'))); },
              )
            ],
          ),
          const SizedBox(height: 18),
          // ações: Adicionar / Enviar / Consultar (iOS style buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _walletActionButton(Icons.add, 'Adicionar', _onAdd),
              _walletActionButton(CupertinoIcons.arrow_up_right, 'Enviar', _onSend),
              _walletActionButton(CupertinoIcons.search, 'Consultar', _onConsult),
            ],
          )
        ],
      ),
    );
  }

  Widget _walletActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: ThemeService.isDarkMode ? Colors.white10 : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ThemeService.isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.18)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem(CupertinoIcons.chat_bubble_2_fill, _messageCount.toString(), 'Conversas'),
        _statItem(CupertinoIcons.group_solid, _channelCount.toString(), 'Canais'),
        _statItem(CupertinoIcons.bell_fill, '0', 'Alertas'),
      ]),
    );
  }

  Widget _statItem(IconData ic, String value, String label) {
    return Column(children: [
      Icon(ic, color: const Color(0xFF1877F2), size: 28),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: ThemeService.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: ThemeService.textColor.withOpacity(0.6))),
    ]);
  }

  Widget _buildMarketsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Mercados', style: TextStyle(color: ThemeService.textColor, fontSize: 20, fontWeight: FontWeight.w700)),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(_expandedMarkets ? 'Mostrar menos' : 'Ver Mercados', style: const TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w600)),
          onPressed: () {
            setState(() {
              _expandedMarkets = !_expandedMarkets;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCryptoLoading() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: ThemeService.cardColor, borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMarketsList() {
    // se expandido, mostra todos os símbolos (podes alimentar com lista maior)
    final symbolsToShow = _expandedMarkets ? (_symbols + ['ADAUSDT', 'SOLUSDT']) : _symbols;
    return Column(
      children: symbolsToShow.map((s) {
        final price = _prices[s] ?? 0.0;
        final closes = _klines[s] ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _cryptoCard(symbol: s, price: price, closes: closes),
        );
      }).toList(),
    );
  }

  // cartão custom sem ListTile (sem libs externas)
  Widget _cryptoCard({required String symbol, required double price, required List<double> closes}) {
    // derive simple color by symbol
    final color = _symbolColor(symbol);
    final priceStr = price == 0.0 ? '—' : (price >= 1000 ? '€${price.toStringAsFixed(0)}' : '€${price.toStringAsFixed(2)}');
    final change = _calcChangeFromCloses(closes);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // abrir tela de detalhe (implementar)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$symbol - abrir detalhes')));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ThemeService.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeService.isDarkMode ? Colors.white10 : Colors.grey.withOpacity(0.12)),
        ),
        child: Row(children: [
          // ícone do ativo (Image.network -> substitui pela url de ícone oficial se tiveres um CDN)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Image.network(
                'https://cryptoicons.org/api/icon/${_symbolToIconName(symbol)}/64', // fallback: podes apontar para logos oficiais
                errorBuilder: (_, __, ___) => Icon(CupertinoIcons.money_dollar, color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_symbolShort(symbol), style: TextStyle(color: ThemeService.textColor, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(_symbolFullName(symbol), style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 13)),
            ]),
          ),
          // mini chart custom
          SizedBox(
            width: 120,
            height: 48,
            child: MiniSparkline(prices: closes, lineColor: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(priceStr, style: TextStyle(color: ThemeService.textColor, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (change != null) Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(change >= 0 ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down, color: change >= 0 ? Colors.green : Colors.red, size: 12),
              const SizedBox(width: 4),
              Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(color: change >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
            ]),
          ])
        ]),
      ),
    );
  }

  // helpers
  Color _symbolColor(String s) {
    if (s.startsWith('BTC')) return const Color(0xFFF7931A);
    if (s.startsWith('ETH')) return const Color(0xFF627EEA);
    if (s.startsWith('BNB')) return const Color(0xFFF0B90B);
    return const Color(0xFF1877F2);
  }

  String _symbolShort(String s) => s.replaceAll('USDT', '');

  String _symbolFullName(String s) {
    if (s.startsWith('BTC')) return 'Bitcoin';
    if (s.startsWith('ETH')) return 'Ethereum';
    if (s.startsWith('BNB')) return 'BNB';
    return s;
  }

  String _symbolToIconName(String s) {
    // cryptoicons expects lowercase symbol code like 'btc', 'eth', etc.
    final short = _symbolShort(s).toLowerCase();
    return short;
  }

  double? _calcChangeFromCloses(List<double> closes) {
    if (closes.length < 2) return null;
    final first = closes.first;
    final last = closes.last;
    if (first == 0) return null;
    return ((last - first) / first) * 100;
  }

  Widget _buildTopCryptos() {
    // "Ver Todos" já integrado com expand toggle em header/markets
    return const SizedBox.shrink();
  }
}

/// MiniSparkline: desenha mini gráfico e suporta drag para ver valor.
///
/// - Recebe lista de preços (closes). Se empty, mostra placeholder.
/// - Ao arrastar mostra um tooltip com preço do ponto.
class MiniSparkline extends StatefulWidget {
  final List<double> prices;
  final Color lineColor;
  const MiniSparkline({Key? key, required this.prices, required this.lineColor}) : super(key: key);

  @override
  State<MiniSparkline> createState() => _MiniSparklineState();
}

class _MiniSparklineState extends State<MiniSparkline> {
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragDown: (d) => _onDrag(d.localPosition, context.size),
      onLongPressStart: (d) => _onDrag(d.localPosition, context.size),
      onPanUpdate: (d) => _onDrag(d.localPosition, context.size),
      onPanEnd: (_) => setState(() => _activeIndex = null),
      child: CustomPaint(
        painter: _SparkPainter(prices: widget.prices, color: widget.lineColor, activeIndex: _activeIndex),
      ),
    );
  }

  void _onDrag(Offset? local, Size? size) {
    if (local == null || size == null) return;
    final w = size.width;
    final count = widget.prices.length;
    if (count == 0) return;
    final dx = local.dx.clamp(0.0, w);
    final idx = ((dx / max(1, w)) * (count - 1)).round().clamp(0, count - 1);
    setState(() {
      _activeIndex = idx;
    });
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> prices;
  final Color color;
  final int? activeIndex;
  _SparkPainter({required this.prices, required this.color, this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke..isAntiAlias = true..color = color;
    if (prices.isEmpty) {
      // placeholder line
      final p = Path();
      p.moveTo(2, size.height / 2);
      p.lineTo(size.width - 2, size.height / 2);
      canvas.drawPath(p, paint..color = color.withOpacity(0.2));
      return;
    }

    final minP = prices.reduce(min);
    final maxP = prices.reduce(max);
    final range = (maxP - minP) == 0 ? 1.0 : maxP - minP;
    final stepX = size.width / (prices.length - 1);

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = stepX * i;
      final y = size.height - ((prices[i] - minP) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    // sombra/filled area (subtle)
    final fill = Paint()..style = PaintingStyle.fill..color = color.withOpacity(0.06);
    final area = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(area, fill);

    // stroke
    canvas.drawPath(path, paint);

    // active marker
    if (activeIndex != null && activeIndex! >= 0 && activeIndex! < prices.length) {
      final px = stepX * activeIndex!;
      final py = size.height - ((prices[activeIndex!] - minP) / range) * size.height;
      final dot = Paint()..style = PaintingStyle.fill..color = Colors.white;
      // ring
      canvas.drawCircle(Offset(px, py), 3.6, Paint()..color = color);
      canvas.drawCircle(Offset(px, py), 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.prices != prices || old.activeIndex != activeIndex;
}
