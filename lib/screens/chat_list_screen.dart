import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _onlineUsers = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _countOnlineUsers();
  }

  void _countOnlineUsers() {
    FirebaseFirestore.instance
        .collection('users')
        .where('online', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _onlineUsers = snapshot.docs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChatOptions() {
    final user = FirebaseAuth.instance.currentUser;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.group_add_rounded, color: Color(0xFFFF444F)),
                title: Text('Criar Grupo'),
                onTap: () {
                  Navigator.pop(context);
                  _createGroup();
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add_rounded, color: Color(0xFFFF444F)),
                title: Text('Nova Conversa'),
                onTap: () {
                  Navigator.pop(context);
                  _showUsersList();
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _createGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    if (userData['is_pro'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apenas usuários PRO podem criar grupos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Criar Grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Grupo',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance.collection('groups').add({
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'created_by': user.uid,
                'created_at': FieldValue.serverTimestamp(),
                'members': [user.uid],
                'admins': [user.uid],
                'image': '',
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Grupo criado com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF444F)),
            child: Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUsersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Selecionar Usuário',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                  }

                  final currentUser = FirebaseAuth.instance.currentUser;
                  final users = snapshot.data!.docs.where((doc) => doc.id != currentUser?.uid).toList();

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                                  ? NetworkImage(userData['profile_image'])
                                  : null,
                              backgroundColor: Color(0xFFFF444F),
                              child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                                  ? Text(
                                      (userData['username'] ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            if (userData['online'] == true)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(userData['username'] ?? 'Usuário'),
                        subtitle: Text(
                          userData['online'] == true ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: userData['online'] == true ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: _getChatId(currentUser!.uid, userId),
                                chatName: userData['username'] ?? 'Usuário',
                                isGroup: false,
                                recipientId: userId,
                              ),
                            ),
                          );
                        },
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

  String _getChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode ? '${userId1}_$userId2' : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Chats', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_onlineUsers online',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            onPressed: _showChatOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFFFF444F),
          labelColor: Color(0xFFFF444F),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Recentes'),
            Tab(text: 'Grupos'),
            Tab(text: 'Privados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentChats(),
          _buildGroupsList(),
          _buildPrivateChats(),
        ],
      ),
    );
  }

  Widget _buildRecentChats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('Faça login para ver suas conversas'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('last_message_time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Inicie uma nova conversa',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final chatId = snapshot.data!.docs[index].id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(chatData['participants'].firstWhere((id) => id != user.uid))
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return SizedBox();

                final otherUser = userSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: otherUser['profile_image'] != null && otherUser['profile_image'].isNotEmpty
                            ? NetworkImage(otherUser['profile_image'])
                            : null,
                        backgroundColor: Color(0xFFFF444F),
                        child: otherUser['profile_image'] == null || otherUser['profile_image'].isEmpty
                            ? Text(
                                (otherUser['username'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      if (otherUser['online'] == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    otherUser['username'] ?? 'Usuário',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    chatData['last_message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: chatData['unread_count'] != null && chatData['unread_count'] > 0
                      ? Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chatData['unread_count']}',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
                          chatName: otherUser['username'] ?? 'Usuário',
                          isGroup: false,
                          recipientId: userSnapshot.data!.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('Faça login para ver grupos'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum grupo ainda',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Crie ou junte-se a um grupo',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final groupData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final groupId = snapshot.data!.docs[index].id;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: groupData['image'] != null && groupData['image'].isNotEmpty
                    ? NetworkImage(groupData['image'])
                    : null,
                backgroundColor: Color(0xFFFF444F),
                child: groupData['image'] == null || groupData['image'].isEmpty
                    ? Icon(Icons.group_rounded, color: Colors.white)
                    : null,
              ),
              title: Text(
                groupData['name'] ?? 'Grupo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${groupData['members'].length} membros',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: groupId,
                      chatName: groupData['name'] ?? 'Grupo',
                      isGroup: true,
                      recipientId: null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPrivateChats() {
    return _buildRecentChats();
  }
}