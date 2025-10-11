// screens/group_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupImage;

  GroupChatScreen({
    required this.groupId,
    required this.groupName,
    this.groupImage,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _joinGroup();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_userData?['isPro'] != true) {
      final tokens = _userData?['tokens'] ?? 0;
      if (tokens <= 0) {
        _showErrorDialog('Tokens insuficientes',
            'Você precisa ser PRO ou ter tokens para enviar mensagens.');
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'tokens': FieldValue.increment(-1)});
    }

    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': messageText,
        'sender_id': user.uid,
        'sender_name': _userData?['full_name'] ?? 'Usuário',
        'sender_image': _userData?['profile_image'],
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
      });
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
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
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                widget.groupImage ??
                    'https://alfredoooh.github.io/database/gallery/app_icon.png',
              ),
            ),
            SizedBox(width: 8),
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CupertinoActivityIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: 80,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            messages[index].data() as Map<String, dynamic>;
                        final isMe = message['sender_id'] == user?.uid;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                    message['sender_image'] ??
                                        'https://alfredoooh.github.io/database/gallery/app_icon.png',
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Color(0xFFFF444F)
                                        : isDark
                                            ? Color(0xFF1C1C1E)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          message['sender_name'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF444F),
                                          ),
                                        ),
                                      Text(
                                        message['text'] ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : isDark
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
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Color(0xFF1C1C1E).withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Color(0xFF38383A) : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: isDark ? Colors.white : Color(0xFF0E0E0E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mensagem',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
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
    _scrollController.dispose();
    super.dispose();
  }
}