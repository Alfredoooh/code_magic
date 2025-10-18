import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'dart:ui';
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
  _PostCardState createState() => _PostCardState();
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CommentsSheet(
        postId: widget.postId,
        isDark: widget.isDark,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      CupertinoPageRoute(
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
      CupertinoPageRoute(
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
      CupertinoPageRoute(
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (widget.currentUserId == widget.post['userId'])
            CupertinoActionSheetAction(
              child: Text('Excluir Publicação'),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          CupertinoActionSheetAction(
            child: Text('Reportar'),
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _reportPost();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Excluir Publicação'),
        content: Text('Esta ação não pode ser desfeita.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Excluir'),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('publicacoes').doc(widget.postId).delete();
            },
          ),
        ],
      ),
    );
  }

  void _reportPost() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Reportar'),
        content: Text('Deseja reportar esta publicação?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Reportar'),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('reports').add({
                'postId': widget.postId,
                'reportedBy': widget.currentUserId,
                'timestamp': FieldValue.serverTimestamp(),
              });
            },
          ),
        ],
      ),
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
    if (imageData == null || imageData.isEmpty) return SizedBox.shrink();

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
      color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 60,
          color: widget.isDark ? Color(0xFF3A3A3A) : Color(0xFFDBDBDB),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final content = widget.post['content'] ?? '';
    if (content.isEmpty) return SizedBox.shrink();

    final shouldTruncate = content.length > 100;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${widget.post['userName'] ?? 'Usuário'} ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            TextSpan(
              text: shouldTruncate ? '${content.substring(0, 100)}... ' : content,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            if (shouldTruncate)
              WidgetSpan(
                child: GestureDetector(
                  onTap: _showFullDescription,
                  child: Text(
                    'ver mais',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.activeBlue,
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
    final bgColor = widget.isDark ? Color(0xFF000000) : CupertinoColors.white;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.5,
            color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showUserProfile,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFF444F),
                    backgroundImage: widget.post['userProfileImage'] != null &&
                            widget.post['userProfileImage'].isNotEmpty
                        ? NetworkImage(widget.post['userProfileImage'])
                        : null,
                    child: widget.post['userProfileImage'] == null ||
                            widget.post['userProfileImage'].isEmpty
                        ? Text(
                            (widget.post['userName'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _showUserProfile,
                    child: Text(
                      widget.post['userName'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          if (widget.post['image'] != null && widget.post['image'].isNotEmpty)
            _buildImage(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  child: Icon(
                    _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: _isLiked ? CupertinoColors.systemRed : (widget.isDark ? CupertinoColors.white : CupertinoColors.black),
                    size: 26,
                  ),
                  onPressed: _toggleLike,
                ),
                SizedBox(width: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  child: Icon(
                    CupertinoIcons.chat_bubble,
                    color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 26,
                  ),
                  onPressed: _showCommentsSheet,
                ),
                SizedBox(width: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  child: Icon(
                    CupertinoIcons.paperplane,
                    color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 26,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (_likesCount > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _likesCount == 1 ? '1 curtida' : '$_likesCount curtidas',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
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
              if (count == 0) return SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: GestureDetector(
                  onTap: _showCommentsSheet,
                  child: Text(
                    count == 1 ? 'Ver 1 comentário' : 'Ver todos os $count comentários',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E8E),
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              _getTimeAgo(widget.post['timestamp']).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF8E8E8E),
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
          ),
        ],
      ),
    );
  }
}