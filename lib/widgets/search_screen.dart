import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/post_card.dart';
import 'app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const AppSecondaryAppBar(
        title: 'Pesquisar',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Pesquisar sheets e usuários...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                    _isSearching = value.isNotEmpty;
                  });
                },
              ),
            ),
            Expanded(
              child: _isSearching ? _buildSearchResults(isDark) : _buildEmptyState(isDark),
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
          const AppIconCircle(
            icon: Icons.search,
            size: 80,
          ),
          const SizedBox(height: 24),
          const AppSectionTitle(
            text: 'Pesquise por sheets ou usuários',
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          const SizedBox(height: 8),
          const Text(
            'Digite algo na barra de pesquisa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
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
          // removi `const` porque usamos AppColors.primary (não é const)
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNoResults(isDark);
        }

        final allPosts = snapshot.data!.docs;

        final filteredPosts = allPosts.where((doc) {
          final post = doc.data();
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final docSnap = filteredPosts[index];
            final post = docSnap.data();
            final postId = docSnap.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
          const AppIconCircle(
            icon: Icons.search_off,
            size: 80,
          ),
          const SizedBox(height: 24),
          const AppSectionTitle(
            text: 'Nenhum resultado encontrado',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente pesquisar com outros termos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const AppInfoCard(
            icon: Icons.lightbulb_outline,
            text: 'Dica: Pesquise por nome de usuário, conteúdo ou hashtags',
          ),
        ],
      ),
    );
  }
}