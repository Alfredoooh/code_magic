import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import 'news_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

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
            onPressed: () => Navigator.pop(context),
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
          onPressed: () => Navigator.pop(context),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('bookmarks')
              .orderBy('savedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CupertinoActivityIndicator(
                  radius: 15,
                  color: primaryColor,
                ),
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
                        fontWeight: FontWeight.w700,
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
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${bookmarks.length} ${bookmarks.length == 1 ? "Favorito" : "Favoritos"}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark 
                              ? CupertinoColors.white 
                              : CupertinoColors.black,
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
                            primaryColor: primaryColor,
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
  final Color primaryColor;

  const _BookmarkCard({
    required this.data,
    required this.docId,
    required this.userId,
    required this.isDark,
    required this.primaryColor,
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
        if (context.mounted) {
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
              onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
              final text = '${data['title']}\n\n${data['description']}\n\n${data['source']}';
              Share.share(text, subject: data['title']);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 20, color: primaryColor),
                SizedBox(width: 8),
                Text('Compartilhar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
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
          onPressed: () => Navigator.pop(context),
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
            publishedAt: DateTime.parse(data['publishedAt'] ?? DateTime.now().toIso8601String()),
            category: category,
          );

          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => NewsDetailScreen(article: article),
            ),
          );
        } catch (e) {
          print('Erro ao abrir notícia: $e');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 180,
                    color: isDark 
                      ? Color(0xFF2C2C2E) 
                      : CupertinoColors.systemGrey6,
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => _showActionSheet(context),
                        child: Icon(
                          CupertinoIcons.ellipsis_circle,
                          color: isDark 
                            ? CupertinoColors.white 
                            : CupertinoColors.black,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark 
                        ? CupertinoColors.white 
                        : CupertinoColors.black,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark 
                        ? CupertinoColors.white.withOpacity(0.7) 
                        : CupertinoColors.black.withOpacity(0.6),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: isDark 
                      ? CupertinoColors.white.withOpacity(0.1) 
                      : CupertinoColors.black.withOpacity(0.05),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          _getFaviconUrl(source),
                          width: 18,
                          height: 18,
                          errorBuilder: (context, error, stack) => Icon(
                            CupertinoIcons.news,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          source,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.bookmark_solid,
                        size: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 4),
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