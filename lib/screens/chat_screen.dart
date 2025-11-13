// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientPhotoURL;
  final bool isOnline;
  final Timestamp? lastActive;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoURL,
    this.isOnline = false,
    this.lastActive,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.user?.uid;

      if (currentUserId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final ids = [currentUserId, widget.recipientId]..sort();
      final chatId = '${ids[0]}_${ids[1]}';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _chatId = chatId;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao inicializar chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao inicializar chat'),
            backgroundColor: Color(0xFFFA383E),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _chatId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;
    if (currentUserId == null) return;

    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'recipientId': widget.recipientId,
        'text': messageText,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Erro ao enviar mensagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar mensagem'),
            backgroundColor: Color(0xFFFA383E),
          ),
        );
      }
    }
  }

  List<TextSpan> _parseFormattedText(String text, Color textColor) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*([^\*]+)\*|_([^_]+)_|~([^~]+)~|`([^`]+)`');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: textColor),
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: textColor,
          ),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: textColor.withOpacity(0.1),
            color: textColor,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: textColor),
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: TextStyle(color: textColor))]
        : spans;
  }

  String _getLastActiveText(Timestamp? lastActive) {
    if (lastActive == null) return 'Offline';

    final now = DateTime.now();
    final activeTime = lastActive.toDate();
    final difference = now.difference(activeTime);

    if (difference.inMinutes < 1) return 'Ativo agora';
    if (difference.inMinutes < 60) return 'Ativo há ${difference.inMinutes}m';
    if (difference.inHours < 24) return 'Ativo há ${difference.inHours}h';
    if (difference.inDays < 7) return 'Ativo há ${difference.inDays}d';
    return 'Offline';
  }

  void _showChatOptions() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.string(
                      CustomIcons.search,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1877F2),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  title: Text(
                    'Pesquisar no chat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em breve'),
                        backgroundColor: Color(0xFF1877F2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.string(
                      CustomIcons.volumeOff,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFF9800),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  title: Text(
                    'Silenciar notificações',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat silenciado'),
                        backgroundColor: Color(0xFFFF9800),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF31A24C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.string(
                      CustomIcons.wallpaper,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF31A24C),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  title: Text(
                    'Alterar papel de parede',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em breve'),
                        backgroundColor: Color(0xFF31A24C),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA383E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.string(
                      CustomIcons.block,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFA383E),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  title: Text(
                    'Bloquear usuário',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFA383E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardColor,
                        title: Text('Bloquear usuário?', style: TextStyle(color: textColor)),
                        content: Text(
                          'Você não receberá mais mensagens desta pessoa.',
                          style: TextStyle(color: secondaryColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Usuário bloqueado'),
                                  backgroundColor: Color(0xFFFA383E),
                                ),
                              );
                            },
                            child: const Text(
                              'Bloquear',
                              style: TextStyle(color: Color(0xFFFA383E)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final isOnline = userSnapshot.data?.get('isOnline') == true;
        final lastActive = userSnapshot.data?.get('lastActive') as Timestamp?;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.string(
                CustomIcons.arrowBack,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1877F2),
                      backgroundImage: widget.recipientPhotoURL != null
                          ? NetworkImage(widget.recipientPhotoURL!)
                          : null,
                      child: widget.recipientPhotoURL == null
                          ? Text(
                              widget.recipientName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
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
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF31A24C),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        isOnline ? 'Online' : _getLastActiveText(lastActive),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline
                              ? const Color(0xFF31A24C)
                              : secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: SvgPicture.string(
                  CustomIcons.moreVert,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                ),
                onPressed: _showChatOptions,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                height: 0.5,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _isInitializing
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1877F2),
                          ),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(_chatId)
                            .collection('messages')
                            .orderBy('createdAt', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1877F2),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Erro ao carregar mensagens',
                                style: TextStyle(color: textColor),
                              ),
                            );
                          }

                          final messages = snapshot.data?.docs ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    CustomIcons.chatBubble,
                                    width: 64,
                                    height: 64,
                                    colorFilter: ColorFilter.mode(
                                      secondaryColor.withOpacity(0.3),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma mensagem ainda',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Envie uma mensagem para iniciar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final messageDoc = messages[index];
                              final data =
                                  messageDoc.data() as Map<String, dynamic>;
                              final isMe = data['senderId'] == currentUserId;
                              final createdAt = data['createdAt'] as Timestamp?;
                              final messageColor = isMe ? Colors.white : textColor;

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF1877F2)
                                        : (isDark
                                            ? const Color(0xFF3A3B3C)
                                            : const Color(0xFFE4E6EB)),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: messageColor,
                                          ),
                                          children: _parseFormattedText(
                                            data['text'] ?? '',
                                            messageColor,
                                          ),
                                        ),
                                      ),
                                      if (createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          timeago.format(
                                            createdAt.toDate(),
                                            locale: 'pt_BR',
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isMe
                                                ? Colors.white70
                                                : secondaryColor,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF3E4042)
                          : const Color(0xFFDADADA),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3B3C)
                                : const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Mensagem...',
                              hintStyle: TextStyle(color: secondaryColor),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1877F2),
                        child: IconButton(
                          icon: SvgPicture.string(
                            CustomIcons.send,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
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
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}