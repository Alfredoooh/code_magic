// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/language_service.dart';
import 'admin_panel_screen.dart';
import 'news_detail_screen.dart';
import 'create_post_screen.dart';
import 'user_drawer.dart';
import 'search_screen.dart';
import '../models/news_article.dart';
import '../widgets/wallet_card.dart';
import '../widgets/post_card.dart';
import 'crypto_list_screen.dart' hide SearchScreen;
import 'more_options_screen.dart' hide WalletCard;
import 'home_widgets.dart';
import 'home_crypto_section.dart' as crypto_section;
import 'plans_screen.dart';
import 'home_screen_helper.dart';

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
  bool _showNewPostsBanner = false;
  int _newPostsCount = 0;
  List<String> _newPostsUserImages = [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postsSubscription;
  String? _lastSeenPostId;
  bool _hasShownWelcomeBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _safeSetUserOnline(true);
    HomeScreenHelper.loadNews((articles, loading) {
      if (mounted) setState(() {
        _newsArticles = articles;
        _loadingNews = loading;
      });
    });
    HomeScreenHelper.loadStats((messages, groups) {
      if (mounted) setState(() {
        _messageCount = messages;
        _groupCount = groups;
      });
    });
    HomeScreenHelper.loadCryptoData((data, loading) {
      if (mounted) setState(() {
        _cryptoData = data;
        _loadingCrypto = loading;
      });
    });
    _cryptoTimer = Timer.periodic(Duration(seconds: 10), (_) {
      HomeScreenHelper.loadCryptoData((data, loading) {
        if (mounted) setState(() {
          _cryptoData = data;
          _loadingCrypto = loading;
        });
      });
    });

    _scrollController.addListener(_onScroll);
    _newsPageController.addListener(() {
      if (_newsPageController.page != null) {
        final newPage = _newsPageController.page!.round();
        if (newPage != _currentNewsPage) {
          setState(() => _currentNewsPage = newPage);
        }
      }
    });
    _cryptoPageController.addListener(() {
      if (_cryptoPageController.page != null) {
        final newPage = _cryptoPageController.page!.round();
        if (newPage != _currentCryptoPage) {
          setState(() => _currentCryptoPage = newPage);
        }
      }
    });

    _listenToNewPosts();
  }

  void _listenToNewPosts() {
    _postsSubscription = FirebaseFirestore.instance
        .collection('publicacoes')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      if (_lastSeenPostId == null && snapshot.docs.isNotEmpty) {
        _lastSeenPostId = snapshot.docs.first.id;
        return;
      }

      if (snapshot.docs.isNotEmpty) {
        final latestPostId = snapshot.docs.first.id;
        if (latestPostId != _lastSeenPostId) {
          final newPosts = snapshot.docs.takeWhile((doc) => doc.id != _lastSeenPostId).toList();
          if (newPosts.isNotEmpty) {
            final userImages = newPosts
                .map((doc) => doc.data()['profile_image'] as String?)
                .where((img) => img != null && img.isNotEmpty)
                .take(3)
                .cast<String>()
                .toList();

            if (mounted && _scrollController.offset > 100) {
              setState(() {
                _newPostsCount = newPosts.length;
                _newPostsUserImages = userImages;
                _showNewPostsBanner = true;
              });
            }
          }
        }
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    FirebaseFirestore.instance
        .collection('publicacoes')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _lastSeenPostId = snapshot.docs.first.id;
      }
    });

    setState(() {
      _showNewPostsBanner = false;
      _newPostsCount = 0;
      _newPostsUserImages = [];
    });
  }

  void _onScroll() {
    // Removido o botão scroll to top
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cryptoTimer?.cancel();
    _newsPageController.dispose();
    _cryptoPageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _postsSubscription?.cancel();
    _safeSetUserOnline(false);
    super.dispose();
  }

  Future<void> _safeSetUserOnline(bool isOnline) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isOnline': isOnline});
      }
    } catch (e) {}
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userSubscription?.cancel();

      _userSubscription = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();

          final isAdmin = data?['admin'] == true;
          if (isAdmin && !_hasShownWelcomeBack) {
            _hasShownWelcomeBack = true;
            return;
          }

          setState(() {
            _userData = data;
            _showNews = _userData?['showNews'] ?? true;
            _cardStyle = _userData?['cardStyle'] ?? 'modern';
          });

          if (!_hasShownWelcomeBack) {
            _hasShownWelcomeBack = true;
            _showWelcomeBackMessage(data?['username'] ?? 'Usuário');
          }
        }
      }, onError: (err) {});
    }
  }

  void _showWelcomeBackMessage(String username) {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            title: Text('🎉'),
            content: Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Bem-vindo de volta, $username!',
                style: TextStyle(fontSize: 17),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('Continuar'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    });
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
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'showNews': value});
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final isPro = userDoc.data()?['pro'] == true;
        if (isPro) return true;

        final currentTokens = userDoc.data()?['tokens'] ?? 0;

        if (currentTokens <= 0) {
          _showNoTokensDialog();
          return false;
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'tokens': currentTokens - 1});
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
                CupertinoPageRoute(
                  builder: (context) => PlansScreen(),
                  fullscreenDialog: true,
                ),
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
          content: Text('Apenas usuários PRO podem criar publicações. Atualize sua conta para desbloquear este recurso.'),
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
                  CupertinoPageRoute(
                    builder: (context) => PlansScreen(),
                    fullscreenDialog: true,
                  ),
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
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _handleNewsClick(NewsArticle article, int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canProceed = await _checkAndDecrementToken('view_news');
    if (!canProceed) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NewsDetailScreen(
          article: article,
          allArticles: _newsArticles,
          currentIndex: index,
          isDark: isDark,
        ),
        fullscreenDialog: true,
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
                    CupertinoPageRoute(
                      builder: (context) => MoreOptionsScreen(),
                      fullscreenDialog: true,
                    ),
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

  ImageProvider? _getProfileImage(String? profileImage, String username) {
    if (profileImage == null || profileImage.isEmpty) return null;
    
    // Verifica se é base64
    if (profileImage.startsWith('data:image')) {
      try {
        final base64String = profileImage.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    }
    
    // Se não for base64, trata como URL
    return NetworkImage(profileImage);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = _userData?['username'] ?? 'Usuário';
    final profileImage = _userData?['profile_image'] as String?;

    return WillPopScope(
      onWillPop: () async {
        // Volta ao topo e atualiza ao pressionar voltar
        _scrollToTop();
        await Future.wait([
          _loadUserData(),
          HomeScreenHelper.loadNews((articles, loading) {
            if (mounted) setState(() {
              _newsArticles = articles;
              _loadingNews = loading;
            });
          }),
          HomeScreenHelper.loadStats((messages, groups) {
            if (mounted) setState(() {
              _messageCount = messages;
              _groupCount = groups;
            });
          }),
          HomeScreenHelper.loadCryptoData((data, loading) {
            if (mounted) setState(() {
              _cryptoData = data;
              _loadingCrypto = loading;
            });
          }),
        ]);
        return false;
      },
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF5F5F5),
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              slivers: [
                CupertinoSliverNavigationBar(
                  backgroundColor: isDark ? Color(0xFF000000).withOpacity(0.9) : Color(0xFFF5F5F5).withOpacity(0.9),
                  border: null,
                  largeTitle: Text(username),
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
                            CupertinoPageRoute(
                              builder: (context) => SearchScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFFF444F),
                          backgroundImage: _getProfileImage(profileImage, username),
                          child: _getProfileImage(profileImage, username) == null
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: TextStyle(fontSize: 14, color: CupertinoColors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        onPressed: _showUserDrawer,
                      ),
                    ],
                  ),
                ),
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    await Future.wait([
                      _loadUserData(),
                      HomeScreenHelper.loadNews((articles, loading) {
                        if (mounted) setState(() {
                          _newsArticles = articles;
                          _loadingNews = loading;
                        });
                      }),
                      HomeScreenHelper.loadStats((messages, groups) {
                        if (mounted) setState(() {
                          _messageCount = messages;
                          _groupCount = groups;
                        });
                      }),
                      HomeScreenHelper.loadCryptoData((data, loading) {
                        if (mounted) setState(() {
                          _cryptoData = data;
                          _loadingCrypto = loading;
                        });
                      }),
                    ]);
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
                            child: _buildStatCard(
                              icon: CupertinoIcons.chat_bubble_2_fill,
                              title: 'Mensagens',
                              value: '$_messageCount',
                              color: CupertinoColors.systemBlue,
                              isDark: isDark,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
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
                              fullscreenDialog: true,
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
                                            child: HomeScreenHelper.buildNewsCard(
                                              article: article,
                                              isDark: isDark,
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
                      color: isDark ? Color(0xFF000000).withOpacity(0.9) : Color(0xFFF5F5F5).withOpacity(0.9),
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
                    stream: FirebaseFirestore.instance.collection('publicacoes').orderBy('timestamp', descending: true).limit(20).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CupertinoActivityIndicator(radius: 16)),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        return _buildEmptyState(isDark);
                      }

                      final posts = snapshot.data!.docs;

                      if (posts.isEmpty) {
                        return _buildEmptyState(isDark);
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            ...posts.map((docSnap) {
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
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Não há mais nada para ver',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
            if (_showNewPostsBanner)
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _scrollToTop,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_newPostsUserImages.isNotEmpty) ...[
                          SizedBox(
                            width: 80,
                            height: 32,
                            child: Stack(
                              children: _newPostsUserImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final imageUrl = entry.value;
                                return Positioned(
                                  left: index * 20.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? Color(0xFF000000) : CupertinoColors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(imageUrl),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            '${_newPostsCount} ${_newPostsCount == 1 ? 'nova publicação' : 'novas publicações'}',
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.arrow_up,
                          color: CupertinoColors.systemBlue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.only(
          topLeft: title == 'Mensagens' ? Radius.circular(25) : Radius.circular(1),
          bottomLeft: title == 'Mensagens' ? Radius.circular(25) : Radius.circular(1),
          topRight: title == 'Grupos' ? Radius.circular(25) : Radius.circular(1),
          bottomRight: title == 'Grupos' ? Radius.circular(25) : Radius.circular(1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
        ],
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
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}