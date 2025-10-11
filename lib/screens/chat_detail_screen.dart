import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientImage;

  const ChatDetailScreen({
    required this.recipientId,
    required this.recipientName,
    required this.recipientImage,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  Map<String, dynamic>? _userData;
  Map<String, DateTime> _editableMessages = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initConversation();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  Future<void> _initConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final conversationQuery = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in conversationQuery.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(widget.recipientId)) {
        setState(() => _conversationId = doc.id);
        return;
      }
    }

    // Create new conversation
    final newConv = await FirebaseFirestore.instance.collection('conversations').add({
      'participants': [currentUser.uid, widget.recipientId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount_${currentUser.uid}': 0,
      'unreadCount_${widget.recipientId}': 0,
    });

    setState(() => _conversationId = newConv.id);
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _conversationId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    
    // Check tokens
    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tokens insuficientes'), backgroundColor: Colors.red),
        );
        return;
      }
      
      // Decrease token
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'tokens': FieldValue.increment(-1),
      });
    }

    final messageText = _controller.text.trim();
    _controller.clear();

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': currentUser.uid,
      'senderName': _userData?['username'] ?? 'Usuário',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
      'edited': false,
    });

    await FirebaseFirestore.instance.collection('conversations').doc(_conversationId).update({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount_${widget.recipientId}': FieldValue.increment(1),
    });

    _scrollToBottom();
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

  Future<void> _likeMessage(String messageId, List likedBy) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    
    if (likedBy.contains(currentUser.uid)) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        'likes': FieldValue.increment(1),
      });
    }
  }

  Future<void> _editMessage(String messageId, String currentText, DateTime timestamp) async {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não é possível editar após 5 minutos'), backgroundColor: Colors.red),
      );
      return;
    }

    final controller = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Mensagem'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Digite a nova mensagem',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(_conversationId)
                    .collection('messages')
                    .doc(messageId)
                    .update({
                  'text': controller.text.trim(),
                  'edited': true,
                });
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    List<InlineSpan> spans = [];

    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(word);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 15,
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
              fontSize: 15,
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
              fontSize: 15,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
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
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFF444F),
              backgroundImage: widget.recipientImage.isNotEmpty ? NetworkImage(widget.recipientImage) : null,
              child: widget.recipientImage.isEmpty
                  ? Text(
                      widget.recipientName[0].toUpperCase(),
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.recipientId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      final isOnline = userData?['isOnline'] == true;
                      return Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _conversationId == null
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)))
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://alfredoooh.github.io/database/gallery/image_background.jpg'),
                  fit: BoxFit.cover,
                  opacity: isDark ? 0.05 : 0.03,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(_conversationId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhuma mensagem ainda',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        final messages = snapshot.data!.docs;

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final messageDoc = messages[index];
                            final message = messageDoc.data() as Map<String, dynamic>;
                            final isMe = message['senderId'] == currentUser.uid;
                            final timestamp = message['timestamp'] as Timestamp?;
                            final likes = message['likes'] ?? 0;
                            final likedBy = List.from(message['likedBy'] ?? []);
                            final isLiked = likedBy.contains(currentUser.uid);
                            final isEdited = message['edited'] == true;

                            if (timestamp == null) return SizedBox.shrink();

                            return GestureDetector(
                              onLongPress: () {
                                if (isMe) {
                                  _editMessage(messageDoc.id, message['text'], timestamp.toDate());
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? Color(0xFFFF444F) : (isDark ? Color(0xFF1A1A1A) : Colors.white),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(18),
                                            topRight: Radius.circular(18),
                                            bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                                            bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildMessageText(message['text'] ?? '', isMe),
                                            if (isEdited)
                                              Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'editado',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMe ? Colors.white70 : Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            if (likes > 0)
                                              Padding(
                                                padding: EdgeInsets.only(top: 6),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                      size: 14,
                                                      color: isMe ? Colors.white : Colors.red,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '$likes',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _likeMessage(messageDoc.id, likedBy),
                                      child: Icon(
                                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        size: 20,
                                        color: isLiked ? Colors.red : Colors.grey,
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
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
                          SizedBox(width: 12),
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
