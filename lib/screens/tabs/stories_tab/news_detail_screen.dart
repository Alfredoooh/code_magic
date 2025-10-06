import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../../models/news_stories_models.dart';
import 'bookmarks_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsStory news;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const NewsDetailScreen({
    Key? key,
    required this.news,
    required this.isLiked,
    required this.onLikeToggle,
  }) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool _isBookmarked;
  bool _hasShownBookmarkDialog = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  List<UserComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _isBookmarked = false;
    _checkIfBookmarked();
    _checkIfShouldShowDialog();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIfBookmarked() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

    setState(() {
      _isBookmarked = bookmarksJson.any((jsonStr) {
        try {
          final bookmark = jsonDecode(jsonStr);
          return bookmark['id'] == widget.news.id;
        } catch (_) {
          return false;
        }
      });
    });
  }

  Future<void> _checkIfShouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_bookmark_dialog') ?? false;
    _hasShownBookmarkDialog = hasShown;
  }

  Future<void> _loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = prefs.getStringList('comments_${widget.news.id}') ?? [];

    setState(() {
      _comments = commentsJson.map((jsonStr) {
        try {
          return UserComment.fromJson(jsonDecode(jsonStr));
        } catch (_) {
          // Se houver JSON inválido, ignorar
          return null;
        }
      }).whereType<UserComment>().toList();
    });
  }

  Future<void> _saveComment(String text) async {
    if (text.trim().isEmpty) return;

    final comment = UserComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'Você',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _comments.insert(0, comment);
    });

    final prefs = await SharedPreferences.getInstance();
    final commentsJson = _comments.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('comments_${widget.news.id}', commentsJson);

    _commentController.clear();
    _commentFocusNode.unfocus();
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList('bookmarks') ?? [];

    if (_isBookmarked) {
      bookmarksJson.removeWhere((jsonStr) {
        try {
          final bookmark = jsonDecode(jsonStr);
          return bookmark['id'] == widget.news.id;
        } catch (_) {
          return false;
        }
      });

      setState(() => _isBookmarked = false);
      await prefs.setStringList('bookmarks', bookmarksJson);
      _showSnackBar('Removido dos favoritos');
    } else {
      final newsJson = jsonEncode(widget.news.toJson());
      bookmarksJson.add(newsJson);

      setState(() => _isBookmarked = true);
      await prefs.setStringList('bookmarks', bookmarksJson);
      _showSnackBar('Adicionado aos favoritos');

      if (!_hasShownBookmarkDialog) {
        await prefs.setBool('has_shown_bookmark_dialog', true);
        _showBookmarkInfoDialog();
      }
    }
  }

  void _showBookmarkInfoDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Dica'),
        content: const Text(
          'Para visualizar os conteúdos salvos, pressione durante 2 segundos no botão de favoritos!',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'SF Pro Text',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _openBookmarks() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const BookmarksScreen(),
      ),
    );
  }

  void _shareNews() {
    final text = '''
${widget.news.title}

${widget.news.content}

Fonte: ${widget.news.source}
''';

    Share.share(
      text,
      subject: widget.news.title,
    );
  }

  void _showShareOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Compartilhar notícia',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 13,
            color: Color(0xFF8E8E93),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _shareNews();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.share, size: 20),
                SizedBox(width: 12),
                Text(
                  'Compartilhar via...',
                  style: TextStyle(fontFamily: 'SF Pro Text'),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: widget.news.title));
              _showSnackBar('Link copiado');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.link, size: 20),
                SizedBox(width: 12),
                Text(
                  'Copiar link',
                  style: TextStyle(fontFamily: 'SF Pro Text'),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontFamily: 'SF Pro Text'),
          ),
        ),
      ),
    );
  }

  void _openComments() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comentários (${_comments.length})',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _comments.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 64,
                            color: Color(0xFF3A3A3C),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum comentário ainda',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 16,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Seja o primeiro a comentar',
                            style: TextStyle(
                              color: Color(0xFF5E5E60),
                              fontSize: 14,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFF2C2C2E),
                        height: 1,
                        thickness: 0.5,
                      ),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                border: Border(
                  top: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      placeholder: 'Adicionar comentário...',
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontFamily: 'SF Pro Text',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'SF Pro Text',
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => _saveComment(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _saveComment(_commentController.text),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(UserComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCommentTime(comment.timestamp),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: Color(0xFFE5E5EA),
                    fontSize: 15,
                    height: 1.4,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF000000),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF000000).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            actions: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showShareOptions,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.share,
                    color: Color(0xFFFFFFFF),
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleBookmark,
                onLongPress: _openBookmarks,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                    color: _isBookmarked ? const Color(0xFF007AFF) : const Color(0xFFFFFFFF),
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.news.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1C1C1E),
                      child: const Icon(
                        CupertinoIcons.photo,
                        color: Color(0xFF8E8E93),
                        size: 64,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          const Color(0xFF000000).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF000000),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.news.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    widget.news.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                      height: 1.2,
                      letterSpacing: -0.5,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.person_fill,
                          color: Color(0xFFFFFFFF),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.news.author,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Text',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatFullDate(widget.news.publishedAt),
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Container(
                    height: 0.5,
                    color: const Color(0xFF2C2C2E),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    widget.news.content,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFFE5E5EA),
                      height: 1.6,
                      letterSpacing: -0.2,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: CupertinoIcons.chat_bubble_text,
                          label: 'Comentários',
                          count: '${_comments.length}',
                          onTap: _openComments,
                        ),
                        Container(
                          width: 0.5,
                          height: 40,
                          color: const Color(0xFF2C2C2E),
                        ),
                        _buildActionButton(
                          icon: CupertinoIcons.arrowshape_turn_up_right,
                          label: 'Compartilhar',
                          count: '',
                          onTap: _showShareOptions,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String count,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF8E8E93),
            size: 22,
          ),
          const SizedBox(height: 6),
          if (count.isNotEmpty)
            Text(
              count,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
              ),
            ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}

/// Classe local para comentários do utilizador (renomeada para evitar colisão com o modelo global).
class UserComment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;

  UserComment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UserComment.fromJson(Map<String, dynamic> json) => UserComment(
    id: json['id'].toString(),
    author: json['author'] ?? 'Anon',
    text: json['text'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}