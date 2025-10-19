import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import 'news_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: const AppSecondaryAppBar(
          title: 'Favoritos',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconCircle(
                icon: Icons.person_off_outlined,
                size: 60,
                iconColor: Colors.grey,
              ),
              const SizedBox(height: 20),
              const AppSectionTitle(
                text: 'Faça login para ver seus favoritos',
                fontSize: 17,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const AppSecondaryAppBar(
        title: 'Favoritos',
      ),
      body: SafeArea(
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
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconCircle(
                        icon: Icons.bookmark_border,
                        size: 60,
                        iconColor: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const AppSectionTitle(
                        text: 'Nenhum favorito ainda',
                        fontSize: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione notícias aos favoritos para vê-las aqui',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final bookmarks = snapshot.data!.docs;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppSectionTitle(
                          text: '${bookmarks.length} ${bookmarks.length == 1 ? "Favorito" : "Favoritos"}',
                          fontSize: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = bookmarks[index];
                        final data = doc.data();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
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
                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
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

      AppDialogs.showSuccess(
        context,
        'Sucesso',
        'Removido dos favoritos',
      );
    } catch (e) {
      AppDialogs.showError(
        context,
        'Erro',
        'Não foi possível remover o favorito',
      );
    }
  }

  void _showActionSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      height: 220,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const AppSectionTitle(text: 'Ações', fontSize: 18),
          const SizedBox(height: 20),
          _buildActionOption(
            context,
            icon: Icons.share_outlined,
            title: 'Compartilhar',
            onTap: () {
              Navigator.pop(context);
              final text = '${data['title']}\n\n${data['description']}\n\n${data['source']}';
              Share.share(text, subject: data['title']);
            },
          ),
          const Divider(height: 1),
          _buildActionOption(
            context,
            icon: Icons.delete_outline,
            title: 'Remover dos Favoritos',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              AppDialogs.showConfirmation(
                context,
                'Remover Favorito',
                'Deseja realmente remover esta notícia dos favoritos?',
                onConfirm: () => _removeBookmark(context),
                confirmText: 'Remover',
                isDestructive: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : null,
                  ),
                ),
              ),
            ],
          ),
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

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                article: article,
                isDark: Theme.of(context).brightness == Brightness.dark,
                allArticles: [article],
                currentIndex: 0,
              ),
              fullscreenDialog: true,
            ),
          );
        } catch (e) {
          print('Erro ao abrir notícia: $e');
        }
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 200,
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: () => _showActionSheet(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          _getFaviconUrl(source),
                          width: 18,
                          height: 18,
                          errorBuilder: (context, error, stack) => Icon(
                            Icons.language,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          source,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.bookmark,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(savedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
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