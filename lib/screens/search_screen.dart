// lib/screens/search_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Pesquisar',
          style: TextStyle(
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Pesquisar sheets e usuários...',
                style: TextStyle(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
                backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
            ),
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(isDark)
                  : _buildEmptyState(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 80,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(height: 16),
          Text(
            'Pesquise por sheets ou usuários',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('publicacoes')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CupertinoActivityIndicator(radius: 16));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNoResults(isDark);
        }

        final allPosts = snapshot.data!.docs;
        
        final filteredPosts = allPosts.where((doc) {
          final post = doc.data() as Map<String, dynamic>;
          final content = (post['content'] ?? '').toString().toLowerCase();
          final username = (post['username'] ?? '').toString().toLowerCase();
          final displayName = (post['displayName'] ?? '').toString().toLowerCase();
          
          return content.contains(_searchQuery) ||
              username.contains(_searchQuery) ||
              displayName.contains(_searchQuery);
        }).toList();

        if (filteredPosts.isEmpty) {
          return _buildNoResults(isDark);
        }

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final docSnap = filteredPosts[index];
            final post = docSnap.data() as Map<String, dynamic>;
            final postId = docSnap.id;
            
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                postId: postId,
                isDark: isDark,
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search_circle,
            size: 80,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tente pesquisar com outros termos',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
    );
  }
}