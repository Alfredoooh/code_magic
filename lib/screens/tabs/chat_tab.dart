import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/theme_service.dart';
import '../profile_screen.dart';

class ChatTab extends StatefulWidget {
  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Chats',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.person_circle, color: ThemeService.textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.add, color: ThemeService.textColor),
            onPressed: () => _showNewChatDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1877F2),
          labelColor: const Color(0xFF1877F2),
          unselectedLabelColor: ThemeService.textColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Diretas'),
            Tab(text: 'Canais'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectMessages(user),
          _buildChannels(user),
        ],
      ),
    );
  }

  Widget _buildDirectMessages(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'direct')
          .where('participants', arrayContains: user?.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!.docs;

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_2,
                  size: 80,
                  color: ThemeService.textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index].data() as Map<String, dynamic>;
            final chatId = chats[index].id;
            final otherUserId = (chat['participants'] as List)
                .firstWhere((id) => id != user?.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return Container();

                final otherUser = userSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1877F2),
                    backgroundImage: otherUser['photoURL'] != null && otherUser['photoURL'] != ''
                        ? NetworkImage(otherUser['photoURL'])
                        : null,
                    child: otherUser['photoURL'] == null || otherUser['photoURL'] == ''
                        ? Text(
                            (otherUser['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    otherUser['name'] ?? 'Usuário',
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    chat['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.6),
                    ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'channel')
          .where('participants', arrayContains: user?.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final channels = snapshot.data!.docs;

        if (channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.group,
                  size: 80,
                  color: ThemeService.textColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum canal ainda',
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index].data() as Map<String, dynamic>;
            final channelId = channels[index].id;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1877F2),
                child: Icon(
                  CupertinoIcons.group_solid,
                  color: Colors.white,
                ),
              ),
              title: Text(
                channel['name'] ?? 'Canal',
                style: TextStyle(
                  color: ThemeService.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                channel['lastMessage'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ThemeService.textColor.withOpacity(0.6),
                ),
              ),
              trailing: Text(
                '${(channel['participants'] as List).length} membros',
                style: TextStyle(
                  color: ThemeService.textColor.withOpacity(0.5),
                  fontSize: 12,
                ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.person, color: Color(0xFF1877F2)),
              title: Text(
                'Nova Mensagem Direta',
                style: TextStyle(color: ThemeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUserSelection(false);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.group, color: Color(0xFF1877F2)),
              title: Text(
                'Criar Canal',
                style: TextStyle(color: ThemeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreateChannel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSelection(bool isChannel) {
    // Implementar seleção de usuários
  }

  void _showCreateChannel() {
    // Implementar criação de canal
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_controller.text.trim().isEmpty && imageUrl == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': _controller.text.trim(),
      'imageUrl': imageUrl,
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuário',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(widget.chatId).update({
      'lastMessage': imageUrl != null ? '📷 Imagem' : _controller.text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Aqui você implementaria o upload para Firebase Storage
      // Por enquanto, enviamos com URL local
      _sendMessage(imageUrl: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: ThemeService.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.chatName,
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.isChannel)
            IconButton(
              icon: Icon(CupertinoIcons.info, color: ThemeService.textColor),
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble,
                          size: 80,
                          color: ThemeService.textColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(
                            color: ThemeService.textColor.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['userId'] == user?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe && widget.isChannel)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1877F2),
                              child: Text(
                                (message['userName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (!isMe && widget.isChannel) const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF1877F2)
                                    : ThemeService.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
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
                                          color: ThemeService.isDarkMode
                                              ? Colors.white70
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  if (message['imageUrl'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(message['imageUrl']),
                                        width: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (message['text'] != null &&
                                      message['text'].toString().isNotEmpty)
                                    Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : ThemeService.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
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
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.photo,
                      color: ThemeService.textColor,
                    ),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ThemeService.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: ThemeService.textColor),
                        decoration: InputDecoration(
                          hintText: 'Mensagem...',
                          hintStyle: TextStyle(
                            color: ThemeService.textColor.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
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
                      icon: const Icon(CupertinoIcons.arrow_up, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
