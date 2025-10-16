import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _initializeLikeState();
  }

  void _initializeLikeState() {
    final likedBy = widget.post['likedBy'] as List<dynamic>? ?? [];
    setState(() {
      _isLiked = likedBy.contains(widget.currentUserId);
      _likesCount = widget.post['likes'] ?? 0;
    });
  }

  Future<void> _toggleLike() async {
    try {
      final postRef = FirebaseFirestore.instance.collection('publicacoes').doc(widget.postId);
      
      if (_isLiked) {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([widget.currentUserId]),
        });
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([widget.currentUserId]),
        });
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
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

  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (widget.currentUserId == widget.post['userId'])
            CupertinoActionSheetAction(
              child: Text('Excluir Publicação', style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
          CupertinoActionSheetAction(
            child: Text('Reportar', style: TextStyle(color: CupertinoColors.destructiveRed)),
            onPressed: () {
              Navigator.pop(context);
              _reportPost();
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Compartilhar'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Copiar Link'),
            onPressed: () {
              Navigator.pop(context);
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

  Future<void> _deletePost() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Excluir Publicação'),
        content: Text('Tem certeza que deseja excluir esta publicação? Esta ação não pode ser desfeita.'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Excluir'),
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('publicacoes')
                    .doc(widget.postId)
                    .delete();
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                print('Error deleting post: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportPost() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Reportar Publicação'),
        content: Text('Deseja reportar esta publicação como conteúdo inapropriado?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Reportar'),
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'postId': widget.postId,
                  'reportedBy': widget.currentUserId,
                  'timestamp': FieldValue.serverTimestamp(),
                  'reason': 'inappropriate_content',
                });
                Navigator.pop(context);
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text('Obrigado'),
                    content: Text('Sua denúncia foi enviada e será analisada.'),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                print('Error reporting post: $e');
              }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDark ? Color(0xFF262626) : Color(0xFFDBDBDB),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFD1D1D), Color(0xFFF77737), Color(0xFFFFDC80)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
                      border: Border.all(
                        color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFFF444F),
                      backgroundImage: widget.post['userProfileImage'] != null &&
                              widget.post['userProfileImage'].isNotEmpty
                          ? NetworkImage(widget.post['userProfileImage'])
                          : null,
                      child: widget.post['userProfileImage'] == null ||
                              widget.post['userProfileImage'].isEmpty
                          ? Text(
                              (widget.post['userName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['userName'] ?? 'Usuário',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      if (widget.post['location'] != null && widget.post['location'].isNotEmpty)
                        Text(
                          widget.post['location'],
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? Color(0xFFA8A8A8) : Color(0xFF262626),
                          ),
                        ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 20,
                  ),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),

          // Image
          if (widget.post['image'] != null && widget.post['image'].isNotEmpty)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: Image.network(
                widget.post['image'],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 400,
                  color: widget.isDark ? Color(0xFF262626) : Color(0xFFFAFAFA),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 60,
                      color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFFDBDBDB),
                    ),
                  ),
                ),
              ),
            ),

          // Actions
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
                Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 24,
                  child: Icon(
                    _isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                    color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 26,
                  ),
                  onPressed: () {
                    setState(() => _isBookmarked = !_isBookmarked);
                  },
                ),
              ],
            ),
          ),

          // Likes count
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

          // Content/Caption
          if (widget.post['content'] != null && widget.post['content'].isNotEmpty)
            Padding(
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
                      text: widget.post['content'],
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // View comments
          if (widget.post['comments'] != null && widget.post['comments'] > 0)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: GestureDetector(
                onTap: _showCommentsSheet,
                child: Text(
                  widget.post['comments'] == 1
                      ? 'Ver 1 comentário'
                      : 'Ver todos os ${widget.post['comments']} comentários',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                  ),
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              _getTimeAgo(widget.post['timestamp']).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  final bool isDark;
  final String currentUserId;

  const CommentsSheet({
    required this.postId,
    required this.isDark,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('publicacoes')
          .doc(widget.postId)
          .collection('comentarios')
          .add({
        'userId': widget.currentUserId,
        'content': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('publicacoes')
          .doc(widget.postId)
          .update({
        'comments': FieldValue.increment(1),
      });

      _commentController.clear();
    } catch (e) {
      print('Error submitting comment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle bar
          SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Color(0xFF3A3A3A) : Color(0xFFDBDBDB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 8),
          
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark ? Color(0xFF262626) : Color(0xFFDBDBDB),
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: Text(
                'Comentários',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicacoes')
                  .doc(widget.postId)
                  .collection('comentarios')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CupertinoActivityIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble,
                          size: 64,
                          color: widget.isDark ? Color(0xFF3A3A3A) : Color(0xFFDBDBDB),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum comentário ainda',
                          style: TextStyle(
                            color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Inicie a conversa.',
                          style: TextStyle(
                            color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFFF444F),
                            child: Text(
                              'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Usuário ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: comment['content'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _getTimeAgo(comment['timestamp']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Responder',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 24,
                            child: Icon(
                              CupertinoIcons.heart,
                              size: 12,
                              color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
              border: Border(
                top: BorderSide(
                  color: widget.isDark ? Color(0xFF262626) : Color(0xFFDBDBDB),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFFF444F),
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _commentController,
                      placeholder: 'Adicione um comentário...',
                      placeholderStyle: TextStyle(
                        color: widget.isDark ? Color(0xFF8E8E8E) : Color(0xFF8E8E8E),
                        fontSize: 14,
                      ),
                      style: TextStyle(
                        color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      padding: EdgeInsets.zero,
                      maxLines: null,
                    ),
                  ),
                  if (_commentController.text.isNotEmpty || _isSubmitting)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 30,
                      onPressed: _isSubmitting ? null : _submitComment,
                      child: _isSubmitting
                          ? CupertinoActivityIndicator(radius: 8)
                          : Text(
                              'Publicar',
                              style: TextStyle(
                                color: Color(0xFF0095F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}