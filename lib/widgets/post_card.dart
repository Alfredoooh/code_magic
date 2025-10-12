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
              child: Text('Excluir Publicação'),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
          CupertinoActionSheetAction(
            child: Text('Reportar'),
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
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['userName'] ?? 'Usuário',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      Text(
                        _getTimeAgo(widget.post['timestamp']),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    color: CupertinoColors.systemGrey,
                  ),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
          ),
          if (widget.post['title'] != null && widget.post['title'].isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
          if (widget.post['title'] != null && widget.post['title'].isNotEmpty)
            SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.post['content'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: widget.isDark ? CupertinoColors.white.withOpacity(0.85) : CupertinoColors.black,
                height: 1.4,
              ),
            ),
          ),
          if (widget.post['image'] != null && widget.post['image'].isNotEmpty) ...[
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post['image'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: CupertinoColors.systemGrey5,
                    child: Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        size: 60,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: _isLiked ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                        size: 24,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '$_likesCount',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  onPressed: _toggleLike,
                ),
                SizedBox(width: 20),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble,
                        color: CupertinoColors.systemGrey,
                        size: 24,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${widget.post['comments'] ?? 0}',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  onPressed: _showCommentsSheet,
                ),
                Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  child: Icon(
                    CupertinoIcons.square_arrow_up,
                    color: CupertinoColors.systemGrey,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Comentários',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          Divider(),
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
                          CupertinoIcons.chat_bubble_2,
                          size: 60,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum comentário ainda',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a comentar!',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFFF444F),
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Usuário',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            comment['content'] ?? '',
                            style: TextStyle(
                              color: widget.isDark ? CupertinoColors.white.withOpacity(0.85) : CupertinoColors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.systemGrey.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _commentController,
                      placeholder: 'Adicione um comentário...',
                      style: TextStyle(
                        color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.all(12),
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(20),
                    onPressed: _isSubmitting ? null : _submitComment,
                    child: _isSubmitting
                        ? CupertinoActivityIndicator(radius: 10)
                        : Icon(CupertinoIcons.paperplane_fill, size: 20),
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