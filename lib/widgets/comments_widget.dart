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
  bool _isSending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
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
        shape: Border(
          bottom: BorderSide(color: dividerColor, width: 0.5),
        ),
        title: Row(
          children: [
            SvgPicture.string(
              CustomIcons.commentOutlined,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            Text(
              'Comentários',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de comentários
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.isNews
                  ? _getNewsCommentsStream()
                  : _getPostCommentsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            CustomIcons.errorOutlined,
                            width: 64,
                            height: 64,
                            colorFilter: ColorFilter.mode(
                              const Color(0xFFFA383E).withOpacity(0.7),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar comentários',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF1877F2),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Carregando comentários...',
                          style: TextStyle(
                            fontSize: 16,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.string(
                                CustomIcons.commentOutlined,
                                width: 48,
                                height: 48,
                                colorFilter: ColorFilter.mode(
                                  const Color(0xFF1877F2).withOpacity(0.7),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Nenhum comentário ainda',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Seja o primeiro a comentar!\nCompartilhe sua opinião.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data() as Map<String, dynamic>?;

                    if (data == null) return const SizedBox.shrink();

                    final comment = Comment.fromFirestore(d);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: dividerColor.withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark 
                                  ? const Color(0xFF3A3B3C) 
                                  : const Color(0xFFE4E6EB),
                              backgroundImage: comment.userAvatar != null
                                  ? MemoryImage(base64Decode(comment.userAvatar!))
                                  : null,
                              child: comment.userAvatar == null
                                  ? Text(
                                      comment.userName.isNotEmpty
                                          ? comment.userName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment.userName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _formatTimestamp(comment.timestamp),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Comment text
                                  Text(
                                    comment.content,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      height: 1.5,
                                    ),
                                  ),

                                  // Actions
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          // TODO: Implementar like
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              SvgPicture.string(
                                                CustomIcons.thumbUpOutlined,
                                                width: 20,
                                                height: 20,
                                                colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Curtir',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: secondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      InkWell(
                                        onTap: () {
                                          // TODO: Implementar responder
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            'Responder',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input de comentário ou mensagem de restrição
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                top: BorderSide(color: dividerColor, width: 0.5),
              ),
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
                padding: const EdgeInsets.all(16),
                child: (uid != null && isPro)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark 
                                ? const Color(0xFF3A3B3C) 
                                : const Color(0xFFE4E6EB),
                            backgroundImage: auth.userData?['photoBase64'] != null
                                ? MemoryImage(base64Decode(auth.userData!['photoBase64']))
                                : null,
                            child: auth.userData?['photoBase64'] == null
                                ? Text(
                                    auth.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Input field
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 50,
                                maxHeight: 150,
                              ),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? const Color(0xFF3A3B3C) 
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _ctrl,
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Escreva um comentário...',
                                  hintStyle: TextStyle(
                                    color: secondaryColor,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                                enabled: !_isSending,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Send button
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_ctrl.text.trim().isNotEmpty && !_isSending)
                                  ? const Color(0xFF1877F2)
                                  : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
                              shape: BoxShape.circle,
                            ),
                            child: _isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : IconButton(
                                    icon: SvgPicture.string(
                                      CustomIcons.sendRounded,
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        (_ctrl.text.trim().isNotEmpty && !_isSending)
                                            ? Colors.white
                                            : secondaryColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    onPressed: (_ctrl.text.trim().isNotEmpty && !_isSending)
                                        ? _sendComment
                                        : null,
                                    padding: EdgeInsets.zero,
                                  ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          uid == null
                              ? 'Faça login para comentar'
                              : 'Apenas usuários Pro podem comentar',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uid == null ? 'Você precisa estar logado para comentar' : 'Apenas usuários Pro podem comentar'),
            backgroundColor: const Color(0xFFFA383E),
          ),
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
        // Comentário em notícia
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
        // Comentário em post normal
        final batch = FirebaseFirestore.instance.batch();

        // Adiciona o comentário
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

        // Incrementa contador de comentários
        final postRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId);

        batch.update(postRef, {
          'comments': FieldValue.increment(1),
        });

        await batch.commit();
      }

      _ctrl.clear();
      _focusNode.unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comentário enviado com sucesso!'),
            backgroundColor: const Color(0xFF42B72A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar comentário: ${e.toString()}'),
            backgroundColor: const Color(0xFFFA383E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}