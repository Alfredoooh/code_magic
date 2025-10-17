import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersListScreen extends StatefulWidget {
  final User? currentUser;
  final Map<String, dynamic>? userData;
  final Function(String)? onUserSelected;

  const UsersListScreen({
    Key? key,
    this.currentUser,
    this.userData,
    this.onUserSelected,
  }) : super(key: key);

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
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
        backgroundColor: isDark ? Color(0xFF000000).withOpacity(0.9) : CupertinoColors.white.withOpacity(0.9),
        border: null,
        middle: Text('Usuários'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar usuários',
                style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  var users = snapshot.data!.docs.where((doc) {
                    return doc.id != widget.currentUser?.uid;
                  }).toList();

                  if (_searchQuery.isNotEmpty) {
                    users = users.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data['username'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return username.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();
                  }

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 64,
                            color: CupertinoColors.systemGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum resultado',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tente buscar outro usuário',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: BouncingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      final username = userData['username'] ?? 'Usuário';
                      final email = userData['email'] ?? '';
                      final profileImage = userData['profile_image'] ?? '';
                      final isOnline = userData['isOnline'] == true;
                      final isPro = userData['pro'] == true;
                      final isAdmin = userData['admin'] == true;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? CupertinoColors.black : CupertinoColors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark 
                                  ? CupertinoColors.systemGrey6.darkColor
                                  : CupertinoColors.systemGrey6,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: CupertinoListTile(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF444F),
                                ),
                                child: profileImage.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          profileImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              username[0].toUpperCase(),
                                              style: TextStyle(
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
                                          username[0].toUpperCase(),
                                          style: TextStyle(
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                  ),
                                ),
                              ),
                              if (isPro)
                                Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    color: CupertinoColors.activeBlue,
                                    size: 16,
                                  ),
                                ),
                              if (isAdmin)
                                Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    CupertinoIcons.shield_fill,
                                    color: Color(0xFFFF444F),
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : email,
                            style: TextStyle(
                              color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                              fontSize: 15,
                            ),
                          ),
                          trailing: Icon(
                            CupertinoIcons.chat_bubble_fill,
                            color: Color(0xFFFF444F),
                            size: 24,
                          ),
                          onTap: () {
                            if (widget.onUserSelected != null) {
                              Navigator.pop(context);
                              widget.onUserSelected!(userId);
                            }
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