import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';

class UsersListScreen extends StatefulWidget {
  final User? currentUser;
  final Map<String, dynamic>? userData;

  const UsersListScreen({
    Key? key,
    required this.currentUser,
    this.userData,
  }) : super(key: key);

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  static const Color primaryColor = Color(0xFFFF444F);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: primaryColor),
          ),
        ),
        middle: Text(
          'Novo Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: (isDark ? CupertinoColors.black : CupertinoColors.white).withOpacity(0.85),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Buscar',
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CupertinoActivityIndicator(radius: 15));
                  }

                  final allUsers = snapshot.data!.docs.where((doc) {
                    if (doc.id == widget.currentUser?.uid) return false;
                    if (_searchQuery.isNotEmpty) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data['username'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return username.contains(_searchQuery) || email.contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (allUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.person_2,
                            size: 64,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'Nenhum usuário disponível' : 'Nenhum resultado',
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: allUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 88,
                      color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
                    ),
                    itemBuilder: (context, index) {
                      final userDoc = allUsers[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final isOnline = userData['isOnline'] == true;

                      return Container(
                        color: isDark ? CupertinoColors.black : CupertinoColors.white,
                        child: CupertinoListTile(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryColor,
                                ),
                                child: userData['profile_image'] != null &&
                                        userData['profile_image'].isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          userData['profile_image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              (userData['username'] ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 22,
                                                color: CupertinoColors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (userData['username'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: CupertinoColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? CupertinoColors.black : CupertinoColors.white,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            userData['username'] ?? 'Usuário',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                              fontSize: 15,
                            ),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 32,
                            child: const Icon(
                              CupertinoIcons.chat_bubble_fill,
                              color: primaryColor,
                              size: 24,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    recipientId: userDoc.id,
                                    recipientName: userData['username'] ?? 'Usuário',
                                    recipientImage: userData['profile_image'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  recipientId: userDoc.id,
                                  recipientName: userData['username'] ?? 'Usuário',
                                  recipientImage: userData['profile_image'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}