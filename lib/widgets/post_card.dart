import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'dart:ui';
import 'app_ui_components.dart';
import 'post_card_screens.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final bool isDark;
  final String currentUserId;

  const PostCard({
    required this.post,
    required this.postId,
    required this.isDark,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    final likedBy = widget.post['likedBy'] as List<dynamic>? ?? [];
    _isLiked = likedBy.contains(widget.currentUserId);
    _likesCount = widget.post['likes'] ?? 0;
  }

  Future<void> _toggleLike() async {
    final newLiked = !_isLiked;
    setState(() {
      _isLiked = newLiked;
      _likesCount += newLiked ? 1 : -1;
    });

    try {
      final postRef = FirebaseFirestore.instance.collection('publicacoes').doc(widget.postId);
      await postRef.update({
        'likes': FieldValue.increment(newLiked ? 1 : -1),
        'likedBy': newLiked 
          ? FieldValue.arrayUnion([widget.currentUserId])
          : FieldValue.arrayRemove([widget.currentUserId]),
      });
    } catch (e) {
      setState(() {
        _isLiked = !newLiked;
        _likesCount += newLiked ? -1 : 1;
      });
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        postId: widget.postId,
        isDark: widget.isDark,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullScreenImageViewer(
          imageUrl: widget.post['image'],
          isDark: widget.isDark,
        ),
      ),
    );
  }

  void _showUserProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: widget.post['userId'],
          isDark: widget.isDark,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _showFullDescription() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => FullDescriptionScreen(
          content: widget.post['content'] ?? '',
          userName: widget.post['userName'] ?? 'Usuário',
          isDark: widget.isDark,
        ),
      ),
    );
  }

  void _showMoreOptions() {
    AppBottomSheet.show(
      context,
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Opções',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 20),
            if (widget.currentUserId == widget.post['userId'])
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Excluir Publicação',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.flag,
                color: Colors.red,
              ),
              title: const Text(
                'Reportar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportPost();
              },
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              text: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    AppDialogs.showConfirmation(
      context,
      'Excluir Publicação',
      'Esta ação não pode ser desfeita.',
      onConfirm: () async {
        await FirebaseFirestore.instance
            .collection('publicacoes')
            .doc(widget.postId)
            .delete();
      },
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
  }

  void _reportPost() {
    AppDialogs.showConfirmation(
      context,
      'Reportar',
      'Deseja reportar esta publicação?',
      onConfirm: () async {
        await FirebaseFirestore.instance.collection('reports').add({
          'postId': widget.postId,
          'reportedBy': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          AppDialogs.showSuccess(
            context,
            'Reportado',
            'Publicação reportada com sucesso.',
          );
        }
      },
      confirmText: 'Reportar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
      return timeago.format(timestamp.toDate(), locale: 'pt_BR');
    } catch (e) {
      return 'Agora';
    }
  }

  Widget _buildImage() {
    final imageData = widget.post['image'];
    if (imageData == null || imageData.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onDoubleTap: _toggleLike,
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          imageData.startsWith('data:image')
              ? Image.memory(
                  base64Decode(imageData.split(',')[1]),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImageError(),
                )
              : Image.network(
                  imageData,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImageError(),
                ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 400,
      color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Center(
        child: Icon(
          Icons.image,
          size: 60,
          color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final content = widget.post['content'] ?? '';
    if (content.isEmpty) return const SizedBox.shrink();

    final shouldTruncate = content.length > 100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${widget.post['userName'] ?? 'Usuário'} ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
            TextSpan(
              text: shouldTruncate ? '${content.substring(0, 100)}... ' : content,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
            if (shouldTruncate)
              WidgetSpan(
                child: GestureDetector(
                  onTap: _showFullDescription,
                  child: const Text(
                    'ver mais',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.darkBackground : Colors.white;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.5,
            color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showUserProfile,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    backgroundImage: widget.post['userProfileImage'] != null &&
                            widget.post['userProfileImage'].isNotEmpty
                        ? NetworkImage(widget.post['userProfileImage'])
                        : null,
                    child: widget.post['userProfileImage'] == null ||
                            widget.post['userProfileImage'].isEmpty
                        ? Text(
                            (widget.post['userName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _showUserProfile,
                    child: Text(
                      widget.post['userName'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: Icon(
                    Icons.more_vert,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          if (widget.post['image'] != null && widget.post['image'].isNotEmpty)
            _buildImage(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked 
                        ? Colors.red 
                        : (widget.isDark ? Colors.white : Colors.black),
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                ),
                const SizedBox(width: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: widget.isDark ? Colors.white : Colors.black,
                    size: 26,
                  ),
                  onPressed: _showCommentsSheet,
                ),
                const SizedBox(width: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    Icons.send,
                    color: widget.isDark ? Colors.white : Colors.black,
                    size: 26,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (_likesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _likesCount == 1 ? '1 curtida' : '$_likesCount curtidas',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          _buildDescription(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('publicacoes')
                .doc(widget.postId)
                .collection('comentarios')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: GestureDetector(
                  onTap: _showCommentsSheet,
                  child: Text(
                    count == 1 ? 'Ver 1 comentário' : 'Ver todos os $count comentários',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              _getTimeAgo(widget.post['timestamp']).toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ],
      ),
    );
  }
}