import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';
import 'group_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _activeUsers = 0;
  Map<String, dynamic>? _userData;
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getActiveUsers();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Listener para usuários online em tempo real
    FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() => _activeUsers = snapshot.docs.length);
      }
    });
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          setState(() => _userData = doc.data());
        }
      });
    }
  }

  void _getActiveUsers() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .get();
    if (mounted) {
      setState(() => _activeUsers = usersSnapshot.docs.length);
    }
  }

  void _showOptionsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Novas Conversas',
          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showUsersDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_add, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text('Nova Conversa', style: TextStyle(color: Color(0xFFFF444F))),
              ],
            ),
          ),
          if (_userData?['pro'] == true)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.group, color: Color(0xFFFF444F)),
                  SizedBox(width: 8),
                  Text('Criar Grupo', style: TextStyle(color: Color(0xFFFF444F))),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Criar Grupo'),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Nome do grupo',
            placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
            style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance.collection('groups').add({
                      'name': nameController.text.trim(),
                      'createdBy': user.uid,
                      'creatorName': _userData?['username'] ?? 'Usuário',
                      'members': [user.uid],
                      'timestamp': FieldValue.serverTimestamp(),
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    print('Erro ao criar grupo: $e');
                  }
                }
              }
            },
            child: Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar', style: TextStyle(color: Color(0xFFFF444F))),
                    ),
                    Text(
                      'Novo Chat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    SizedBox(width: 60),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Buscar',
                  style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
                  onChanged: (value) {
                    setModalState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      );
                    }

                    final allUsers = snapshot.data!.docs.where((doc) {
                      if (doc.id == currentUser!.uid) return false;
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
                            Icon(
                              CupertinoIcons.person_2,
                              size: 60,
                              color: CupertinoColors.systemGrey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Nenhum usuário disponível' : 'Nenhum resultado',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = allUsers[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final isOnline = userData['isOnline'] == true;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey6,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: CupertinoListTile(
                            leading: Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF444F),
                                  ),
                                  child: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            userData['profile_image'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            (userData['username'] ?? 'U')[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: CupertinoColors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.activeGreen,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.white,
                                          width: 2,
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
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                            subtitle: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                                fontSize: 13,
                              ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        middle: Text(
          'Conversas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_activeUsers > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$_activeUsers',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showOptionsMenu,
              child: Icon(
                CupertinoIcons.add_circled,
                color: Color(0xFFFF444F),
                size: 28,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0 ? Color(0xFFFF444F) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Chats',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTab == 0
                                ? Color(0xFFFF444F)
                                : CupertinoColors.systemGrey,
                            fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1 ? Color(0xFFFF444F) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Grupos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? Color(0xFFFF444F)
                                : CupertinoColors.systemGrey,
                            fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: currentUser == null
                  ? Center(child: CupertinoActivityIndicator(radius: 15))
                  : (_selectedTab == 0
                      ? _buildConversationsList(currentUser, isDark)
                      : _buildGroupsList(currentUser, isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(User currentUser, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
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
                  CupertinoIcons.chat_bubble_2,
                  size: 80,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma conversa',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toque em + para começar',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(conversation['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return SizedBox.shrink();

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final isOnline = userData['isOnline'] == true;
                final lastMessage = conversation['lastMessage'] ?? '';
                final unreadCount = conversation['unreadCount_${currentUser.uid}'] ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey6,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: CupertinoListTile(
                    leading: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF444F),
                          ),
                          child: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    userData['profile_image'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    (userData['username'] ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                                  width: 2,
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
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF444F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ChatDetailScreen(
                            recipientId: otherUserId,
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
        );
      },
    );
  }

  Widget _buildGroupsList(User currentUser, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
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
                  CupertinoIcons.group,
                  size: 80,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum grupo',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _userData?['pro'] == true ? 'Toque em + para criar' : 'Apenas PRO',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupData = groups[index].data() as Map<String, dynamic>;
            final members = List.from(groupData['members'] ?? []);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey6,
                    width: 0.5,
                  ),
                ),
              ),
              child: CupertinoListTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.activeGreen,
                  ),
                  child: Icon(
                    CupertinoIcons.group_solid,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  groupData['name'] ?? 'Grupo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                subtitle: Text(
                  '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: groups[index].id,
                        groupName: groupData['name'] ?? 'Grupo',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}