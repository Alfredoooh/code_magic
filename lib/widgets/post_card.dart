import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'dart:ui';

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
  bool _showFullDescription = false;

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
          // Blur effect overlay
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

class FullDescriptionScreen extends StatelessWidget {
  final String content;
  final String userName;
  final bool isDark;

  const FullDescriptionScreen({
    required this.content,
    required this.userName,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$userName ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                TextSpan(
                  text: content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final bool isDark;
  final String currentUserId;

  const UserProfileScreen({
    required this.userId,
    required this.isDark,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  List<QueryDocumentSnapshot> _userPosts = [];
  int _postsCount = 0;
  int _totalLikes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      
      final postsQuery = await FirebaseFirestore.instance
          .collection('publicacoes')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();

      int totalLikes = 0;
      for (var post in postsQuery.docs) {
        totalLikes += (post.data()['likes'] ?? 0) as int;
      }

      setState(() {
        _userData = userDoc.data();
        _userPosts = postsQuery.docs;
        _postsCount = postsQuery.docs.length;
        _totalLikes = totalLikes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        backgroundColor: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final username = _userData?['username'] ?? 'Usuário';
    final profileImage = _userData?['profile_image'] as String?;
    final coverImage = _userData?['cover_image'] as String?;
    final isPro = _userData?['pro'] == true;
    final isAdmin = _userData?['admin'] == true;

    return CupertinoPageScaffold(
      backgroundColor: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: widget.isDark ? Color(0xFF000000).withOpacity(0.9) : CupertinoColors.white.withOpacity(0.9),
            border: null,
            largeTitle: Text(username),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.back, color: widget.isDark ? CupertinoColors.white : CupertinoColors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Cover Image
                if (coverImage != null && coverImage.isNotEmpty)
                  Container(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
                  ),
                
                Transform.translate(
                  offset: Offset(0, -40),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark ? Color(0xFF000000) : CupertinoColors.white,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFFF444F),
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          if (isPro) ...[
                            SizedBox(width: 6),
                            Icon(CupertinoIcons.checkmark_seal_fill, color: CupertinoColors.activeBlue, size: 18),
                          ],
                          if (isAdmin) ...[
                            SizedBox(width: 6),
                            Icon(CupertinoIcons.shield_fill, color: CupertinoColors.systemRed, size: 18),
                          ],
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Publicações', _postsCount.toString()),
                          _buildStatColumn('Curtidas', _totalLikes.toString()),
                          _buildStatColumn('Status', isPro ? 'PRO' : 'Free'),
                        ],
                      ),
                      SizedBox(height: 24),
                      Container(
                        height: 1,
                        color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _userPosts[index].data() as Map<String, dynamic>;
                  final postId = _userPosts[index].id;
                  final imageUrl = post['image'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => PostDetailScreen(
                            postId: postId,
                            post: post,
                            isDark: widget.isDark,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: widget.isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                CupertinoIcons.photo,
                                color: widget.isDark ? Color(0xFF3A3A3A) : Color(0xFFDBDBDB),
                              ),
                            )
                          : Icon(
                              CupertinoIcons.photo,
                              color: widget.isDark ? Color(0xFF3A3A3A) : Color(0xFFDBDBDB),
                            ),
                    ),
                  );
                },
                childCount: _userPosts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E8E),
          ),
        ),
      ],
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final bool isDark;
  final String currentUserId;

  const PostDetailScreen({
    required this.postId,
    required this.post,
    required this.isDark,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: PostCard(
            post: post,
            postId: postId,
            isDark: isDark,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  const FullScreenImageViewer({
    required this.imageUrl,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.xmark, color: CupertinoColors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageUrl.startsWith('data:image')
              ? Image.memory(base64Decode(imageUrl.split(',')[1]), fit: BoxFit.contain)
              : Image.network(imageUrl, fit: BoxFit.contain),
        ),
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
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _submitComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('publicacoes')
          .doc(widget.postId)
          .collection('comentarios')
          .add({
        'userId': widget.currentUserId,
        'content': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getTimeAgo(Timestamp? t) {
    if (t == null) return 'Agora';
    try {
      timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
      return timeago.format(t.toDate(), locale: 'pt_BR');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
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
                            color: Color(0xFF8E8E8E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Inicie a conversa.',
                          style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
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
                            child: Text('U', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                Text(
                                  _getTimeAgo(comment['timestamp']),
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E8E)),
                                ),
                              ],
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
              top: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFFF444F),
                    child: Text('U', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _controller,
                      placeholder: 'Adicione um comentário...',
                      placeholderStyle: TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
                      style: TextStyle(
                        color: widget.isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 14,
                      ),
                      decoration: BoxDecoration(color: Colors.transparent),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      maxLines: null,
                    ),
                  ),
                  if (_controller.text.trim().isNotEmpty)
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
    _controller.dispose();
    super.dispose();
  }
}