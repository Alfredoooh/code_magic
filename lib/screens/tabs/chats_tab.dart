import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/theme_service.dart';
import '../chat_screen.dart';
import '../direct_message_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({Key? key}) : super(key: key);

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => _showNewChatOptions(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1877F2),
          labelColor: const Color(0xFF1877F2),
          unselectedLabelColor: textColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Mensagens Diretas'),
            Tab(text: 'Canais'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectMessages(),
          _buildChannels(),
        ],
      ),
    );
  }

  Widget _buildDirectMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Não autenticado'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('direct_messages')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar conversas'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data?.docs ?? [];

        if (conversations.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.chat_bubble_2,
            message: 'Nenhuma conversa ainda.\nInicie uma nova conversa!',
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index].data() as Map<String, dynamic>;
            final conversationId = conversations[index].id;
            final participants = List<String>.from(conversation['participants']);
            final otherUserId = participants.firstWhere((id) => id != user.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Carregando...'));
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final userName = userData?['displayName'] ?? 'Usuário';
                final lastMessage = conversation['lastMessage'] ?? '';

                return _buildChatItem(
                  name: userName,
                  lastMessage: lastMessage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectMessageScreen(
                          conversationId: conversationId,
                          otherUserId: otherUserId,
                          otherUserName: userName,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChannels() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('channels')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar canais'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final channels = snapshot.data?.docs ?? [];

        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.number,
            message: 'Nenhum canal ainda.\nCrie um novo canal!',
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index].data() as Map<String, dynamic>;
            final channelId = channels[index].id;
            final channelName = channel['name'] ?? 'Canal sem nome';
            final channelDescription = channel['description'] ?? '';
            final memberCount = (channel['members'] as List?)?.length ?? 0;

            return _buildChannelItem(
              name: channelName,
              description: channelDescription,
              memberCount: memberCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      channelId: channelId,
                      channelName: channelName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String lastMessage,
    required VoidCallback onTap,
  }) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1877F2),
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: textColor.withOpacity(0.3),
        size: 20,
      ),
    );
  }

  Widget _buildChannelItem({
    required String name,
    required String description,
    required int memberCount,
    required VoidCallback onTap,
  }) {
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1877F2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.number,
          color: Color(0xFF1877F2),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        description.isEmpty ? '$memberCount membros' : description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: textColor.withOpacity(0.3),
        size: 20,
      ),
    );
  }

  void _showNewChatOptions(BuildContext context) {
    final bgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF000000)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFFFFFFF);

    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.chat_bubble, color: Color(0xFF1877F2)),
              title: Text('Nova Mensagem Direta', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _showUserSelectionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.add_circled, color: Color(0xFF1877F2)),
              title: Text('Criar Canal', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _showCreateChannelDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeService.currentTheme == AppTheme.deepDark
            ? const Color(0xFF000000)
            : ThemeService.currentTheme == AppTheme.dark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
        title: Text('Selecionar Usuário', style: TextStyle(color: textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, isNotEqualTo: user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  final userName = userData['displayName'] ?? 'Usuário';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1877F2),
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(userName, style: TextStyle(color: textColor)),
                    onTap: () async {
                      Navigator.pop(context);
                      await _createDirectMessage(userId, userName);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDirectMessage(String otherUserId, String otherUserName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Verificar se já existe uma conversa
    final existingConversation = await FirebaseFirestore.instance
        .collection('direct_messages')
        .where('participants', arrayContains: user.uid)
        .get();

    String? conversationId;

    for (var doc in existingConversation.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        conversationId = doc.id;
        break;
      }
    }

    // Criar nova conversa se não existir
    if (conversationId == null) {
      final newConversation = await FirebaseFirestore.instance
          .collection('direct_messages')
          .add({
        'participants': [user.uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      conversationId = newConversation.id;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectMessageScreen(
            conversationId: conversationId!,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    }
  }

  void _showCreateChannelDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeService.currentTheme == AppTheme.deepDark
            ? const Color(0xFF000000)
            : ThemeService.currentTheme == AppTheme.dark
                ? const Color(0xFF1C1C1E)
                : const Color(0xFFFFFFFF),
        title: Text('Criar Canal', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Nome do Canal',
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              await FirebaseFirestore.instance.collection('channels').add({
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
                'createdBy': user.uid,
                'createdAt': FieldValue.serverTimestamp(),
                'members': [user.uid],
              });

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
