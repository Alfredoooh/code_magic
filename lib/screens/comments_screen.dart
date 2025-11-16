// lib/screens/comments_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/post_model.dart';
import '../widgets/custom_icons.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final bool isNews;

  const CommentsScreen({
    super.key,
    required this.postId,
    this.isNews = false,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final uid = auth.user?.uid;
    final isPro = auth.userData?['isPro'] ?? false;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final dividerColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comentários',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: dividerColor),
        ),
      ),
      body: Column(
        children: [
          // Lista de comentários
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.isNews ? _getNewsCommentsStream() : _getPostCommentsStream(),
              builder: (context, snapshot) {
                // Estado de erro
                if (snapshot.hasError) {
                  return _buildEmptyState(
                    icon: Icons.error_outline,
                    iconColor: const Color(0xFFFA383E),
                    title: 'Erro ao carregar',
                    subtitle: 'Não foi possível carregar os comentários.\nTente novamente mais tarde.',
                  );
                }

                // Estado de carregamento
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF1877F2),
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Estado vazio
                if (docs.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF1877F2),
                    title: 'Nenhum comentário',
                    subtitle: 'Seja o primeiro a comentar!\nCompartilhe sua opinião sobre esta publicação.',
                  );
                }

                // Lista de comentários
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox.shrink();

                    final comment = Comment.fromFirestore(d);
                    return _buildCommentItem(
                      comment,
                      isDark,
                      textColor,
                      secondaryColor,
                      cardColor,
                    );
                  },
                );
              },
            ),
          ),

          // Área de input
          _buildInputArea(
            context,
            uid,
            isPro,
            isDark,
            cardColor,
            textColor,
            secondaryColor,
            dividerColor,
            auth,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: secondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    bool isDark,
    Color textColor,
    Color secondaryColor,
    Color cardColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatar(comment, isDark, textColor),
          const SizedBox(width: 12),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e tempo
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Texto do comentário
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Comment comment, bool isDark, Color textColor) {
    final hasAvatar = comment.userAvatar != null;

    return CircleAvatar(
      radius: 18,
      backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
      backgroundImage: hasAvatar ? MemoryImage(base64Decode(comment.userAvatar!)) : null,
      child: !hasAvatar
          ? Text(
              comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            )
          : null,
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    String? uid,
    bool isPro,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryColor,
    Color dividerColor,
    AuthProvider auth,
  ) {
    final canComment = uid != null && isPro;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: canComment
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar do usuário
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      backgroundImage: auth.userData?['photoBase64'] != null
                          ? MemoryImage(base64Decode(auth.userData!['photoBase64']))
                          : null,
                      child: auth.userData?['photoBase64'] == null
                          ? Text(
                              auth.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Campo de texto
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !_isSending,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Escreva um comentário...',
                            hintStyle: TextStyle(color: secondaryColor, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão enviar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _ctrl.text.trim().isNotEmpty && !_isSending
                            ? const Color(0xFF1877F2)
                            : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: _ctrl.text.trim().isNotEmpty && !_isSending
                                    ? Colors.white
                                    : secondaryColor,
                              ),
                              onPressed: _ctrl.text.trim().isNotEmpty && !_isSending
                                  ? _sendComment
                                  : null,
                              padding: EdgeInsets.zero,
                            ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      uid == null
                          ? 'Faça login para comentar'
                          : 'Apenas usuários Pro podem comentar',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getPostCommentsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> _getNewsCommentsStream() {
    return FirebaseFirestore.instance
        .collection('news_comments')
        .where('newsId', isEqualTo: widget.postId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> _sendComment() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    final isPro = auth.userData?['isPro'] ?? false;

    if (uid == null || !isPro) {
      if (mounted) {
        _showSnackBar(
          uid == null ? 'Faça login para comentar' : 'Apenas usuários Pro podem comentar',
          isError: true,
        );
      }
      return;
    }

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final now = FieldValue.serverTimestamp();
      final userName = auth.userData?['name'] ?? 'Usuário';
      final userAvatar = auth.userData?['photoBase64'];

      if (widget.isNews) {
        await FirebaseFirestore.instance.collection('news_comments').add({
          'newsId': widget.postId,
          'userId': uid,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': text,
          'timestamp': now,
          'likes': 0,
          'likedBy': [],
        });
      } else {
        final batch = FirebaseFirestore.instance.batch();

        final commentRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc();

        batch.set(commentRef, {
          'postId': widget.postId,
          'userId': uid,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': text,
          'timestamp': now,
          'likes': 0,
          'likedBy': [],
        });

        final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
        batch.update(postRef, {'comments': FieldValue.increment(1)});

        await batch.commit();
      }

      _ctrl.clear();
      _focusNode.unfocus();

      // Scroll para o final
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }

      if (mounted) {
        _showSnackBar('Comentário enviado!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao enviar comentário', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFA383E) : const Color(0xFF42B72A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'agora';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 10) return 'agora';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';

    return '${dt.day}/${dt.month}';
  }
}