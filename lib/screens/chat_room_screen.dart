// chat_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatRoomScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientImage;
  final bool isOnline;
  final String? chatId;

  ChatRoomScreen({
    required this.recipientId,
    required this.recipientName,
    this.recipientImage,
    required this.isOnline,
    this.chatId,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentChatId;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadUserData();
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

  Future<void> _initializeChat() async {
    if (widget.chatId != null) {
      setState(() {
        _currentChatId = widget.chatId;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Procurar chat existente
    final existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in existingChat.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(widget.recipientId)) {
        setState(() {
          _currentChatId = doc.id;
        });
        return;
      }
    }

    // Criar novo chat
    final newChat = await FirebaseFirestore.instance.collection('chats').add({
      'participants': [user.uid, widget.recipientId],
      'created_at': FieldValue.serverTimestamp(),
      'last_message': '',
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_${user.uid}': 0,
      'unread_${widget.recipientId}': 0,
    });

    setState(() {
      _currentChatId = newChat.id;
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _currentChatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Verificar tokens
    if (_userData?['isPro'] != true) {
      final tokens = _userData?['tokens'] ?? 0;
      if (tokens <= 0) {
        _showErrorDialog('Tokens insuficientes',
            'Você não tem tokens suficientes. Upgrade para PRO para tokens ilimitados.');
        return;
      }
      // Deduzir token
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'tokens': FieldValue.increment(-1)});
    }

    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'text': messageText,
        'sender_id': user.uid,
        'sender_name': _userData?['full_name'] ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
        'likes': 0,
        'dislikes': 0,
      });

      // Atualizar chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_currentChatId)
          .update({
        'last_message': messageText,
        'last_message_time': FieldValue.serverTimestamp(),
        'unread_${widget.recipientId}': FieldValue.increment(1),
      });

      _scrollToBottom();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

  void _showMessageOptions(String messageId, Map<String, dynamic> messageData) {
    final user = FirebaseAuth.instance.currentUser;
    final isMyMessage = messageData['sender_id'] == user?.uid;
    final timestamp = messageData['timestamp'] as Timestamp?;
    final canEdit = timestamp != null &&
        DateTime.now().difference(timestamp.toDate()).inMinutes < 5;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (isMyMessage && canEdit)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editMessage(messageId, messageData['text']);
              },
              child: Text('Editar'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _reactToMessage(messageId, 'like');
            },
            child: Text('👍 Curtir'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _reactToMessage(messageId, 'dislike');
            },
            child: Text('👎 Não curtir'),
          ),
          if (isMyMessage || _userData?['isAdmin'] == true)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
              isDestructiveAction: true,
              child: Text('Excluir'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _editMessage(String messageId, String currentText) async {
    final controller = TextEditingController(text: currentText);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Editar Mensagem'),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(_currentChatId)
                    .collection('messages')
                    .doc(messageId)
                    .update({
                  'text': controller.text.trim(),
                  'edited': true,
                });
              }
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactToMessage(String messageId, String reaction) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages')
        .doc(messageId)
        .update({
      '${reaction}s': FieldValue.increment(1),
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_currentChatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Widget _buildMessageText(String text, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);

    List<InlineSpan> spans = [];
    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(word)),
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      } else if (word.startsWith('*') && word.endsWith('*') && word.length > 2) {
        spans.add(
          TextSpan(
            text: word.substring(1, word.length - 1) + ' ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              fontSize: 16,
            ),
          ),
        );
      }
    });

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (_currentChatId == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.recipientName),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

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
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    widget.recipientImage ??
                        'https://alfredoooh.github.io/database/gallery/app_icon.png',
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
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
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF0E0E0E),
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://alfredoooh.github.io/database/gallery/image_background.jpg',
                ),
                fit: BoxFit.cover,
                opacity: 0.05,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_currentChatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar mensagens',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CupertinoActivityIndicator());
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Envie a primeira mensagem!',
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
                        final messageDoc = messages[index];
                        final message = messageDoc.data() as Map<String, dynamic>;
                        final isMe = message['sender_id'] == user?.uid;

                        if (message['timestamp'] == null) {
                          return SizedBox.shrink();
                        }

                        return GestureDetector(
                          onLongPress: () => _showMessageOptions(
                            messageDoc.id,
                            message,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) SizedBox(width: 8),
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
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomLeft: isMe
                                            ? Radius.circular(18)
                                            : Radius.circular(4),
                                        bottomRight: isMe
                                            ? Radius.circular(4)
                                            : Radius.circular(18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildMessageText(
                                          message['text'] ?? '',
                                          isMe,
                                        ),
                                        if (message['edited'] == true)
                                          Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              'editado',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: isMe
                                                    ? Colors.white70
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        if ((message['likes'] ?? 0) > 0 ||
                                            (message['dislikes'] ?? 0) > 0)
                                          Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if ((message['likes'] ?? 0) > 0)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '👍',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '${message['likes']}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isMe
                                                              ? Colors.white70
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if ((message['likes'] ?? 0) >
                                                        0 &&
                                                    (message['dislikes'] ?? 0) >
                                                        0)
                                                  SizedBox(width: 8),
                                                if ((message['dislikes'] ?? 0) >
                                                    0)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '👎',
                                                        style: TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '${message['dislikes']}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isMe
                                                              ? Colors.white70
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) SizedBox(width: 8),
                              ],
                            ),
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
                          textInputAction: TextInputAction.newline,
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