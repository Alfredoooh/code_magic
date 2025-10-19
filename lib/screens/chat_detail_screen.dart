import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientImage;

  const ChatDetailScreen({
    required this.recipientId,
    required this.recipientName,
    required this.recipientImage,
    Key? key,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? _conversationId;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSending = false;

  static const int FREE_LIMIT = 20;
  static const int PRO_LIMIT = 1000;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _loadUserData();
    await _initConversation();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() => _userData = doc.data());
        }
      } catch (e) {
        print('❌ Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _refreshUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) setState(() => _userData = doc.data());
    } catch (e) {
      print('❌ Erro ao atualizar dados: $e');
    }
  }

  Future<void> _initConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientId)
          .get();
      if (!recipientDoc.exists) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final conversationQuery = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (var doc in conversationQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(widget.recipientId) && participants.length == 2) {
          if (mounted) setState(() => _conversationId = doc.id);
          _markAsRead();
          return;
        }
      }

      final newConv = await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [currentUser.uid, widget.recipientId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${currentUser.uid}': 0,
        'unreadCount_${widget.recipientId}': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) setState(() => _conversationId = newConv.id);
    } catch (e) {
      print('❌ Erro ao inicializar conversa: $e');
    }
  }

  Future<void> _markAsRead() async {
    if (_conversationId == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .update({'unreadCount_${currentUser.uid}': 0});
    } catch (e) {
      print('❌ Erro ao marcar como lido: $e');
    }
  }

  String _todayString() {
    final now = DateTime.now().toUtc();
    return now.toIso8601String().split('T').first;
  }

  Future<int> _getUserMessagesSentToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return 0;
      final data = doc.data();
      if (data == null) return 0;
      final date = data['messagesSentAt'] as String? ?? '';
      final count = (data['messagesSentToday'] ?? 0) as int;
      if (date != _todayString()) return 0;
      return count;
    } catch (e) {
      print('❌ Erro ao obter contador: $e');
      return 0;
    }
  }

  Future<void> _incrementUserMessagesSent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = _todayString();
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) {
          tx.set(ref, {'messagesSentToday': 1, 'messagesSentAt': today});
          return;
        }
        final data = snapshot.data()!;
        final date = (data['messagesSentAt'] as String?) ?? '';
        int count = (data['messagesSentToday'] ?? 0) as int;
        if (date != today) {
          tx.update(ref, {'messagesSentToday': 1, 'messagesSentAt': today});
        } else {
          tx.update(ref, {'messagesSentToday': count + 1});
        }
      });
      await _refreshUserData();
    } catch (e) {
      print('❌ Erro ao incrementar contador: $e');
    }
  }

  Future<bool> _canSendMessage() async {
    await _refreshUserData();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final isPro = _userData?['pro'] == true;
    final limit = isPro ? PRO_LIMIT : FREE_LIMIT;
    final sentToday = await _getUserMessagesSentToday();

    if (sentToday >= limit) {
      AppDialogs.showError(context, 'Limite atingido', 'Você atingiu o limite diário de $limit mensagens.');
      return false;
    }

    return true;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId == null || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final canSend = await _canSendMessage();
    if (!canSend) return;

    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        AppDialogs.showError(context, 'Tokens insuficientes', 'Você não tem tokens suficientes para enviar mensagens.');
        return;
      }
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'tokens': FieldValue.increment(-1),
        });
        if (_userData != null) _userData!['tokens'] = (_userData!['tokens'] ?? 0) - 1;
      } catch (e) {
        print('❌ Erro ao decrementar tokens: $e');
      }
    }

    setState(() => _isSending = true);
    final messageText = text;
    _controller.clear();

    try {
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

      await _incrementUserMessagesSent();
      _scrollToBottom();
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      AppDialogs.showError(context, 'Erro', 'Não foi possível enviar a mensagem.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  Future<void> _likeMessage(String messageId, List likedBy) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _conversationId == null) return;

    try {
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
    } catch (e) {
      print('❌ Erro ao curtir: $e');
    }
  }

  void _editMessage(String messageId, String currentText, DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes > 5) {
      AppDialogs.showError(context, 'Tempo excedido', 'Não é possível editar após 5 minutos.');
      return;
    }

    final controller = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Mensagem'),
        content: AppTextField(
          controller: controller,
          hintText: 'Digite a nova mensagem',
          maxLines: 3,
        ),
        actions: [
          AppSecondaryButton(
            text: 'Cancelar',
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
          ),
          AppPrimaryButton(
            text: 'Salvar',
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(_conversationId)
                      .collection('messages')
                      .doc(messageId)
                      .update({
                    'text': controller.text.trim(),
                    'edited': true,
                  });
                  controller.dispose();
                  Navigator.pop(context);
                } catch (e) {
                  print('❌ Erro ao editar: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) {
    AppDialogs.showConfirmation(
      context,
      'Excluir Mensagem',
      'Tem certeza que deseja excluir esta mensagem?',
      onConfirm: () async {
        try {
          await FirebaseFirestore.instance
              .collection('conversations')
              .doc(_conversationId)
              .collection('messages')
              .doc(messageId)
              .delete();
        } catch (e) {
          print('❌ Erro ao excluir: $e');
        }
      },
      isDestructive: true,
    );
  }

  void _showMessageOptions(String messageId, String messageText, DateTime timestamp, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                if (isMe) ...[
                  ListTile(
                    leading: Icon(Icons.edit, color: AppColors.primary),
                    title: Text('Editar'),
                    onTap: () {
                      Navigator.pop(context);
                      _editMessage(messageId, messageText, timestamp);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Excluir', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(messageId);
                    },
                  ),
                ],
                ListTile(
                  leading: Icon(Icons.copy, color: AppColors.primary),
                  title: Text('Copiar'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: messageText));
                    Navigator.pop(context);
                    AppDialogs.showSuccess(context, 'Copiado', 'Mensagem copiada!');
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageText(String text, bool isMe, bool isDark) {
    final urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    List<InlineSpan> spans = [];

    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(WidgetSpan(
          child: GestureDetector(
            onTap: () async {
              try {
                final uri = Uri.parse(word);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                print('❌ Erro ao abrir URL: $e');
              }
            },
            child: Text(
              word + ' ',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.blue,
                decoration: TextDecoration.underline,
                fontSize: 16,
              ),
            ),
          ),
        ));
      } else if (word.startsWith('*') && word.endsWith('*') && word.length > 2) {
        spans.add(TextSpan(
          text: word.substring(1, word.length - 1) + ' ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
          ),
        ));
      } else if (word.startsWith('_') && word.endsWith('_') && word.length > 2) {
        spans.add(TextSpan(
          text: word.substring(1, word.length - 1) + ' ',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: word + ' ',
          style: TextStyle(
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
          ),
        ));
      }
    });

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: widget.recipientName,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.recipientId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox.shrink();
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final isOnline = userData?['isOnline'] == true;
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _conversationId == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
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
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Nenhuma mensagem ainda', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                          final isMe = message['senderId'] == currentUser?.uid;
                          final timestamp = message['timestamp'] as Timestamp?;
                          final likes = message['likes'] ?? 0;
                          final likedBy = List.from(message['likedBy'] ?? []);
                          final isLiked = likedBy.contains(currentUser?.uid);
                          final isEdited = message['edited'] == true;

                          if (timestamp == null) return SizedBox.shrink();

                          return GestureDetector(
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _showMessageOptions(messageDoc.id, message['text'], timestamp.toDate(), isMe);
                            },
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _likeMessage(messageDoc.id, likedBy);
                                      },
                                      child: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        size: 20,
                                        color: isLiked ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                          bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                                          bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildMessageText(message['text'] ?? '', isMe, isDark),
                                          if (isEdited)
                                            Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                'editado',
                                                style: TextStyle(
                                                  fontSize: 11,
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
                                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                                    size: 14,
                                                    color: isMe ? Colors.white : Colors.red,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$likes',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _likeMessage(messageDoc.id, likedBy);
                                      },
                                      child: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        size: 20,
                                        color: isLiked ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // INPUT FLUTUANTE
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Mensagem',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _sendMessage();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isSending ? Colors.grey : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isSending
                              ? Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}