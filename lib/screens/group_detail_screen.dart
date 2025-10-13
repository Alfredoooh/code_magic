// lib/screens/group_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    required this.groupId,
    required this.groupName,
  });

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGroup();
  }

  Future<void> _initializeGroup() async {
    await _loadUserData();
    await _loadGroupData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() => _userData = doc.data());
        }
      } catch (e) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (doc.exists) {
        setState(() => _groupData = doc.data());
      }
    } catch (e) {
      print('Erro ao carregar dados do grupo: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (_groupData != null) {
      final members = List.from(_groupData!['members'] ?? []);
      if (!members.contains(currentUser.uid)) {
        _showErrorMessage('Você não é membro deste grupo');
        return;
      }
    }

    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        _showErrorMessage('Tokens insuficientes');
        return;
      }

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
      print('Erro ao enviar mensagem: $e');
      _showErrorMessage('Erro ao enviar mensagem');
    }
  }

  void _showErrorMessage(String message) {
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

  Future<void> _editMessage(String messageId, String currentText, DateTime timestamp) async {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes > 5) {
      _showErrorMessage('Não é possível editar após 5 minutos');
      return;
    }

    final controller = TextEditingController(text: currentText);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Editar Mensagem'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            maxLines: 3,
            placeholder: 'Digite a nova mensagem',
            style: TextStyle(
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
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
                      .collection('groups')
                      .doc(widget.groupId)
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
                    .collection('groups')
                    .doc(widget.groupId)
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
              _showErrorMessage('Mensagem copiada');
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

  void _showGroupInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar', style: TextStyle(color: Color(0xFFFF444F))),
                  ),
                  Text(
                    'Info do Grupo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(width: 60),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF34C759), Color(0xFF30D158)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.group_solid,
                      color: CupertinoColors.white,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.groupName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MEMBROS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  Text(
                    '${_groupData?['members']?.length ?? 0}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                  final members = List<String>.from(groupData?['members'] ?? []);

                  if (members.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum membro',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: members.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 72,
                      color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
                    ),
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

                          return Container(
                            color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFF444F),
                                      ),
                                      child: userData['profile_image'] != null &&
                                              userData['profile_image'].isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                userData['profile_image'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    (userData['username'] ?? 'U')[0].toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: CupertinoColors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                (userData['username'] ?? 'U')[0].toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: CupertinoColors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.activeGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              userData['username'] ?? 'Usuário',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 17,
                                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isCreator)
                                            Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFF444F),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'ADMIN',
                                                  style: TextStyle(
                                                    color: CupertinoColors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

  Widget _buildMessageText(String text, bool isMe, bool isDark) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
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
                  fontSize: 17,
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
              fontSize: 17,
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
              fontSize: 17,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? CupertinoColors.white : (isDark ? CupertinoColors.white : CupertinoColors.black),
              fontSize: 17,
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
        child: Center(child: CupertinoActivityIndicator(radius: 15)),
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
              Icon(
                CupertinoIcons.back,
                color: Color(0xFFFF444F),
                size: 28,
              ),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        middle: GestureDetector(
          onTap: _showGroupInfo,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF30D158)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.group_solid,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                      final members = List.from(groupData?['members'] ?? []);
                      return Text(
                        '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      child: Column(
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
                  return Center(child: CupertinoActivityIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_2,
                          size: 64,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma mensagem',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 17,
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                    if (!isMe)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          message['senderName'] ?? 'Usuário',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFFFF444F),
                                          ),
                                        ),
                                      ),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CupertinoTextField(
                        controller: _controller,
                        style: TextStyle(
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          fontSize: 17,
                        ),
                        decoration: BoxDecoration(),
                        placeholder: 'Mensagem',
                        placeholderStyle: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 17,
                        ),
                        maxLines: null,
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