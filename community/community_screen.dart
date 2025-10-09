import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../models/strategy_model.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _postController = TextEditingController();

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _postController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'userId': user.uid,
      'content': _postController.text,
      'images': [],
      'timestamp': Timestamp.now(),
      'likes': 0,
      'comments': 0,
    });
    _postController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.translate('feed')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).limit(20).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(AppLocalizations.of(context)!.translate('error_loading')!);
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              final posts = snapshot.data!.docs.map((doc) => PostModel.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up_rounded),
                                onPressed: () {
                                  FirebaseFirestore.instance.collection('posts').doc(post.id).update({'likes': FieldValue.increment(1)});
                                },
                              ),
                              Text(post.likes.toString()),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.comment_rounded),
                                onPressed: () {
                                  // Open comments screen
                                },
                              ),
                              Text(post.comments.toString()),
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
          Text(AppLocalizations.of(context)!.translate('create_post')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _postController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('write_post')!,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('post')!,
            onPressed: _createPost,
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('marketplace')!, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('strategies').orderBy('rating', descending: true).limit(10).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(AppLocalizations.of(context)!.translate('error_loading')!);
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              final strategies = snapshot.data!.docs.map((doc) => StrategyModel.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id).toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5),
                itemCount: strategies.length,
                itemBuilder: (context, index) {
                  final strategy = strategies[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strategy.name, style: Theme.of(context).textTheme.bodyLarge),
                          Text(strategy.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text('\$${strategy.price.toStringAsFixed(2)}'),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: warning, size: 16),
                              Text(strategy.rating.toStringAsFixed(1)),
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
          // Add sections for groups, leaderboard, etc.
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}
