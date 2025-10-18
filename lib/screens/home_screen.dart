// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_ui_components.dart';
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
  String? _lastSeenPostId;
  bool _hasShownWelcomeBack = false;

  // Infinite scrolling
  List<QueryDocumentSnapshot> _posts = [];
  bool _loadingMorePosts = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;

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

    _loadInitialPosts();
    _listenToNewPostsNotification();
  }

  Future<void> _loadInitialPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('publicacoes')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _posts = snapshot.docs;
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMorePosts = snapshot.docs.length == 10;
        });
      }

      if (snapshot.docs.isNotEmpty) {
        _lastSeenPostId = snapshot.docs.first.id;
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMorePosts || !_hasMorePosts || _lastDocument == null) return;

    setState(() => _loadingMorePosts = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('publicacoes')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _posts.addAll(snapshot.docs);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
          _hasMorePosts = snapshot.docs.length == 10;
          _loadingMorePosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMorePosts = false);
      }
    }
  }

  void _listenToNewPostsNotification() {
    FirebaseFirestore.instance
        .collection('publicacoes')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (_lastSeenPostId == null && snapshot.docs.isNotEmpty) {
        _lastSeenPostId = snapshot.docs.first.id;
        return;
      }

      if (snapshot.docs.isNotEmpty) {
        final latestPostId = snapshot.docs.first.id;
        if (latestPostId != _lastSeenPostId && _scrollController.hasClients && _scrollController.offset > 100) {
          setState(() {
            _newPostsCount = (_newPostsCount + 1);
            _showNewPostsBanner = true;
          });
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

    _loadInitialPosts();

    setState(() {
      _showNewPostsBanner = false;
      _newPostsCount = 0;
      _newPostsUserImages = [];
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (offset >= maxScroll - 200 && !_loadingMorePosts && _hasMorePosts) {
        _loadMorePosts();
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
        AppDialogs.showSuccess(
          context,
          '🎉',
          'Bem-vindo de volta, $username!',
        );
      }
    });
  }

  void _showUserDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

    AppDialogs.showConfirmation(
      context,
      'Olá, $username!',
      'Os seus tokens estão esgotados. Adquira saldo para obter mais tokens e continuar usando todos os recursos do aplicativo.',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlansScreen(),
            fullscreenDialog: true,
          ),
        );
      },
      confirmText: 'Continuar',
      cancelText: 'Cancelar',
    );
  }

  Future<void> _handleCreatePost() async {
    final isPro = _userData?['pro'] == true;

    if (!isPro) {
      AppDialogs.showConfirmation(
        context,
        'Recursos PRO',
        'Apenas usuários PRO podem criar publicações. Atualize sua conta para desbloquear este recurso.',
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlansScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        confirmText: 'Atualizar para PRO',
        cancelText: 'Entendi',
      );
      return;
    }

    final canProceed = await _checkAndDecrementToken('create_post');
    if (!canProceed) return;

    Navigator.push(
      context,
      MaterialPageRoute(
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
      MaterialPageRoute(
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

    AppBottomSheet.show(
      context,
      height: 350,
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildModalOption(
            icon: Icons.arrow_upward_rounded,
            label: 'Enviar',
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          _buildModalOption(
            icon: Icons.add_circle,
            label: 'Criar Publicação',
            isDark: isDark,
            onPressed: () {
              Navigator.pop(context);
              _handleCreatePost();
            },
          ),
          _buildModalOption(
            icon: Icons.arrow_downward_rounded,
            label: 'Receber',
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          _buildModalOption(
            icon: Icons.more_horiz,
            label: 'Mais Opções',
            isDark: isDark,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoreOptionsScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage(String? profileImage, String username) {
    if (profileImage == null || profileImage.isEmpty) return null;

    if (profileImage.startsWith('data:image')) {
      try {
        final base64String = profileImage.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    }

    return NetworkImage(profileImage);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = _userData?['username'] ?? 'Usuário';
    final profileImage = _userData?['profile_image'] as String?;

    return WillPopScope(
      onWillPop: () async {
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _loadUserData(),
                  _loadInitialPosts(),
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
              child: CustomScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    elevation: 0,
                    pinned: false,
                    floating: true,
                    expandedHeight: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                      title: Text(
                        username,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: _showUserDrawer,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _getProfileImage(profileImage, username),
                            child: _getProfileImage(profileImage, username) == null
                                ? Text(
                                    username[0].toUpperCase(),
                                    style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
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
                                icon: Icons.chat_bubble,
                                title: 'Mensagens',
                                value: '$_messageCount',
                                color: Colors.blue,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.group,
                                title: 'Grupos',
                                value: '$_groupCount',
                                color: Colors.green,
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
                              MaterialPageRoute(
                                builder: (context) => CryptoListScreen(),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                        if (_showNews) ...[
                          SizedBox(height: 32),
                          AppSectionTitle(
                            text: 'Últimas Notícias',
                            fontSize: 24,
                          ),
                          SizedBox(height: 16),
                          _loadingNews
                              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                    pinned: false,
                    floating: true,
                    delegate: _SliverAppBarDelegate(
                      minHeight: 60,
                      maxHeight: 60,
                      child: Container(
                        color: isDark ? AppColors.darkBackground.withOpacity(0.9) : AppColors.lightBackground.withOpacity(0.9),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: AppSectionTitle(
                          text: 'Sheets',
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _posts.length) {
                          final post = _posts[index].data() as Map<String, dynamic>;
                          final postId = _posts[index].id;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0),
                            child: PostCard(
                              post: post,
                              postId: postId,
                              isDark: isDark,
                              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          );
                        } else if (_loadingMorePosts) {
                          return Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        } else if (!_hasMorePosts) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'Não há mais publicações',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                      childCount: _posts.length + 1,
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
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
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
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
                                        color: isDark ? AppColors.darkBackground : Colors.white,
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
                              color: Colors.blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_upward,
                          color: Colors.blue,
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

  Widget _buildActionButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showOptionsBottomSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Começar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
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
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
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