// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../services/language_service.dart';
import 'admin_panel_screen.dart';
import 'news_detail_screen.dart';
import 'create_post_screen.dart';
import 'user_drawer.dart';
import 'search_screen.dart';
import '../models/news_article.dart';
import '../widgets/wallet_card.dart';
import '../widgets/post_card.dart';
import 'crypto_list_screen.dart';
import 'more_screen.dart';
import 'home_widgets.dart';
import 'home_crypto_section.dart' as crypto_section;
import 'plans_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const HomeScreen({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _userData;
  List<NewsArticle> _newsArticles = [];
  bool _loadingNews = true;
  bool _showNews = true;
  String _cardStyle = 'modern';
  int _messageCount = 0;
  int _groupCount = 0;
  List<crypto_section.CryptoData> _cryptoData = [];
  bool _loadingCrypto = true;
  Timer? _cryptoTimer;
  final PageController _newsPageController = PageController();
  final PageController _cryptoPageController = PageController();
  int _currentNewsPage = 0;
  int _currentCryptoPage = 0;
  final ScrollController _scrollController = ScrollController();
  String _headerTitle = '';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _safeSetUserOnline(true);
    _loadNews();
    _loadStats();
    _loadCryptoData();
    _cryptoTimer = Timer.periodic(Duration(seconds: 10), (_) => _loadCryptoData());
    
    _scrollController.addListener(_onScroll);
    _newsPageController.addListener(() {
      setState(() {
        _currentNewsPage = _newsPageController.page?.round() ?? 0;
      });
    });
    _cryptoPageController.addListener(() {
      setState(() {
        _currentCryptoPage = _cryptoPageController.page?.round() ?? 0;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset > 600) {
        if (_headerTitle != 'Sheets') {
          setState(() => _headerTitle = 'Sheets');
        }
      } else {
        if (_headerTitle != '') {
          setState(() => _headerTitle = '');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadCryptoData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/ticker/24hr'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final usdtPairs = data.where((coin) => 
          coin['symbol'].toString().endsWith('USDT') && 
          !coin['symbol'].toString().contains('DOWN') &&
          !coin['symbol'].toString().contains('UP') &&
          !coin['symbol'].toString().contains('BEAR') &&
          !coin['symbol'].toString().contains('BULL')
        ).toList();
        
        usdtPairs.sort((a, b) => double.parse(b['quoteVolume'].toString()).compareTo(double.parse(a['quoteVolume'].toString())));
        
        if (mounted) {
          setState(() {
            _cryptoData = usdtPairs.take(3).map((coin) => crypto_section.CryptoData.fromBinance(coin)).toList();
            _loadingCrypto = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCrypto = false);
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final convSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .get();

      int totalMessages = 0;
      for (var conv in convSnapshot.docs) {
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conv.id)
            .collection('messages')
            .where('senderId', isEqualTo: user.uid)
            .get();
        totalMessages += messagesSnapshot.docs.length;
      }

      final groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _messageCount = totalMessages;
          _groupCount = groupSnapshot.docs.length;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadNews() async {
    setState(() => _loadingNews = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        List<NewsArticle> articles = [];
        for (var article in results.take(10)) {
          articles.add(NewsArticle.fromNewsdata(article));
        }

        if (mounted) {
          setState(() {
            _newsArticles = articles;
            _loadingNews = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingNews = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingNews = false);
      }
    }
  }

  @override
  void dispose() {
    _cryptoTimer?.cancel();
    _newsPageController.dispose();
    _cryptoPageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _safeSetUserOnline(false);
    super.dispose();
  }

  Future<void> _safeSetUserOnline(bool isOnline) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isOnline': isOnline});
      }
    } catch (e) {}
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userSubscription?.cancel();

      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _userData = data;
            _showNews = _userData?['showNews'] ?? true;
            _cardStyle = _userData?['cardStyle'] ?? 'modern';
          });
        }
      }, onError: (err) {});
    }
  }

  void _showUserDrawer() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => UserDrawer(
        userData: _userData,
        onThemeChanged: widget.onThemeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
        showNews: _showNews,
        cardStyle: _cardStyle,
        onShowNewsChanged: (value) async {
          setState(() => _showNews = value);
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'showNews': value});
            } catch (e) {}
          }
        },
        onCardStyleChanged: (style) {
          setState(() => _cardStyle = style);
        },
      ),
    );
  }

  Future<bool> _checkAndDecrementToken(String action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final isPro = userDoc.data()?['pro'] == true;
        if (isPro) return true;

        final currentTokens = userDoc.data()?['tokens'] ?? 0;
        
        if (currentTokens <= 0) {
          _showNoTokensDialog();
          return false;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'tokens': currentTokens - 1});
        
        return true;
      }
    } catch (e) {}
    return false;
  }

  void _showNoTokensDialog() {
    final username = _userData?['username'] ?? 'Usuário';
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Olá, $username!'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Os seus tokens estão esgotados. Adquira saldo para obter mais tokens e continuar usando todos os recursos do aplicativo.',
            style: TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Continuar'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => PlansScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreatePost() async {
    final isPro = _userData?['pro'] == true;

    if (!isPro) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Recursos PRO'),
          content: Text(
              'Apenas usuários PRO podem criar publicações. Atualize sua conta para desbloquear este recurso.'),
          actions: [
            CupertinoDialogAction(
              child: Text('Entendi'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text('Atualizar para PRO'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => PlansScreen()),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    final canProceed = await _checkAndDecrementToken('create_post');
    if (!canProceed) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CreatePostScreen(
          userData: _userData ?? {},
        ),
      ),
    );
  }

  Future<void> _handleNewsClick(NewsArticle article, int index) async {
    final canProceed = await _checkAndDecrementToken('view_news');
    if (!canProceed) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NewsDetailScreen(
          article: article,
          allArticles: _newsArticles,
          currentIndex: index,  // CORREÇÃO: mudado de initialIndex para currentIndex
        ),
      ),
    );
  }

  void _showOptionsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              _buildModalOption(
                icon: CupertinoIcons.arrow_up_circle_fill,
                label: 'Enviar',
                isDark: isDark,
                onPressed: () => Navigator.pop(context),
              ),
              _buildModalOption(
                icon: CupertinoIcons.add_circled_solid,
                label: 'Criar Publicação',
                isDark: isDark,
                onPressed: () {
                  Navigator.pop(context);
                  _handleCreatePost();
                },
              ),
              _buildModalOption(
                icon: CupertinoIcons.arrow_down_circle_fill,
                label: 'Receber',
                isDark: isDark,
                onPressed: () => Navigator.pop(context),
              ),
              _buildModalOption(
                icon: CupertinoIcons.ellipsis_circle_fill,
                label: 'Mais Opções',
                isDark: isDark,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => TradingWarningScreen()),
                  );
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.systemBlue, size: 24),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = _userData?['username'] ?? 'Usuário';

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF5F5F5),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
          leading: Padding(
            padding: EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _headerTitle.isEmpty ? username : _headerTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.search,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  size: 22,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => SearchScreen()),
                  );
                },
              ),
              SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFFF444F),
                  backgroundImage: (_userData?['profile_image'] != null &&
                          (_userData!['profile_image'] as String).isNotEmpty)
                      ? NetworkImage(_userData!['profile_image'])
                      : null,
                  child: (_userData?['profile_image'] == null ||
                          (_userData!['profile_image'] as String).isEmpty)
                      ? Text(
                          username[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                onPressed: _showUserDrawer,
              ),
            ],
          ),
          border: null,
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await _loadUserData();
                  await _loadNews();
                  await _loadStats();
                  await _loadCryptoData();
                },
              ),
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    WalletCard(
                      userData: _userData,
                      cardStyle: _cardStyle,
                      showCustomizeButton: false,
                    ),
                    SizedBox(height: 16),
                    _buildActionButton(isDark),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: HomeWidgets.buildStatCard(
                            icon: CupertinoIcons.chat_bubble_2_fill,
                            title: 'Mensagens',
                            value: '$_messageCount',
                            color: CupertinoColors.systemBlue,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: HomeWidgets.buildStatCard(
                            icon: CupertinoIcons.group_solid,
                            title: 'Grupos',
                            value: '$_groupCount',
                            color: CupertinoColors.systemGreen,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    crypto_section.HomeCryptoSection(
                      cryptoData: _cryptoData,
                      loadingCrypto: _loadingCrypto,
                      isDark: isDark,
                      pageController: _cryptoPageController,
                      currentPage: _currentCryptoPage,
                      onViewMore: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => CryptoListScreen(),
                          ),
                        );
                      },
                    ),
                    if (_showNews) ...[
                      SizedBox(height: 32),
                      Text(
                        'Últimas Notícias',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      _loadingNews
                          ? Center(child: CupertinoActivityIndicator(radius: 16))
                          : Column(
                              children: [
                                Container(
                                  height: 140,
                                  child: PageView.builder(
                                    controller: _newsPageController,
                                    physics: BouncingScrollPhysics(),
                                    itemCount: _newsArticles.length,
                                    itemBuilder: (context, index) {
                                      final article = _newsArticles[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: GestureDetector(
                                          onTap: () => _handleNewsClick(article, index),
                                          child: HomeWidgets.buildNewsCard(
                                            article: article,
                                            index: index,
                                            isDark: isDark,
                                            context: context,
                                            allArticles: _newsArticles,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 12),
                                HomeWidgets.buildPageIndicator(
                                  count: _newsArticles.length,
                                  currentPage: _currentNewsPage,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                    ],
                  ]),
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 60,
                  child: Container(
                    color: isDark ? Color(0xFF000000) : Color(0xFFF5F5F5),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Sheets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('publicacoes')
                      .orderBy('timestamp', descending: true)
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CupertinoActivityIndicator(radius: 16)),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(CupertinoIcons.doc_text, size: 60, color: CupertinoColors.systemGrey),
                              SizedBox(height: 16),
                              Text('Nenhuma publicação ainda', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(CupertinoIcons.doc_text, size: 60, color: CupertinoColors.systemGrey),
                              SizedBox(height: 16),
                              Text('Nenhuma publicação ainda', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: posts.map((docSnap) {
                          final post = docSnap.data() as Map<String, dynamic>;
                          final postId = docSnap.id;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: PostCard(
                              post: post,
                              postId: postId,
                              isDark: isDark,
                              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showOptionsBottomSheet,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.activeBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Começar',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

void unawaited(Future? f) {}