// lib/screens/bookmarks_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import 'news_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark
              ? Color(0xFF1C1C1E).withOpacity(0.95)
              : CupertinoColors.white.withOpacity(0.95),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          middle: Text(
            'Favoritos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          border: null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                size: 80,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 20),
              Text(
                'Faça login para ver seus favoritos',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark
            ? Color(0xFF1C1C1E).withOpacity(0.95)
            : CupertinoColors.white.withOpacity(0.95),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Favoritos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('bookmarks')
              .orderBy('savedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CupertinoActivityIndicator(radius: 15),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.bookmark,
                      size: 80,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Nenhum favorito ainda',
                      style: TextStyle(
                        color: isDark
                            ? CupertinoColors.white.withOpacity(0.7)
                            : CupertinoColors.black.withOpacity(0.6),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Adicione notícias aos favoritos para vê-las aqui',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final bookmarks = snapshot.data!.docs;

            return CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${bookmarks.length} ${bookmarks.length == 1 ? "Favorito" : "Favoritos"}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = bookmarks[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _BookmarkCard(
                            data: data,
                            docId: doc.id,
                            userId: user.uid,
                            isDark: isDark,
                          ),
                        );
                      },
                      childCount: bookmarks.length,
                    ),
                  ),
                ),
                SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String userId;
  final bool isDark;

  const _BookmarkCard({
    required this.data,
    required this.docId,
    required this.userId,
    required this.isDark,
  });

  String _getFaviconUrl(String source) {
    final domain = source.toLowerCase().replaceAll(' ', '');
    return 'https://www.google.com/s2/favicons?domain=$domain.com&sz=64';
  }

  String _getTimeAgo(dynamic savedAt) {
    if (savedAt == null) return 'Recente';

    try {
      final timestamp = savedAt as Timestamp;
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d atrás';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h atrás';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min atrás';
      } else {
        return 'Agora';
      }
    } catch (e) {
      return 'Recente';
    }
  }

  Future<void> _removeBookmark(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(docId)
          .delete();

      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen,
                size: 24,
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Removido dos favoritos',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      Future.delayed(Duration(seconds: 1), () {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Erro'),
          content: Text('Não foi possível remover o favorito'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Ações',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              final text = '${data['title']}\n\n${data['description']}\n\n${data['source']}';
              Share.share(text, subject: data['title']);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 20, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text('Compartilhar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _removeBookmark(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.trash, size: 20),
                SizedBox(width: 8),
                Text('Remover dos Favoritos'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final title = data['title'] ?? 'Sem título';
    final description = data['description'] ?? '';
    final source = data['source'] ?? 'Fonte desconhecida';
    final category = data['category'] ?? 'Geral';
    final savedAt = data['savedAt'];

    return GestureDetector(
      onTap: () {
        try {
          final article = NewsArticle(
            title: title,
            description: description,
            url: data['url'] ?? '',
            imageUrl: imageUrl,
            source: source,
            publishedAt: DateTime.parse(
                data['publishedAt'] ?? DateTime.now().toIso8601String()),
            category: category,
          );

          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => NewsDetailScreen(
                article: article,
                allArticles: [article],
                currentIndex: 0,
                isDark: isDark,
              ),
              fullscreenDialog: true,
            ),
          );
        } catch (e) {
          print('Erro ao abrir notícia: $e');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 200,
                    color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF444F).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: Color(0xFFFF444F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => _showActionSheet(context),
                        child: Icon(
                          CupertinoIcons.ellipsis_circle_fill,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                        .withOpacity(0.08),
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          _getFaviconUrl(source),
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stack) => Icon(
                            CupertinoIcons.news,
                            size: 20,
                            color: Color(0xFFFF444F),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          source,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF444F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.bookmark_solid,
                        size: 15,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        _getTimeAgo(savedAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w600,
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
  }
}