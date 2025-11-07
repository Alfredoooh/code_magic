// lib/screens/messages_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../providers/auth_provider.dart' as auth; // CORRIGIDO: alias para evitar conflito

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

  Future<void> _initAdmin() async {
    final authProvider = context.read<auth.AuthProvider>(); // CORRIGIDO: usa alias
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

    setState(() {
      _isAdmin = isAdmin;
      _loadingAdminCheck = false;
      _tabController = TabController(length: isAdmin ? 3 : 1, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<auth.AuthProvider>(); // CORRIGIDO: usa alias
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Row(
          children: [
            SvgIcon(
              svgString: CustomIcons.inbox,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Inbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              Container(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA), height: 0.5),
              if (_loadingAdminCheck)
                const LinearProgressIndicator()
              else
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF1877F2),
                  labelColor: const Color(0xFF1877F2),
                  unselectedLabelColor: hintColor,
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
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _isAdmin ? _buildAdminTabs(cardColor, textColor, hintColor, authProvider) : [_buildUserInbox(cardColor, textColor, hintColor, authProvider)],
            ),
    );
  }

  Widget _buildUserInbox(Color cardColor, Color textColor, Color hintColor, auth.AuthProvider authProvider) {
    final currentUid = authProvider.user?.uid;
    if (currentUid == null) {
      return Center(child: Text('Usuário não autenticado', style: TextStyle(color: hintColor)));
    }

    final query = FirebaseFirestore.instance
        .collection('emails')
        .where('recipientId', isEqualTo: currentUid)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar mensagens: ${snapshot.error}', style: TextStyle(color: hintColor)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgIcon(svgString: CustomIcons.envelope, color: hintColor, size: 64),
              const SizedBox(height: 16),
              Text('Nenhuma mensagem', style: TextStyle(fontSize: 16, color: hintColor)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cardColor),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final senderName = data['senderName'] ?? 'Sistema';
            final created = data['createdAt'] as Timestamp?;
            final read = data['read'] == true;

            return ListTile(
              tileColor: cardColor,
              title: Text(subject, style: TextStyle(color: textColor, fontWeight: read ? FontWeight.w400 : FontWeight.w700)),
              subtitle: Text('$senderName • ${_formatTimestamp(created)}', style: TextStyle(color: hintColor)),
              trailing: read ? null : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1877F2).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('Novo', style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w700))),
              onTap: () => _openEmailDetail(doc.id, data, authProvider.user!.uid),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAdminTabs(Color cardColor, Color textColor, Color hintColor, auth.AuthProvider authProvider) {
    return [
      _buildAdminEmailsTab(cardColor, textColor, hintColor),
      _buildAdminUsersTab(cardColor, textColor, hintColor),
      _buildAdminSendTab(cardColor, textColor, hintColor, authProvider),
    ];
  }

  Widget _buildAdminEmailsTab(Color cardColor, Color textColor, Color hintColor) {
    final query = FirebaseFirestore.instance.collection('emails').orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro ao carregar emails: ${snapshot.error}', style: TextStyle(color: hintColor)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('Nenhum email', style: TextStyle(color: hintColor)));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cardColor),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final recipientName = data['recipientName'] ?? data['recipientId'];
            final created = data['createdAt'] as Timestamp?;

            return ListTile(
              tileColor: cardColor,
              title: Text(subject, style: TextStyle(color: textColor)),
              subtitle: Text('$recipientName • ${_formatTimestamp(created)}', style: TextStyle(color: hintColor)),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    await _adminDeleteEmail(doc.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Deletar')),
                ],
              ),
              onTap: () => _openEmailDetailAdmin(doc.id, data),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminUsersTab(Color cardColor, Color textColor, Color hintColor) {
    final query = FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro ao carregar usuários: ${snapshot.error}', style: TextStyle(color: hintColor)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text('Nenhum usuário', style: TextStyle(color: hintColor)));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cardColor),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Usuário';
            final email = data['email'] ?? '';
            final isBlocked = data['isBlocked'] == true;

            return ListTile(
              tileColor: cardColor,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1877F2),
                child: Text((name.isNotEmpty ? name[0].toUpperCase() : 'U')),
              ),
              title: Text(name, style: TextStyle(color: textColor)),
              subtitle: Text(email, style: TextStyle(color: hintColor)),
              trailing: PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'block') {
                    await _adminBlockUser(doc.id);
                  } else if (val == 'delete') {
                    await _adminDeleteUser(doc.id);
                  } else if (val == 'edit') {
                    _openEditUserDialog(doc.id, data);
                  } else if (val == 'send') {
                    _openSendEmailToUserDialog(doc.id, name);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'send', child: Text('Enviar email')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'block', child: Text(isBlocked ? 'Desbloquear' : 'Bloquear')),
                  const PopupMenuItem(value: 'delete', child: Text('Deletar')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminSendTab(Color cardColor, Color textColor, Color hintColor, auth.AuthProvider authProvider) {
    final TextEditingController toController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: toController,
            decoration: InputDecoration(
              hintText: 'UID do destinatário (ou deixe vazio para broadcast)',
              filled: true,
              fillColor: cardColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: subjectController,
            decoration: InputDecoration(hintText: 'Assunto', filled: true, fillColor: cardColor),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: bodyController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(hintText: 'Corpo do email', filled: true, fillColor: cardColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final recipientId = toController.text.trim();
                    final subject = subjectController.text.trim();
                    final body = bodyController.text.trim();
                    await _adminSendEmail(recipientId.isEmpty ? null : recipientId, subject, body);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email enviado')));
                    toController.clear();
                    subjectController.clear();
                    bodyController.clear();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1877F2)),
                  child: const Text('Enviar'),
                ),
              ),
            ],
          )
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
        await callable.call({'recipientId': recipientId, 'subject': subject, 'body': body});
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário bloqueado')));
    } catch (e) {
      debugPrint('Erro ao bloquear usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao bloquear usuário')));
    }
  }

  Future<void> _adminDeleteUser(String uid) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente deletar este usuário? Esta ação é irreversível.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Deletar')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
      await callable.call({'uid': uid});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário deletado')));
    } catch (e) {
      debugPrint('Erro ao deletar usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao deletar usuário')));
    }
  }

  Future<void> _adminDeleteEmail(String emailDocId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(emailDocId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email deletado')));
    } catch (e) {
      debugPrint('Erro ao deletar email: $e');
    }
  }

  Future<void> _openEmailDetail(String emailId, Map<String, dynamic> data, String currentUid) async {
    await showDialog(
      context: context,
      builder: (_) {
        final subject = data['subject'] ?? '(Sem assunto)';
        final body = data['body'] ?? '';
        final senderName = data['senderName'] ?? 'Sistema';
        return AlertDialog(
          title: Text(subject),
          content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('De: $senderName'), const SizedBox(height: 8), Text(body)])),
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
      if (doc.exists && doc.data()?['recipientId'] == currentUid && doc.data()?['read'] != true) {
        await docRef.update({'read': true});
      }
    } catch (e) {
      debugPrint('Erro ao marcar email como lido: $e');
    }
  }

  Future<void> _openEmailDetailAdmin(String emailId, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (_) {
        final subject = data['subject'] ?? '(Sem assunto)';
        final body = data['body'] ?? '';
        final senderName = data['senderName'] ?? 'Admin';
        final recipientName = data['recipientName'] ?? data['recipientId'];
        return AlertDialog(
          title: Text(subject),
          content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('De: $senderName'), Text('Para: $recipientName'), const SizedBox(height: 8), Text(body)])),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('emails').doc(emailId).delete();
                Navigator.of(context).pop();
              },
              child: const Text('Deletar'),
            ),
          ],
        );
      },
    );
  }

  void _openEditUserDialog(String uid, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final updates = <String, dynamic>{};
              if (nameController.text.trim().isNotEmpty) updates['name'] = nameController.text.trim();
              if (emailController.text.trim().isNotEmpty) updates['email'] = emailController.text.trim();
              try {
                final callable = FirebaseFunctions.instance.httpsCallable('updateUserData');
                await callable.call({'uid': uid, 'updates': updates});
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário atualizado')));
              } catch (e) {
                debugPrint('Erro ao atualizar usuário: $e');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _openSendEmailToUserDialog(String recipientId, String recipientName) {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enviar email para $recipientName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Assunto')),
            TextField(controller: bodyController, decoration: const InputDecoration(labelText: 'Corpo'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();
              if (subject.isEmpty || body.isEmpty) return;
              await _adminSendEmail(recipientId, subject, body);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email enviado')));
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