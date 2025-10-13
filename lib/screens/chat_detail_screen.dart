// lib/screens/chat_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Key? key,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  static const int FREE_LIMIT = 20;
  static const int PRO_LIMIT = 1000;

  @override
  void initState() {
    super.initState();
    _initializeChat();
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
        print('Erro ao carregar dados do usuário: $e');
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
      print('Erro ao atualizar dados do usuário: $e');
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
      print('Erro ao inicializar conversa: $e');
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
          .update({
        'unreadCount_${currentUser.uid}': 0,
      });
    } catch (e) {
      print('Erro ao marcar como lido: $e');
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
      if (date != _todayString()) {
        return 0;
      }
      return count;
    } catch (e) {
      print('Erro ao obter contador diário: $e');
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
          count += 1;
          tx.update(ref, {'messagesSentToday': count});
        }
      });
      await _refreshUserData();
    } catch (e) {
      print('Erro ao incrementar contador diário: $e');
    }
  }

  Future<bool> _canSendMessageAndMaybeWarn() async {
    await _refreshUserData();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final isPro = _userData?['pro'] == true;
    final limit = isPro ? PRO_LIMIT : FREE_LIMIT;
    final sentToday = await _getUserMessagesSentToday();

    if (sentToday >= limit) {
      _showToast('Você atingiu o limite diário de $limit mensagens.');
      return false;
    }

    return true;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final canSend = await _canSendMessageAndMaybeWarn();
    if (!canSend) return;

    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        _showToast('Tokens insuficientes');
        return;
      } else {
        try {
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'tokens': FieldValue.increment(-1),
          });
          if (_userData != null) {
            _userData!['tokens'] = (_userData!['tokens'] ?? 0) - 1;
          }
        } catch (e) {
          print('Erro ao decrementar tokens: $e');
        }
      }
    }

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
      final sentAfter = await _getUserMessagesSentToday();
      final isPro = _userData?['pro'] == true;
      final limit = isPro ? PRO_LIMIT : FREE_LIMIT;
      if (sentAfter >= limit) {
        _showToast('Você atingiu o limite diário de $limit mensagens.');
      }

      _scrollToBottom();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      _showToast('Erro ao enviar mensagem');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          try {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } catch (e) {
            _scrollController.jumpTo(0);
          }
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
      print('Erro ao curtir mensagem: $e');
    }
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _editMessage(String messageId, String currentText, DateTime timestamp) async {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes > 5) {
      _showToast('Não é possível editar após 5 minutos');
      return;
    }

    final controller = TextEditingController(text: currentText);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Editar Mensagem'),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 3,
            placeholder: 'Digite a nova mensagem',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                  Navigator.pop(context);
                } catch (e) {
                  print('Erro ao editar mensagem: $e');
                }
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Excluir Mensagem'),
        content: Text('Tem certeza que deseja excluir esta mensagem?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(_conversationId)
                    .collection('messages')
                    .doc(messageId)
                    .delete();
                Navigator.pop(context);
              } catch (e) {
                print('Erro ao excluir mensagem: $e');
              }
            },
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(String messageId, String messageText, DateTime timestamp, bool isMe) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Opções da Mensagem'),
        actions: [
          if (isMe) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editMessage(messageId, messageText, timestamp);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, color: Color(0xFFFF444F)),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Color(0xFFFF444F))),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.delete),
                  SizedBox(width: 8),
                  Text('Excluir'),
                ],
              ),
            ),
          ],
          CupertinoActionSheetAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: messageText));
              Navigator.pop(context);
              _showToast('Mensagem copiada');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_clipboard, color: Color(0xFFFF444F)),
                SizedBox(width: 8),
                Text('Copiar', style: TextStyle(color: Color(0xFFFF444F))),
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

  Widget _buildMessageText(String text, bool isMe, bool isDark) {
    final urlPattern = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    List<InlineSpan> spans = [];

    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () async {
                try {
                  final uri = Uri.parse(word);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  print('Erro ao abrir URL: $e');
                }
              },
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: isMe ? CupertinoColors.white : CupertinoColors.activeBlue,
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
              color: isMe ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
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
              color: isMe ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        child: Center(
          child: CupertinoActivityIndicator(radius: 15),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, color: Color(0xFFFF444F), size: 28),
              Text(
                'Voltar',
                style: TextStyle(color: Color(0xFFFF444F), fontSize: 17),
              ),
            ],
          ),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF444F),
              ),
              child: widget.recipientImage.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.recipientImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            widget.recipientName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.recipientName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                        fontSize: 11,
                        color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      child: _conversationId == null
          ? Center(child: CupertinoActivityIndicator(radius: 15))
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
                        return Center(child: CupertinoActivityIndicator(radius: 15));
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
                                'Nenhuma mensagem ainda',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Color(0xFFFF444F)
                                            : (isDark ? Color(0xFF1A1A1A) : CupertinoColors.white),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                          bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                                          bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
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
                                                  color: isMe
                                                      ? CupertinoColors.white.withOpacity(0.7)
                                                      : CupertinoColors.systemGrey,
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
                                                    isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                                    size: 14,
                                                    color: isMe ? CupertinoColors.white : CupertinoColors.systemRed,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$likes',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isMe
                                                          ? CupertinoColors.white
                                                          : (isDark ? CupertinoColors.white : CupertinoColors.black),
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
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _likeMessage(messageDoc.id, likedBy);
                                    },
                                    child: Icon(
                                      isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                      size: 20,
                                      color: isLiked ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Color(0xFF2C2C2C) : CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CupertinoTextField(
                              controller: _controller,
                              style: TextStyle(
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                fontSize: 16,
                              ),
                              maxLines: null,
                              placeholder: 'Mensagem',
                              placeholderStyle: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 16,
                              ),
                              decoration: BoxDecoration(),
                              padding: EdgeInsets.zero,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _sendMessage();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF444F),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
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