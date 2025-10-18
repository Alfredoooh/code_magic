// lib/screens/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui_components.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    required this.groupId,
    required this.groupName,
    Key? key,
  }) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeGroup();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeGroup() async {
    await _loadUserData();
    await _loadGroupData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) setState(() => _userData = doc.data());
      } catch (e) {
        print('❌ Erro ao carregar usuário: $e');
      }
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (doc.exists && mounted) setState(() => _groupData = doc.data());
    } catch (e) {
      print('❌ Erro ao carregar grupo: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_groupData != null) {
      final members = List.from(_groupData!['members'] ?? []);
      if (!members.contains(currentUser.uid)) {
        AppDialogs.showError(context, 'Erro', 'Você não é membro deste grupo');
        return;
      }
    }

    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        AppDialogs.showError(context, 'Tokens insuficientes', 'Você não tem tokens.');
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
    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUser.uid,
        'senderName': _userData?['username'] ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
      });

      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

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
                      .collection('groups')
                      .doc(widget.groupId)
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
              .collection('groups')
              .doc(widget.groupId)
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

  void _showGroupInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                AppIconCircle(icon: Icons.group, size: 80),
                SizedBox(height: 16),
                AppSectionTitle(text: widget.groupName, fontSize: 24),
                SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox.shrink();
                    final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                    final members = List.from(groupData?['members'] ?? []);
                    return Text(
                      '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MEMBROS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                final members = List<String>.from(groupData?['members'] ?? []);

                if (members.isEmpty) {
                  return Center(child: Text('Nenhum membro', style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: members.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(members[index]).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return SizedBox.shrink();
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final isOnline = userData['isOnline'] == true;
                        final isCreator = members[index] == groupData?['createdBy'];

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary,
                                backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                                    ? NetworkImage(userData['profile_image'])
                                    : null,
                                child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                                    ? Text(
                                        (userData['username'] ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      )
                                    : null,
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Text(userData['username'] ?? 'Usuário', style: TextStyle(fontWeight: FontWeight.w600)),
                              if (isCreator) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 13, color: isOnline ? Colors.green : Colors.grey)),
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
              style: TextStyle(color: isMe ? Colors.white : Colors.blue, decoration: TextDecoration.underline, fontSize: 16),
            ),
          ),
        ));
      } else if (word.startsWith('*') && word.endsWith('*') && word.length > 2) {
        spans.add(TextSpan(
          text: word.substring(1, word.length - 1) + ' ',
          style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 16),
        ));
      } else if (word.startsWith('_') && word.endsWith('_') && word.length > 2) {
        spans.add(TextSpan(
          text: word.substring(1, word.length - 1) + ' ',
          style: TextStyle(fontStyle: FontStyle.italic, color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 16),
        ));
      } else {
        spans.add(TextSpan(text: word + ' ', style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 16)));
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
        title: widget.groupName,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: Column(
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
                        Text('Nenhuma mensagem', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                    final isEdited = message['edited'] == true;

                    if (timestamp == null) return SizedBox.shrink();

                    return GestureDetector(
                      onLongPress: () {
                        if (isMe) {
                          HapticFeedback.mediumImpact();
                          _showMessageOptions(messageDoc.id, message['text'], timestamp.toDate(), isMe);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
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
                                    if (!isMe)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message['senderName'] ?? 'Usuário',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                                        ),
                                      ),
                                    _buildMessageText(message['text'] ?? '', isMe, isDark),
                                    if (isEdited)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'editado',
                                          style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : Colors.grey, fontStyle: FontStyle.italic),
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
                  },
                );
              },
            ),
          ),
          // INPUT FLUTUANTE IDÊNTICO
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