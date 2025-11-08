// lib/screens/messages_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../providers/auth_provider.dart' as auth_provider;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
  bool _isAdmin = false;
  bool _loadingAdminCheck = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initAdmin();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initAdmin() async {
    final authProvider = context.read<auth_provider.AuthProvider>();
    final localUserData = authProvider.userData;
    bool isAdmin = false;

    try {
      if (localUserData != null && localUserData['userType'] == 'admin') {
        isAdmin = true;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final tokenRes = await user.getIdTokenResult(true);
          final claims = tokenRes.claims ?? {};
          if (claims['admin'] == true) isAdmin = true;
        }
      }
    } catch (e) {
      debugPrint('Erro ao checar admin: $e');
    }

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _loadingAdminCheck = false;
        _tabController = TabController(length: isAdmin ? 3 : 1, vsync: this);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mensagens',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        bottom: _loadingAdminCheck
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(49),
                child: Column(
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                      height: 0.5,
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF1877F2),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF1877F2),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      unselectedLabelColor: hintColor,
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      tabs: _isAdmin
                          ? const [
                              Tab(text: 'Emails'),
                              Tab(text: 'Usuários'),
                              Tab(text: 'Enviar'),
                            ]
                          : const [
                              Tab(text: 'Inbox'),
                            ],
                    ),
                  ],
                ),
              ),
      ),
      body: _loadingAdminCheck
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(color: hintColor),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _isAdmin
                  ? _buildAdminTabs(cardColor, textColor, hintColor)
                  : [_buildUserInbox(cardColor, textColor, hintColor)],
            ),
    );
  }

  Widget _buildUserInbox(Color cardColor, Color textColor, Color hintColor) {
    final authProvider = context.watch<auth_provider.AuthProvider>();
    final currentUid = authProvider.user?.uid;

    if (currentUid == null) {
      return Center(
        child: Text(
          'Usuário não autenticado',
          style: TextStyle(color: hintColor),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('emails')
        .where('recipientId', isEqualTo: currentUid)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar mensagens',
                    style: TextStyle(color: hintColor),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(
                    CustomIcons.inbox,
                    width: 80,
                    height: 80,
                    colorFilter: ColorFilter.mode(
                      hintColor.withOpacity(0.5),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nenhuma mensagem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Suas mensagens aparecerão aqui',
                    style: TextStyle(
                      fontSize: 15,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final senderName = data['senderName'] ?? 'Sistema';
            final created = data['createdAt'] as Timestamp?;
            final read = data['read'] == true;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: read
                      ? (const Color(0xFF1877F2).withOpacity(0.1))
                      : const Color(0xFF1877F2),
                  child: SvgPicture.string(
                    CustomIcons.envelope,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      read ? const Color(0xFF1877F2) : Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  subject,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '$senderName • ${_formatTimestamp(created)}',
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 13,
                  ),
                ),
                trailing: read
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Novo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                onTap: () => _openEmailDetail(doc.id, data, currentUid),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAdminTabs(Color cardColor, Color textColor, Color hintColor) {
    final authProvider = context.watch<auth_provider.AuthProvider>();
    return [
      _buildAdminEmailsTab(cardColor, textColor, hintColor),
      _buildAdminUsersTab(cardColor, textColor, hintColor),
      _buildAdminSendTab(cardColor, textColor, hintColor, authProvider),
    ];
  }

  Widget _buildAdminEmailsTab(Color cardColor, Color textColor, Color hintColor) {
    final query = FirebaseFirestore.instance
        .collection('emails')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar emails',
              style: TextStyle(color: hintColor),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Nenhum email',
              style: TextStyle(color: hintColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final recipientName = data['recipientName'] ?? data['recipientId'];
            final created = data['createdAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  subject,
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
                subtitle: Text(
                  '$recipientName • ${_formatTimestamp(created)}',
                  style: TextStyle(color: hintColor, fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _adminDeleteEmail(doc.id),
                ),
                onTap: () => _openEmailDetailAdmin(doc.id, data),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminUsersTab(Color cardColor, Color textColor, Color hintColor) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar usuários',
              style: TextStyle(color: hintColor),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Nenhum usuário',
              style: TextStyle(color: hintColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Usuário';
            final email = data['email'] ?? '';
            final isBlocked = data['isBlocked'] == true;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1877F2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  email,
                  style: TextStyle(color: hintColor, fontSize: 13),
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textColor),
                  onSelected: (val) async {
                    if (val == 'block') {
                      await _adminBlockUser(doc.id);
                    } else if (val == 'delete') {
                      await _adminDeleteUser(doc.id);
                    } else if (val == 'send') {
                      _openSendEmailToUserDialog(doc.id, name);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'send', child: Text('Enviar email')),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(isBlocked ? 'Desbloquear' : 'Bloquear'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Deletar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminSendTab(
    Color cardColor,
    Color textColor,
    Color hintColor,
    auth_provider.AuthProvider authProvider,
  ) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final TextEditingController toController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: toController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'UID do destinatário (vazio = todos)',
                hintStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: subjectController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Assunto',
                hintStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: bodyController,
              maxLines: null,
              expands: true,
              style: TextStyle(color: textColor),
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Corpo do email',
                hintStyle: TextStyle(color: hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final recipientId = toController.text.trim();
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();

              if (subject.isEmpty || body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha assunto e corpo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _adminSendEmail(
                recipientId.isEmpty ? null : recipientId,
                subject,
                body,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email enviado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );

              toController.clear();
              subjectController.clear();
              bodyController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enviar Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _adminSendEmail(String? recipientId, String subject, String body) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendEmailToUser');

      if (recipientId == null) {
        final usersSnap = await FirebaseFirestore.instance.collection('users').get();
        for (final u in usersSnap.docs) {
          await callable.call({
            'recipientId': u.id,
            'subject': subject,
            'body': body,
          });
        }
      } else {
        await callable.call({
          'recipientId': recipientId,
          'subject': subject,
          'body': body,
        });
      }
    } catch (e) {
      debugPrint('Erro ao enviar email admin: $e');
      rethrow;
    }
  }

  Future<void> _adminBlockUser(String uid) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('blockUser');
      await callable.call({'uid': uid});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário bloqueado')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao bloquear usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao bloquear usuário'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adminDeleteUser(String uid) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text(
              'Deseja realmente deletar este usuário? Esta ação é irreversível.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Deletar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
      await callable.call({'uid': uid});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário deletado')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao deletar usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao deletar usuário'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adminDeleteEmail(String emailDocId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(emailDocId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email deletado')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao deletar email: $e');
    }
  }

  Future<void> _openEmailDetail(String emailId, Map<String, dynamic> data, String currentUid) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    await showDialog(
      context: context,
      builder: (_) {
        final subject = data['subject'] ?? '(Sem assunto)';
        final body = data['body'] ?? '';
        final senderName = data['senderName'] ?? 'Sistema';

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            subject,
            style: TextStyle(color: textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'De: $senderName',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );

    try {
      final docRef = FirebaseFirestore.instance.collection('emails').doc(emailId);
      final doc = await docRef.get();
      if (doc.exists &&
          doc.data()?['recipientId'] == currentUid &&
          doc.data()?['read'] != true) {
        await docRef.update({'read': true});
      }
    } catch (e) {
      debugPrint('Erro ao marcar email como lido: $e');
    }
  }

  Future<void> _openEmailDetailAdmin(String emailId, Map<String, dynamic> data) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    await showDialog(
      context: context,
      builder: (_) {
        final subject = data['subject'] ?? '(Sem assunto)';
        final body = data['body'] ?? '';
        final senderName = data['senderName'] ?? 'Admin';
        final recipientName = data['recipientName'] ?? data['recipientId'];

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            subject,
            style: TextStyle(color: textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('De: $senderName', style: TextStyle(color: textColor)),
                Text('Para: $recipientName', style: TextStyle(color: textColor)),
                const SizedBox(height: 16),
                Text(body, style: TextStyle(color: textColor)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('emails').doc(emailId).delete();
                if (mounted) Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deletar'),
            ),
          ],
        );
      },
    );
  }

  void _openSendEmailToUserDialog(String recipientId, String recipientName) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Enviar email para $recipientName',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Assunto',
                labelStyle: TextStyle(color: textColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Corpo',
                labelStyle: TextStyle(color: textColor),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();
              if (subject.isEmpty || body.isEmpty) return;

              await _adminSendEmail(recipientId, subject, body);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email enviado')),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}