// chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_screen.dart';
import 'group_chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  ChatsListScreen({this.userData});

  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _countActiveUsers();
  }

  void _countActiveUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .where('online', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeUsers = snapshot.docs.length;
        });
      }
    });
  }

  void _showChatOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Opções de Chat'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showUsersList();
            },
            child: Text('Nova Conversa'),
          ),
          if (widget.userData?['isPro'] == true)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
              child: Text('Criar Grupo'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showGroupsList();
            },
            child: Text('Ver Grupos'),
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

  void _showUsersList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Selecionar Usuário',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('id',
                        isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;

                      return _buildUserItem(userData, userId);
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

  Widget _buildUserItem(Map<String, dynamic> userData, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = userData['online'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChatRoomScreen(
                  recipientId: userId,
                  recipientName: userData['full_name'] ?? 'Usuário',
                  recipientImage: userData['profile_image'],
                  isOnline: isOnline,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                        userData['profile_image'] ??
                            'https://alfredoooh.github.io/database/gallery/app_icon.png',
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
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['full_name'] ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF0E0E0E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 13,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController groupNameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Criar Grupo'),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: groupNameController,
            placeholder: 'Nome do grupo',
            padding: EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (groupNameController.text.trim().isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                await FirebaseFirestore.instance.collection('groups').add({
                  'name': groupNameController.text.trim(),
                  'creator_id': user?.uid,
                  'creator_name': widget.userData?['full_name'] ?? 'Usuário',
                  'members': [user?.uid],
                  'created_at': FieldValue.serverTimestamp(),
                  'image_url': 'https://alfredoooh.github.io/database/gallery/app_icon.png',
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grupo criado com sucesso!')),
                );
              }
            },
            isDefaultAction: true,
            child: Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showGroupsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Grupos Disponíveis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  final groups = snapshot.data!.docs;

                  if (groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_rounded, size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum grupo disponível',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final groupData = groups[index].data() as Map<String, dynamic>;
                      final groupId = groups[index].id;

                      return _buildGroupItem(groupData, groupId);
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

  Widget _buildGroupItem(Map<String, dynamic> groupData, String groupId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => GroupChatScreen(
                  groupId: groupId,
                  groupName: groupData['name'] ?? 'Grupo',
                  groupImage: groupData['image_url'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                    groupData['image_url'] ??
                        'https://alfredoooh.github.io/database/gallery/app_icon.png',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupData['name'] ?? 'Grupo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF0E0E0E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${(groupData['members'] as List?)?.length ?? 0} membros',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF38383A) : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        leading: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '$_activeUsers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        middle: Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF0E0E0E),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showChatOptions,
          child: Icon(
            Icons.add_circle_rounded,
            color: Color(0xFFFF444F),
            size: 28,
          ),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: user?.uid)
              .orderBy('last_message_time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CupertinoActivityIndicator());
            }

            final chats = snapshot.data!.docs;

            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 100,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Nenhuma conversa ainda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toque no + para iniciar uma conversa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chatData = chats[index].data() as Map<String, dynamic>;
                final chatId = chats[index].id;

                final participants = chatData['participants'] as List;
                final otherUserId = participants.firstWhere(
                  (id) => id != user?.uid,
                  orElse: () => null,
                );

                if (otherUserId == null) return SizedBox.shrink();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return SizedBox.shrink();
                    }

                    final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (otherUserData == null) return SizedBox.shrink();

                    return _buildChatItem(
                      chatData,
                      chatId,
                      otherUserData,
                      otherUserId,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(
    Map<String, dynamic> chatData,
    String chatId,
    Map<String, dynamic> otherUserData,
    String otherUserId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = otherUserData['online'] == true;
    final lastMessage = chatData['last_message'] ?? '';
    final unreadCount = chatData['unread_${FirebaseAuth.instance.currentUser?.uid}'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => ChatRoomScreen(
                  recipientId: otherUserId,
                  recipientName: otherUserData['full_name'] ?? 'Usuário',
                  recipientImage: otherUserData['profile_image'],
                  isOnline: isOnline,
                  chatId: chatId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                        otherUserData['profile_image'] ??
                            'https://alfredoooh.github.io/database/gallery/app_icon.png',
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
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUserData['full_name'] ?? 'Usuário',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF0E0E0E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
