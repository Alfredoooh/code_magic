// lib/screens/user_detail_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/custom_icons.dart';
import 'chat_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _userData;
  List<Post> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _postsCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _hasError = false;
      });

      // Buscar dados do usuário
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Usuário não encontrado';
          _loading = false;
        });
        return;
      }

      // Buscar posts do usuário
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      setState(() {
        _userData = userDoc.data();
        _posts = postsSnap.docs.map((d) => Post.fromFirestore(d)).toList();
        _postsCount = postsSnap.docs.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro ao carregar perfil: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _navigateToChat() {
    if (_userData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientId: widget.userId,
          recipientName: _userData!['name'] ?? 'Usuário',
          recipientPhotoURL: _userData!['photoURL'],
          isOnline: _userData!['isOnline'] ?? false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    final isOwnProfile = currentUserId == widget.userId;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final subtitleColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final borderColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: SvgIcon(svgString: CustomIcons.arrowBack, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 0.5),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: SvgIcon(svgString: CustomIcons.arrowBack, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderColor, height: 0.5),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: subtitleColor,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Erro ao carregar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(svgString: CustomIcons.arrowBack, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _userData?['name'] ?? 'Usuário',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!isOwnProfile)
            IconButton(
              icon: SvgIcon(svgString: CustomIcons.inbox, color: textColor),
              onPressed: _navigateToChat,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 0.5),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1877F2),
        child: ListView(
          children: [
            // Header do perfil
            Container(
              color: cardColor,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1877F2),
                        width: 3,
                      ),
                    ),
                    child: _buildAvatar(),
                  ),
                  const SizedBox(height: 16),

                  // Nome
                  Text(
                    _userData?['name'] ?? 'Usuário',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Nickname (se existir)
                  if (_userData?['nickname'] != null && _userData!['nickname'].toString().isNotEmpty)
                    Text(
                      '@${_userData!['nickname']}',
                      style: TextStyle(
                        fontSize: 15,
                        color: subtitleColor,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _userData?['email'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                    ),
                  ),

                  // Bio (se existir)
                  if (_userData?['bio'] != null && _userData!['bio'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _userData!['bio'],
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Badge Pro/Premium
                  if (_userData?['isPro'] == true || _userData?['isPremium'] == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1877F2).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFF1877F2),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userData?['isPremium'] == true ? 'Premium' : 'Pro',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1877F2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Estatísticas
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Publicações', _postsCount, textColor, subtitleColor),
                        Container(
                          width: 1,
                          height: 40,
                          color: borderColor,
                        ),
                        _buildStatColumn('Seguidores', _userData?['followersCount'] ?? 0, textColor, subtitleColor),
                        Container(
                          width: 1,
                          height: 40,
                          color: borderColor,
                        ),
                        _buildStatColumn('Seguindo', _userData?['followingCount'] ?? 0, textColor, subtitleColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botões de ação
                  if (!isOwnProfile)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _navigateToChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Mensagem',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implementar seguir
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Funcionalidade em desenvolvimento'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Seguir',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Divisor
            Container(height: 8, color: bgColor),

            // Seção de publicações
            Container(
              color: cardColor,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Publicações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),

            // Lista de posts
            if (_posts.isEmpty)
              Container(
                color: cardColor,
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      SvgIcon(
                        svgString: CustomIcons.inbox,
                        size: 64,
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma publicação ainda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._posts.map((post) => PostCard(post: post)).toList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Primeiro tenta photoBase64
    if (_userData?['photoBase64'] != null && _userData!['photoBase64'].toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(
            base64Decode(_userData!['photoBase64']),
          ),
        );
      } catch (e) {
        debugPrint('Erro ao decodificar photoBase64: $e');
      }
    }

    // Depois tenta photoURL
    if (_userData?['photoURL'] != null && _userData!['photoURL'].toString().isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_userData!['photoURL']),
      );
    }

    // Fallback: primeira letra do nome
    return CircleAvatar(
      radius: 50,
      backgroundColor: const Color(0xFF1877F2),
      child: Text(
        (_userData?['name'] ?? 'U')
            .toString()
            .substring(0, 1)
            .toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color textColor, Color subtitleColor) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }
}