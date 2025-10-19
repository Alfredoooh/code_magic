// lib/screens/home_posts_section.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/post_card.dart';
import '../widgets/app_colors.dart';

class HomePostsSection extends StatelessWidget {
  final List<QueryDocumentSnapshot> posts;
  final int index;
  final bool loadingMorePosts;
  final bool hasMorePosts;
  final bool isDark;

  const HomePostsSection({
    required this.posts,
    required this.index,
    required this.loadingMorePosts,
    required this.hasMorePosts,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (index < posts.length) {
      return _buildPostItem();
    } else if (loadingMorePosts) {
      return _buildLoadingIndicator();
    } else if (!hasMorePosts) {
      return _buildEndMessage();
    }
    return SizedBox.shrink();
  }

  Widget _buildPostItem() {
    final post = posts[index].data() as Map<String, dynamic>;
    final postId = posts[index].id;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 0),
      child: PostCard(
        post: post,
        postId: postId,
        isDark: isDark,
        currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEndMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.grey,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Não há mais publicações',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}