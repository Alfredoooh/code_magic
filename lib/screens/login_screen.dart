// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_ui_components.dart';
import 'home_widgets.dart';
import 'home_crypto_section.dart' as crypto_section;
import 'home_news_section.dart';
import 'home_posts_section.dart';
import 'home_stats_section.dart';
import 'home_action_button.dart';
import 'user_drawer.dart';
import 'search_screen.dart' as search_posts;
import '../models/news_article.dart';
import '../widgets/wallet_card.dart';
import 'crypto_list_screen.dart';
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

  List<QueryDocumentSnapshot> _posts = [];
  bool _loadingMorePosts = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  void _initializeScreen() {
    _loadUserData();
    _safeSetUserOnline(true);
    _loadAllData();
    _setupTimers();
    _setupScrollListeners();
    _loadInitialPosts();
    _listenToNewPostsNotification();
  }

  void _loadAllData() {
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
  }

  void _setupTimers() {
    _cryptoTimer = Timer.periodic(Duration(seconds: 10), (_) {
      HomeScreenHelper.loadCryptoData((data, loading) {
        if (mounted) setState(() {
          _cryptoData = data;
          _loadingCrypto = loading;
        });
      });
    });
  }

  void _setupScrollListeners() {
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
        if (latestPostId != _lastSeenPostId && 
            _scrollController.hasClients && 
            _scrollController.offset > 100) {
          setState(() {
            _newPostsCount++;
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
                ]);
                _loadAllData();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(isDark, username, profileImage),
                  _buildMainContent(isDark),
                  _buildPostsHeader(isDark),
                  _buildPostsList(isDark),
                  SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
            if (_showNewPostsBanner)
              _buildNewPostsBanner(isDark),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark, String username, String? profileImage) {
    return SliverAppBar(
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
                builder: (context) => search_posts.SearchScreen(),
                fullscreenDialog: true,
              ),
            );
          },
        ),
        SizedBox(width: 8),
        GestureDetector(
          onTap: _showUserDrawer,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? Text(
                      username[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  SliverPadding _buildMainContent(bool isDark) {
    return SliverPadding(
      padding: EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          WalletCard(
            userData: _userData,
            cardStyle: _cardStyle,
            showCustomizeButton: false,
          ),
          SizedBox(height: 16),
          HomeActionButton(
            userData: _userData,
            onCheckToken: _checkAndDecrementToken,
            isDark: isDark,
          ),
          SizedBox(height: 24),
          HomeStatsSection(
            messageCount: _messageCount,
            groupCount: _groupCount,
            isDark: isDark,
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
            HomeNewsSection(
              newsArticles: _newsArticles,
              loadingNews: _loadingNews,
              isDark: isDark,
              pageController: _newsPageController,
              currentPage: _currentNewsPage,
              onNewsClick: _checkAndDecrementToken,
            ),
          ],
        ]),
      ),
    );
  }

  SliverPersistentHeader _buildPostsHeader(bool isDark) {
    return SliverPersistentHeader(
      pinned: false,
      floating: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 60,
        maxHeight: 60,
        child: Container(
          color: isDark 
              ? AppColors.darkBackground.withOpacity(0.9) 
              : AppColors.lightBackground.withOpacity(0.9),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AppSectionTitle(
            text: 'Sheets',
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  SliverList _buildPostsList(bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return HomePostsSection(
            posts: _posts,
            index: index,
            loadingMorePosts: _loadingMorePosts,
            hasMorePosts: _hasMorePosts,
            isDark: isDark,
          );
        },
        childCount: _posts.length + 1,
      ),
    );
  }

  Widget _buildNewPostsBanner(bool isDark) {
    return Positioned(
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
              Expanded(
                child: Text(
                  '$_newPostsCount ${_newPostsCount == 1 ? 'nova publicação' : 'novas publicações'}',
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