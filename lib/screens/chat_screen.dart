// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
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

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoURL,
    this.isOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isInitializing = true;
  bool _showQuickMessages = true;

  // Mensagens rápidas pré-definidas
  final List<Map<String, String>> _quickMessages = [
    {
      'title': 'Quero saber dos vossos serviços',
      'message': 'Olá! Gostaria de saber mais sobre os vossos serviços. Podem me dar mais informações?'
    },
    {
      'title': 'Interesse em parceria',
      'message': 'Tenho interesse em estabelecer uma parceria. Podemos conversar sobre isso?'
    },
    {
      'title': 'Dúvida sobre produto',
      'message': 'Olá! Tenho algumas dúvidas sobre os produtos disponíveis. Podem me ajudar?'
    },
    {
      'title': 'Solicitar orçamento',
      'message': 'Bom dia! Gostaria de solicitar um orçamento para os vossos serviços.'
    },
    {
      'title': 'Marcar reunião',
      'message': 'Olá! Gostaria de marcar uma reunião para conversarmos melhor. Qual a vossa disponibilidade?'
    },
    {
      'title': 'Suporte técnico',
      'message': 'Olá! Preciso de suporte técnico. Podem me ajudar com isso?'
    },
  ];

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
        if (mounted) {
          Navigator.pop(context);
        }
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
          SnackBar(
            content: Text('Erro ao inicializar chat: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage({String? predefinedMessage}) async {
    final messageText = predefinedMessage ?? _messageController.text.trim();
    
    if (messageText.isEmpty || _chatId == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null) return;

    if (predefinedMessage == null) {
      _messageController.clear();
    }

    // Esconde as mensagens rápidas após enviar a primeira mensagem
    if (_showQuickMessages) {
      setState(() {
        _showQuickMessages = false;
      });
    }

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
          SnackBar(
            content: Text('Erro ao enviar mensagem: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    }
  }

  Widget _buildQuickMessageButton(String title, String message, bool isDark) {
    return InkWell(
      onTap: () => _sendMessage(predefinedMessage: message),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3B3C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: const Color(0xFF1877F2),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessagesSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt,
                color: const Color(0xFF1877F2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mensagens rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Escolha uma opção ou escreva sua própria mensagem',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickMessages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final quickMsg = _quickMessages[index];
              return _buildQuickMessageButton(
                quickMsg['title']!,
                quickMsg['message']!,
                isDark,
              );
            },
          ),
        ],
      ),
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(svgString: CustomIcons.arrowBack, color: textColor),
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
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF31A24C),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardColor,
                          width: 2,
                        ),
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
                  if (widget.isOnline)
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF31A24C),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
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

                      if (messages.isEmpty && _showQuickMessages) {
                        return SingleChildScrollView(
                          child: _buildQuickMessagesSection(isDark),
                        );
                      }

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: isDark
                                    ? const Color(0xFF3A3B3C)
                                    : const Color(0xFFDADADA),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Inicie a conversa',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFFB0B3B8)
                                      : const Color(0xFF65676B),
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
                          final data = messageDoc.data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == currentUserId;
                          final createdAt = data['createdAt'] as Timestamp?;

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
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['text'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isMe
                                          ? Colors.white
                                          : textColor,
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
                                            : (isDark
                                                ? const Color(0xFFB0B3B8)
                                                : const Color(0xFF65676B)),
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
                  color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
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
                          hintText: 'Escrever mensagem...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFFB0B3B8)
                                : const Color(0xFF65676B),
                          ),
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
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(),
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}