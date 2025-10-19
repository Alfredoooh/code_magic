import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'app_ui_components.dart';
import 'app_colors.dart';
import 'post_card.dart';

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
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppSecondaryAppBar(
        title: 'Descrição',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$userName ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextSpan(
                  text: content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
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
  State<UserProfileScreen> createState() => _UserProfileScreenState();
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
      return Scaffold(
        backgroundColor: widget.isDark ? AppColors.darkBackground : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final username = _userData?['username'] ?? 'Usuário';
    final profileImage = _userData?['profile_image'] as String?;
    final coverImage = _userData?['cover_image'] as String?;
    final isPro = _userData?['pro'] == true;
    final isAdmin = _userData?['admin'] == true;

    return Scaffold(
      backgroundColor: widget.isDark ? AppColors.darkBackground : Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: widget.isDark ? AppColors.darkBackground : Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 200,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: AppSectionTitle(
                text: username,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              background: coverImage != null && coverImage.isNotEmpty
                  ? Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                      ),
                    )
                  : Container(
                      color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark ? AppColors.darkBackground : Colors.white,
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary,
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppSectionTitle(
                            text: username,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          if (isPro) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.shield,
                              color: Colors.red,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Publicações', _postsCount.toString()),
                          _buildStatColumn('Curtidas', _totalLikes.toString()),
                          _buildStatColumn('Status', isPro ? 'PRO' : 'Free'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 1,
                        color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        MaterialPageRoute(
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
                      color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image,
                                color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
                              ),
                            )
                          : Icon(
                              Icons.image,
                              color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
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
            color: widget.isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
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
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppSecondaryAppBar(
        title: 'Publicação',
      ),
      body: SafeArea(
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageUrl.startsWith('data:image')
              ? Image.memory(
                  base64Decode(imageUrl.split(',')[1]),
                  fit: BoxFit.contain,
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
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
  State<CommentsSheet> createState() => _CommentsSheetState();
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
        color: widget.isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: AppSectionTitle(
                text: 'Comentários',
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconCircle(
                          icon: Icons.chat_bubble_outline,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum comentário ainda',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicie a conversa.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                          color: widget.isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: comment['content'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: widget.isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getTimeAgo(comment['timestamp']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkBackground : Colors.white,
              border: Border(
                top: BorderSide(
                  color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Adicione um comentário...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      maxLines: null,
                    ),
                  ),
                  if (_controller.text.trim().isNotEmpty)
                    _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : TextButton(
                            onPressed: _submitComment,
                            child: const Text(
                              'Publicar',
                              style: TextStyle(
                                color: AppColors.primary,
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