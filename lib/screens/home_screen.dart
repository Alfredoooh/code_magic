import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

import '../services/language_service.dart';
import 'admin_panel_screen.dart';
import 'news_detail_screen.dart';
import 'create_post_screen.dart';
import 'user_drawer.dart';
import '../models/news_article.dart';
import '../widgets/wallet_card.dart';
import '../widgets/post_card.dart';

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
  Map<int, Color> _newsColors = {};
  String _cardStyle = 'modern';
  int _messageCount = 0;
  int _groupCount = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _safeSetUserOnline(true);
    _loadNews();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when inherited theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
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
    } catch (e) {
      // Falha ao carregar stats — manter valores anteriores
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _loadingNews = true;
    });

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

        // Extrair cores em background (não bloqueante)
        unawaited(_extractColors());
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

  Future<void> _extractColors() async {
    for (int i = 0; i < _newsArticles.length; i++) {
      final imageUrl = _newsArticles[i].imageUrl;
      if (imageUrl.isNotEmpty) {
        try {
          final paletteGenerator = await PaletteGenerator.fromImageProvider(
            NetworkImage(imageUrl),
            maximumColorCount: 10,
          );

          if (mounted) {
            setState(() {
              _newsColors[i] = paletteGenerator.dominantColor?.color ??
                  paletteGenerator.vibrantColor?.color ??
                  Color(0xFFFF444F);
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _newsColors[i] = Color(0xFFFF444F);
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _newsColors[i] = Color(0xFFFF444F);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _safeSetUserOnline(false);
    super.dispose();
  }

  // wrapper with try/catch para evitar que erros de rede causem crashes
  Future<void> _safeSetUserOnline(bool isOnline) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isOnline': isOnline});
      }
    } catch (e) {
      // Falha a atualizar estado online — ignorar silênciosamente
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // cancelar subscrição anterior se existir
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
      }, onError: (err) {
        // ignorar erros de snapshot
      });
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
            } catch (e) {
              // ignorar erro de escrita
            }
          }
        },
        onCardStyleChanged: (style) {
          setState(() => _cardStyle = style);
        },
      ),
    );
  }

  void _handleCreatePost() {
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
                // Navegar para tela de upgrade — implementar conforme app
              },
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CreatePostScreen(
          userData: _userData ?? {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar Theme da app (não o brilho do sistema) para obedecer troca de tema do utilizador
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        middle: Text(
          'K Paga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        // removido o ícone de pesquisa conforme pedido
        trailing: CupertinoButton(
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
                    (_userData?['username'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          onPressed: _showUserDrawer,
        ),
        border: null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    await _loadUserData();
                    await _loadNews();
                    await _loadStats();
                  },
                ),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      WalletCard(
                        userData: _userData,
                        cardStyle: _cardStyle,
                        onStyleChanged: (style) {
                          setState(() => _cardStyle = style);
                        },
                      ),
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
                            ? Center(
                                child: CupertinoActivityIndicator(radius: 16),
                              )
                            : Container(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: _newsArticles.length,
                                  itemBuilder: (context, index) {
                                    final article = _newsArticles[index];
                                    final cardColor = _newsColors[index] ?? Color(0xFFFF444F);

                                    return _buildNewsCard(article, cardColor, index);
                                  },
                                ),
                              ),
                      ],
                      SizedBox(height: 32),
                      Text(
                        'Publicações Recentes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                    ]),
                  ),
                ),

                // Posts: usar StreamBuilder que retorna um Column com PostCards (evita ListView aninhado)
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

                      // Construir Column de PostCards (cada PostCard é responsável pelo seu próprio tamanho)
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

                // espaço inferior para FAB
                SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),

            // FAB para criar publicação — respeita safe area
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 16,
              child: GestureDetector(
                onTap: _handleCreatePost,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF444F).withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.plus,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, Color cardColor, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => NewsDetailScreen(
              article: article,
              allArticles: _newsArticles,
              currentIndex: index,
            ),
          ),
        );
      },
      child: Container(
        width: 320,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cardColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (article.imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: cardColor.withOpacity(0.2),
                      child: Icon(
                        CupertinoIcons.photo,
                        color: cardColor,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.source.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// small helper para unawaited future sem avisos
void unawaited(Future? f) {}