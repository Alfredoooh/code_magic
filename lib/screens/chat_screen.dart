import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;
  final String? recipientId;

  const ChatScreen({
    required this.chatId,
    required this.chatName,
    required this.isGroup,
    this.recipientId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _editingMessageId;
  bool _isRecipientOnline = false;

  @override
  void initState() {
    super.initState();
    _createChatIfNotExists();
    if (!widget.isGroup && widget.recipientId != null) {
      _checkRecipientStatus();
    }
  }

  void _checkRecipientStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.recipientId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _isRecipientOnline = snapshot.data()?['online'] ?? false;
        });
      }
    });
  }

  Future<void> _createChatIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.isGroup) return;

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    
    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'participants': [user.uid, widget.recipientId],
        'created_at': FieldValue.serverTimestamp(),
        'last_message': '',
        'last_message_time': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> _checkTokensAndPro() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    if (userData['is_pro'] == true) return true;

    final tokens = userData['tokens'] ?? 0;
    if (tokens <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você não tem tokens suficientes. Upgrade para PRO para tokens ilimitados.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Deduzir 1 token
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'tokens': FieldValue.increment(-1),
    });

    return true;
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Verificar tokens
    final canSend = await _checkTokensAndPro();
    if (!canSend) return;

    try {
      final collection = widget.isGroup ? 'groups' : 'chats';
      final messageData = {
        'text': _controller.text.trim(),
        'userId': user.uid,
        'userName': user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
        'likes': 0,
        'dislikes': 0,
      };

      if (_editingMessageId != null) {
        // Editar mensagem
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.chatId)
            .collection('messages')
            .doc(_editingMessageId)
            .update({
          'text': _controller.text.trim(),
          'edited': true,
          'edited_at': FieldValue.serverTimestamp(),
        });
        setState(() => _editingMessageId = null);
      } else {
        // Nova mensagem
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.chatId)
            .collection('messages')
            .add(messageData);

        // Atualizar último mensagem
        if (!widget.isGroup) {
          await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
            'last_message': _controller.text.trim(),
            'last_message_time': FieldValue.serverTimestamp(),
          });
        }
      }

      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e'), backgroundColor: Colors.red),
      );
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

  void _editMessage(String messageId, String currentText) {
    setState(() {
      _editingMessageId = messageId;
      _controller.text = currentText;
    });
  }

  void _deleteMessage(String messageId) async {
    final collection = widget.isGroup ? 'groups' : 'chats';
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  void _reactToMessage(String messageId, bool isLike) async {
    final collection = widget.isGroup ? 'groups' : 'chats';
    final field = isLike ? 'likes' : 'dislikes';
    
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      field: FieldValue.increment(1),
    });
  }

  bool _canEdit(Timestamp? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);
    return difference.inMinutes < 5;
  }

  void _showMessageOptions(String messageId, String text, String userId, Timestamp? timestamp) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyMessage = userId == currentUser?.uid;

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
              SizedBox(height: 16),
              if (isMyMessage && _canEdit(timestamp))
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: Color(0xFFFF444F)),
                  title: Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(messageId, text);
                  },
                ),
              if (isMyMessage)
                ListTile(
                  leading: Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text('Excluir', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(messageId);
                  },
                ),
              ListTile(
                leading: Icon(Icons.thumb_up_rounded, color: Colors.blue),
                title: Text('Curtir'),
                onTap: () {
                  Navigator.pop(context);
                  _reactToMessage(messageId, true);
                },
              ),
              ListTile(
                leading: Icon(Icons.thumb_down_rounded, color: Colors.red),
                title: Text('Não curtir'),
                onTap: () {
                  Navigator.pop(context);
                  _reactToMessage(messageId, false);
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe) {
    final urlPattern = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );

    List<InlineSpan> spans = [];
    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _launchURL(word),
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
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
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      } else if (word.startsWith('_') && word.endsWith('_') && word.length > 2) {
        spans.add(
          TextSpan(
            text: word.substring(1, word.length - 1) + ' ',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      }
    });

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (!widget.isGroup)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFF444F),
                    child: Text(
                      widget.chatName[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_isRecipientOnline)
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
            if (widget.isGroup)
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFF444F),
                child: Icon(Icons.group_rounded, color: Colors.white, size: 20),
              ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (!widget.isGroup)
                    Text(
                      _isRecipientOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isRecipientOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            onPressed: () {
              // Opções do chat
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.isGroup ? 'groups' : 'chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar mensagens', style: TextStyle(color: Colors.red)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma mensagem ainda',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final isMe = message['userId'] == user?.uid;

                    if (message['timestamp'] == null) {
                      return SizedBox.shrink();
                    }

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(
                        messageDoc.id,
                        message['text'] ?? '',
                        message['userId'],
                        message['timestamp'],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe && widget.isGroup)
                              CircleAvatar(
                                backgroundColor: Color(0xFFFF444F),
                                radius: 16,
                                child: Text(
                                  (message['userName'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (!isMe && widget.isGroup) SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Color(0xFFFF444F) : (isDark ? Color(0xFF1A1A1A) : Colors.grey[200]),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe && widget.isGroup)
                                      Text(
                                        message['userName'] ?? 'Usuário',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFFFF444F),
                                        ),
                                      ),
                                    if (!isMe && widget.isGroup) SizedBox(height: 4),
                                    _buildMessageText(message['text'] ?? '', isMe),
                                    if (message['edited'] == true)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'editado',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: isMe ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    if ((message['likes'] ?? 0) > 0 || (message['dislikes'] ?? 0) > 0)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if ((message['likes'] ?? 0) > 0) ...[
                                              Icon(Icons.thumb_up_rounded, size: 12, color: isMe ? Colors.white70 : Colors.blue),
                                              SizedBox(width: 4),
                                              Text(
                                                '${message['likes']}',
                                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                              ),
                                              SizedBox(width: 12),
                                            ],
                                            if ((message['dislikes'] ?? 0) > 0) ...[
                                              Icon(Icons.thumb_down_rounded, size: 12, color: isMe ? Colors.white70 : Colors.red),
                                              SizedBox(width: 4),
                                              Text(
                                                '${message['dislikes']}',
                                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) SizedBox(width: 8),
                            if (isMe)
                              CircleAvatar(
                                backgroundColor: Color(0xFFFF444F),
                                radius: 16,
                                child: Text(
                                  (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_editingMessageId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 16, color: Color(0xFFFF444F)),
                  SizedBox(width: 8),
                  Text('Editando mensagem', style: TextStyle(color: Color(0xFFFF444F))),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        _editingMessageId = null;
                        _controller.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Color(0xFF2C2C2C) : Color(0xFFE0E0E0), width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Mensagem',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
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
                      icon: Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
    _scrollController.dispose();
    super.dispose();
  }
}