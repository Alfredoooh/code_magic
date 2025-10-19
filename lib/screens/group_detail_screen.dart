// lib/screens/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_ui_components.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

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
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        debugPrint('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (doc.exists && mounted) {
        setState(() => _groupData = doc.data());
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do grupo: $e');
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
        debugPrint('Erro ao decrementar tokens: $e');
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
      debugPrint('Erro ao enviar mensagem: $e');
      _showErrorMessage('Erro ao enviar mensagem');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    AppDialogs.showError(context, 'Atenção', message);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          try {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Mensagem'),
        content: AppTextField(
          controller: controller,
          hintText: 'Digite a nova mensagem',
          maxLines: 3,
        ),
        actions: [
          AppTextButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppTextButton(
            text: 'Salvar',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
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
      } catch (e) {
        debugPrint('Erro ao editar mensagem: $e');
        if (mounted) {
          _showErrorMessage('Erro ao editar mensagem');
        }
      }
    }
    controller.dispose();
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      'Excluir Mensagem',
      'Tem certeza que deseja excluir esta mensagem?',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } catch (e) {
        debugPrint('Erro ao excluir mensagem: $e');
        if (mounted) {
          _showErrorMessage('Erro ao excluir mensagem');
        }
      }
    }
  }

  void _showMessageOptions(String messageId, String messageText, DateTime timestamp, bool isMe) {
    AppBottomSheet.show(
      context,
      height: isMe ? 240 : 140,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(text: 'Opções da Mensagem', fontSize: 18),
            const SizedBox(height: 20),
            if (isMe) ...[
              _buildOptionButton(
                icon: Icons.edit_rounded,
                title: 'Editar',
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(messageId, messageText, timestamp);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                icon: Icons.delete_rounded,
                title: 'Excluir',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
              const SizedBox(height: 12),
            ],
            _buildOptionButton(
              icon: Icons.copy_rounded,
              title: 'Copiar',
              onTap: () {
                Clipboard.setData(ClipboardData(text: messageText));
                Navigator.pop(context);
                AppDialogs.showSuccess(context, 'Copiado', 'Mensagem copiada para área de transferência');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AppIconCircle(
                icon: icon,
                iconColor: color ?? AppColors.primary,
                backgroundColor: (color ?? AppColors.primary).withOpacity(0.1),
                size: 48,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppIconCircle(
                  icon: Icons.group_rounded,
                  iconColor: Colors.white,
                  backgroundColor: AppColors.success,
                  size: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.groupName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MEMBROS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${_groupData?['members']?.length ?? 0}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
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
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                final members = List<String>.from(groupData?['members'] ?? []);

                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum membro',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: members.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 72,
                    color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  ),
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(members[index]).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final isOnline = userData['isOnline'] == true;
                        final isCreator = members[index] == groupData?['createdBy'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary,
                                backgroundImage: userData['profile_image'] != null &&
                                        userData['profile_image'].toString().isNotEmpty
                                    ? NetworkImage(userData['profile_image'])
                                    : null,
                                child: userData['profile_image'] == null ||
                                        userData['profile_image'].toString().isEmpty
                                    ? Text(
                                        (userData['username'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? AppColors.darkCard : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userData['username'] ?? 'Usuário',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCreator)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? AppColors.success : Colors.grey,
                              fontSize: 13,
                            ),
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
                  debugPrint('Erro ao abrir URL: $e');
                }
              },
              child: Text(
                '$word ',
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.info,
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
            text: '${word.substring(1, word.length - 1)} ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
              fontSize: 16,
            ),
          ),
        );
      } else if (word.startsWith('_') && word.endsWith('_') && word.length > 2) {
        spans.add(
          TextSpan(
            text: '${word.substring(1, word.length - 1)} ',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(
              color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
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
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: widget.groupName,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showGroupInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Contador de membros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Row(
              children: [
                Icon(Icons.group_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                    final members = List.from(groupData?['members'] ?? []);
                    return Text(
                      '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Lista de mensagens
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
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma mensagem',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message = messageDoc.data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == currentUser?.uid;
                    final timestamp = message['timestamp'] as Timestamp?;
                    final isEdited = message['edited'] == true;

                    if (timestamp == null) return const SizedBox.shrink();

                    return GestureDetector(
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showMessageOptions(messageDoc.id, message['text'], timestamp.toDate(), isMe);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                backgroundColor: isMe
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkCard : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          message['senderName'] ?? 'Usuário',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    _buildMessageText(message['text'] ?? '', isMe, isDark),
                                    if (isEdited)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'editado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.grey,
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
          
          // Input de mensagem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      hintText: 'Mensagem',
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppIconButton(
                    icon: Icons.send_rounded,
                    onPressed: _sendMessage,
                    backgroundColor: AppColors.primary,
                    iconColor: Colors.white,
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