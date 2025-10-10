import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../models/strategy_model.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _postController = TextEditingController();
  bool _isPosting = false;

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('login_required') ?? 'Login necessário'),
          backgroundColor: danger,
        ),
      );
      return;
    }

    if (_postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('empty_post') ?? 'Escreva algo para postar'),
          backgroundColor: warning,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'content': _postController.text.trim(),
        'images': [],
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });
      
      _postController.clear();
      FocusScope.of(context).unfocus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('post_created') ?? 'Post criado com sucesso!'),
            backgroundColor: success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('error_creating_post') ?? 'Erro ao criar post'),
            backgroundColor: danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _likePost(String postId, int currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('error_liking_post') ?? 'Erro ao curtir post'),
            backgroundColor: danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de criar post
            Text(
              AppLocalizations.of(context)?.translate('create_post') ?? 'Criar Post',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _postController,
                      maxLines: 4,
                      enabled: !_isPosting,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)?.translate('write_post') ?? 'O que você está pensando?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: AppLocalizations.of(context)?.translate('post') ?? 'Publicar',
                        onPressed: _isPosting ? null : _createPost,
                        isLoading: _isPosting,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feed de posts
            Text(
              AppLocalizations.of(context)?.translate('feed') ?? 'Feed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)?.translate('error_loading') ?? 'Erro ao carregar',
                      style: TextStyle(color: danger),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        AppLocalizations.of(context)?.translate('no_posts') ?? 'Nenhum post ainda',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final posts = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return PostModel.fromJson(data);
                }).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_rounded),
                                  color: accentPrimary,
                                  onPressed: () => _likePost(post.id, post.likes),
                                ),
                                Text(
                                  post.likes.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.comment_rounded),
                                  color: accentPrimary,
                                  onPressed: () {
                                    // Implementar tela de comentários
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)?.translate('coming_soon') ?? 'Em breve',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  post.comments.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Marketplace de estratégias
            Text(
              AppLocalizations.of(context)?.translate('marketplace') ?? 'Marketplace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('strategies')
                  .orderBy('rating', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)?.translate('error_loading') ?? 'Erro ao carregar',
                      style: TextStyle(color: danger),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        AppLocalizations.of(context)?.translate('no_strategies') ?? 'Nenhuma estratégia disponível',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                final strategies = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return StrategyModel.fromJson(data);
                }).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: strategies.length,
                  itemBuilder: (context, index) {
                    final strategy = strategies[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Implementar detalhes da estratégia
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${strategy.name} - ${AppLocalizations.of(context)?.translate('coming_soon') ?? 'Em breve'}'),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strategy.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  strategy.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${strategy.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: accentPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: warning,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    strategy.rating.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${strategy.reviews})',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}