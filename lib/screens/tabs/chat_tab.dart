import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/theme_service.dart';
import '../profile_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({Key? key}) : super(key: key);
  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  int _selectedTab = 0;
  final _database = FirebaseDatabase.instance.ref();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ThemeService.backgroundColor,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: ThemeService.backgroundColor.withOpacity(0.8),
              elevation: 0,
              systemOverlayStyle: ThemeService.isDarkMode 
                  ? SystemUiOverlayStyle.light 
                  : SystemUiOverlayStyle.dark,
              leading: IconButton(
                icon: Icon(CupertinoIcons.bars, color: ThemeService.textColor),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                'Chats',
                style: TextStyle(color: ThemeService.textColor, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  icon: Icon(CupertinoIcons.person_circle, color: ThemeService.textColor),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                  },
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.add, color: ThemeService.textColor),
                  onPressed: () => _showNewChatDialog(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? const Color(0xFF1877F2) : ThemeService.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                      child: Text('Diretas',
                          style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : ThemeService.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? const Color(0xFF1877F2) : ThemeService.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                      child: Text('Canais',
                          style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : ThemeService.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ]),
        ),
        Expanded(child: _selectedTab == 0 ? _buildDirectMessages(user) : _buildChannels(user)),
      ]),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      backgroundColor: ThemeService.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF1877F2),
                    backgroundImage: user?.photoURL != null 
                        ? NetworkImage(user!.photoURL!) 
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Usuário',
                          style: TextStyle(
                            color: ThemeService.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: ThemeService.textColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: ThemeService.textColor.withOpacity(0.1)),
            ListTile(
              leading: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF1877F2)),
              title: Text('Conversas Diretas', style: TextStyle(color: ThemeService.textColor)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedTab = 0);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.group_solid, color: Color(0xFF1877F2)),
              title: Text('Canais', style: TextStyle(color: ThemeService.textColor)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedTab = 1);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.person_2_fill, color: Color(0xFF1877F2)),
              title: Text('Usuários Ativos', style: TextStyle(color: ThemeService.textColor)),
              onTap: () {
                Navigator.pop(context);
                _showActiveUsers();
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.square_arrow_right, color: Color(0xFF1877F2)),
              title: Text('Chat Geral', style: TextStyle(color: ThemeService.textColor)),
              onTap: () {
                Navigator.pop(context);
                _openGeneralChat();
              },
            ),
            const Spacer(),
            Divider(color: ThemeService.textColor.withOpacity(0.1)),
            ListTile(
              leading: Icon(CupertinoIcons.settings, color: ThemeService.textColor),
              title: Text('Configurações', style: TextStyle(color: ThemeService.textColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveUsers() {
    final currentUser = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeService.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Usuários Ativos', style: TextStyle(color: ThemeService.textColor, fontSize: 20, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Online', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _database.child('users').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || (snapshot.data!.snapshot.value == null)) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final usersMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final users = usersMap.entries.where((e) => e.key != currentUser?.uid).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_2, size: 60, color: ThemeService.textColor.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('Nenhum usuário encontrado', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: controller,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userEntry = users[index];
                    final userId = userEntry.key;
                    final userData = Map<String, dynamic>.from(userEntry.value);

                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1877F2),
                            backgroundImage: userData['photoURL'] != null && userData['photoURL'] != ''
                                ? NetworkImage(userData['photoURL'])
                                : null,
                            child: userData['photoURL'] == null || userData['photoURL'] == ''
                                ? Text((userData['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: ThemeService.backgroundColor, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(userData['name'] ?? 'Usuário', style: TextStyle(color: ThemeService.textColor, fontWeight: FontWeight.w600)),
                      subtitle: Text(userData['email'] ?? '', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.chat_bubble_fill, color: Color(0xFF1877F2)),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _createDirectChat(userId);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDirectMessages(User? user) {
    if (user == null) {
      return Center(child: Text('Faça login para ver conversas', style: TextStyle(color: ThemeService.textColor)));
    }

    return StreamBuilder(
      stream: _database.child('chats').orderByChild('lastMessageTime').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data!.snapshot.value == null)) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.chat_bubble_2, size: 80, color: ThemeService.textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Nenhuma conversa ainda', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 16)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showNewChatDialog(),
                child: const Text('Iniciar conversa', style: TextStyle(color: Color(0xFF1877F2), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ]),
          );
        }

        final chatsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final directChats = chatsMap.entries
            .where((e) {
              final chat = Map<String, dynamic>.from(e.value);
              return chat['type'] == 'direct' && 
                     chat['participants'] != null &&
                     (chat['participants'] as Map).containsKey(user.uid);
            })
            .toList()
          ..sort((a, b) {
            final aTime = (Map<String, dynamic>.from(a.value))['lastMessageTime'] ?? 0;
            final bTime = (Map<String, dynamic>.from(b.value))['lastMessageTime'] ?? 0;
            return (bTime as num).compareTo(aTime as num);
          });

        if (directChats.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.chat_bubble_2, size: 80, color: ThemeService.textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Nenhuma conversa direta', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 16)),
            ]),
          );
        }

        return ListView.builder(
          itemCount: directChats.length,
          itemBuilder: (context, index) {
            final chatEntry = directChats[index];
            final chatId = chatEntry.key;
            final chat = Map<String, dynamic>.from(chatEntry.value);
            
            final participants = Map<String, dynamic>.from(chat['participants'] ?? {});
            final otherUserId = participants.keys.firstWhere(
              (id) => id != user.uid,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return const SizedBox.shrink();

            return FutureBuilder(
              future: _database.child('users').child(otherUserId).once(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                  return Container();
                }
                
                final otherUser = Map<String, dynamic>.from(userSnapshot.data!.snapshot.value as Map);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1877F2),
                    backgroundImage: otherUser['photoURL'] != null && otherUser['photoURL'] != '' 
                        ? NetworkImage(otherUser['photoURL']) 
                        : null,
                    child: otherUser['photoURL'] == null || otherUser['photoURL'] == ''
                        ? Text((otherUser['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(
                    otherUser['name'] ?? 'Usuário',
                    style: TextStyle(color: ThemeService.textColor, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    chat['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ThemeService.textColor.withOpacity(0.6)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
                          chatName: otherUser['name'] ?? 'Usuário',
                          isChannel: false,
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

  Widget _buildChannels(User? user) {
    if (user == null) {
      return Center(child: Text('Faça login para ver canais', style: TextStyle(color: ThemeService.textColor)));
    }

    return StreamBuilder(
      stream: _database.child('chats').orderByChild('lastMessageTime').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data!.snapshot.value == null)) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.group, size: 80, color: ThemeService.textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Nenhum canal ainda', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 16)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showCreateChannel(),
                child: const Text('Criar canal', style: TextStyle(color: Color(0xFF1877F2), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ]),
          );
        }

        final chatsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final channels = chatsMap.entries
            .where((e) {
              final chat = Map<String, dynamic>.from(e.value);
              return chat['type'] == 'channel' &&
                     chat['participants'] != null &&
                     (chat['participants'] as Map).containsKey(user.uid);
            })
            .toList()
          ..sort((a, b) {
            final aTime = (Map<String, dynamic>.from(a.value))['lastMessageTime'] ?? 0;
            final bTime = (Map<String, dynamic>.from(b.value))['lastMessageTime'] ?? 0;
            return (bTime as num).compareTo(aTime as num);
          });

        if (channels.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.group, size: 80, color: ThemeService.textColor.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Nenhum canal disponível', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 16)),
            ]),
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channelEntry = channels[index];
            final channelId = channelEntry.key;
            final channel = Map<String, dynamic>.from(channelEntry.value);
            final participants = Map<String, dynamic>.from(channel['participants'] ?? {});

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1877F2),
                child: const Icon(CupertinoIcons.group_solid, color: Colors.white),
              ),
              title: Text(
                channel['name'] ?? 'Canal',
                style: TextStyle(color: ThemeService.textColor, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                channel['lastMessage'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ThemeService.textColor.withOpacity(0.6)),
              ),
              trailing: Text(
                '${participants.length} membros',
                style: TextStyle(color: ThemeService.textColor.withOpacity(0.5), fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: channelId,
                      chatName: channel['name'] ?? 'Canal',
                      isChannel: true,
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

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeService.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(CupertinoIcons.person, color: Color(0xFF1877F2)),
            title: Text('Nova Mensagem Direta', style: TextStyle(color: ThemeService.textColor)),
            onTap: () {
              Navigator.pop(context);
              _showUserSelection();
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.group, color: Color(0xFF1877F2)),
            title: Text('Criar Canal', style: TextStyle(color: ThemeService.textColor)),
            onTap: () {
              Navigator.pop(context);
              _showCreateChannel();
            },
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.chat_bubble_2, color: Color(0xFF1877F2)),
            title: Text('Geral', style: TextStyle(color: ThemeService.textColor)),
            subtitle: Text('Conversa pública geral', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6))),
            onTap: () {
              Navigator.pop(context);
              _openGeneralChat();
            },
          ),
        ]),
      ),
    );
  }

  void _showUserSelection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeService.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Selecionar usuário', style: TextStyle(color: ThemeService.textColor, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _database.child('users').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || (snapshot.data!.snapshot.value == null)) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final usersMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                final users = usersMap.entries.where((e) => e.key != currentUser?.uid).toList();

                return ListView.builder(
                  controller: controller,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userEntry = users[index];
                    final userId = userEntry.key;
                    final userData = Map<String, dynamic>.from(userEntry.value);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1877F2),
                        backgroundImage: userData['photoURL'] != null && userData['photoURL'] != ''
                            ? NetworkImage(userData['photoURL'])
                            : null,
                        child: userData['photoURL'] == null || userData['photoURL'] == ''
                            ? Text((userData['name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                      title: Text(userData['name'] ?? 'Usuário', style: TextStyle(color: ThemeService.textColor)),
                      subtitle: Text(userData['email'] ?? '', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6))),
                      onTap: () async {
                        Navigator.pop(context);
                        await _createDirectChat(userId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future _createDirectChat(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatsSnapshot = await _database.child('chats').once();
      
      if (chatsSnapshot.snapshot.value != null) {
        final chatsMap = Map<String, dynamic>.from(chatsSnapshot.snapshot.value as Map);
        
        for (var entry in chatsMap.entries) {
          final chat = Map<String, dynamic>.from(entry.value);
          if (chat['type'] == 'direct') {
            final participants = Map<String, dynamic>.from(chat['participants'] ?? {});
            if (participants.containsKey(currentUser.uid) && participants.containsKey(otherUserId)) {
              final userSnapshot = await _database.child('users').child(otherUserId).once();
              final otherUser = userSnapshot.snapshot.value != null 
                  ? Map<String, dynamic>.from(userSnapshot.snapshot.value as Map)
                  : {'name': 'Usuário'};
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: entry.key,
                      chatName: otherUser['name'] ?? 'Usuário',
                      isChannel: false,
                    ),
                  ),
                );
              }
              return;
            }
          }
        }
      }

      final newChatRef = _database.child('chats').push();
      await newChatRef.set({
        'type': 'direct',
        'participants': {
          currentUser.uid: true,
          otherUserId: true,
        },
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      final userSnapshot = await _database.child('users').child(otherUserId).once();
      final otherUser = userSnapshot.snapshot.value != null
          ? Map<String, dynamic>.from(userSnapshot.snapshot.value as Map)
          : {'name': 'Usuário'};

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: newChatRef.key!,
              chatName: otherUser['name'] ?? 'Usuário',
              isChannel: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateChannel() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeService.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Criar Canal', style: TextStyle(color: ThemeService.textColor)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: ThemeService.textColor),
          decoration: InputDecoration(
            hintText: 'Nome do canal',
            hintStyle: TextStyle(color: ThemeService.textColor.withOpacity(0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) return;

              try {
                final channelRef = _database.child('chats').push();
                await channelRef.set({
                  'type': 'channel',
                  'name': nameController.text.trim(),
                  'participants': {currentUser.uid: true},
                  'lastMessage': '',
                  'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
                });

                Navigator.pop(context);
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: channelRef.key!,
                        chatName: nameController.text.trim(),
                        isChannel: true,
                      ),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar canal: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Criar', style: TextStyle(color: Color(0xFF1877F2))),
          ),
        ],
      ),
    );
  }

  Future _openGeneralChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final generalRef = _database.child('chats').child('general');
      final snapshot = await generalRef.once();

      if (!snapshot.snapshot.exists) {
        await generalRef.set({
          'type': 'channel',
          'name': 'Geral',
          'participants': {currentUser.uid: true},
          'lastMessage': '',
          'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
          'isGeneral': true,
        });
      } else {
        await generalRef.child('participants').child(currentUser.uid).set(true);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: 'general',
              chatName: 'Geral',
              isChannel: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir chat geral: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isChannel;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.chatName,
    required this.isChannel,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  Future _sendMessage({String? imageUrl}) async {
    if ((_controller.text.trim().isEmpty && imageUrl == null) || _sending) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      final messageRef = _database.child('chats').child(widget.chatId).child('messages').push();
      
      await messageRef.set({
        'text': _controller.text.trim(),
        'imageUrl': imageUrl,
        'userId': user.uid,
        'userName': user.displayName ?? 'Usuário',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await _database.child('chats').child(widget.chatId).update({
        'lastMessage': imageUrl != null ? '📷 Imagem' : _controller.text.trim(),
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
      if (image == null) return;

      setState(() => _sending = true);

      final user = _auth.currentUser;
      if (user == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
      final storageRef = _storage.ref().child('chat_images').child(widget.chatId).child(fileName);
      
      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await _sendMessage(imageUrl: downloadUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: ThemeService.backgroundColor.withOpacity(0.8),
              elevation: 0,
              systemOverlayStyle: ThemeService.isDarkMode 
                  ? SystemUiOverlayStyle.light 
                  : SystemUiOverlayStyle.dark,
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, color: ThemeService.textColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.chatName,
                style: TextStyle(color: ThemeService.textColor, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              actions: [
                if (widget.isChannel)
                  IconButton(
                    icon: Icon(CupertinoIcons.info, color: ThemeService.textColor),
                    onPressed: () {},
                  )
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        const SizedBox(height: 56),
        Expanded(
          child: StreamBuilder(
            stream: _database.child('chats').child(widget.chatId).child('messages').orderByChild('timestamp').onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || (snapshot.data!.snapshot.value == null)) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(CupertinoIcons.chat_bubble, size: 80, color: ThemeService.textColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Nenhuma mensagem ainda', style: TextStyle(color: ThemeService.textColor.withOpacity(0.6), fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Envie a primeira mensagem!', style: TextStyle(color: ThemeService.textColor.withOpacity(0.4), fontSize: 14)),
                  ]),
                );
              }

              final messagesMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              final messages = messagesMap.entries.toList()
                ..sort((a, b) {
                  final aTime = (Map<String, dynamic>.from(a.value))['timestamp'] ?? 0;
                  final bTime = (Map<String, dynamic>.from(b.value))['timestamp'] ?? 0;
                  return (bTime as num).compareTo(aTime as num);
                });

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageEntry = messages[index];
                  final message = Map<String, dynamic>.from(messageEntry.value);
                  final isMe = message['userId'] == user?.uid;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && widget.isChannel)
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF1877F2),
                            child: Text(
                              (message['userName'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        if (!isMe && widget.isChannel) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe 
                                  ? const Color(0xFF1877F2) 
                                  : ThemeService.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe && widget.isChannel)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      message['userName'] ?? 'Usuário',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: ThemeService.isDarkMode ? Colors.white70 : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                if (message['imageUrl'] != null && message['imageUrl'] != '')
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      message['imageUrl'],
                                      width: 200,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          width: 200,
                                          height: 150,
                                          color: Colors.grey[300],
                                          child: const Center(child: CircularProgressIndicator()),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 200,
                                          height: 150,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  ),
                                if (message['text'] != null && message['text'].toString().isNotEmpty)
                                  Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: isMe 
                                          ? Colors.white 
                                          : ThemeService.isDarkMode ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeService.backgroundColor,
            border: Border(
              top: BorderSide(
                color: ThemeService.isDarkMode 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(children: [
              IconButton(
                icon: Icon(CupertinoIcons.photo, color: ThemeService.textColor),
                onPressed: _sending ? null : _pickImage,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: ThemeService.textColor),
                    decoration: InputDecoration(
                      hintText: 'Mensagem...',
                      hintStyle: TextStyle(color: ThemeService.textColor.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_sending,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1877F2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(CupertinoIcons.arrow_up, color: Colors.white),
                  onPressed: _sending ? null : _sendMessage,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
