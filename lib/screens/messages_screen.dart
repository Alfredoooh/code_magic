// lib/screens/messages_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/request_cards.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
  bool _isAdmin = false;
  bool _loadingAdminCheck = true;
  TabController? _tabController;
  final DocumentService _documentService = DocumentService();

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
        _tabController = TabController(
          length: isAdmin ? 5 : 2,
          vsync: this,
        );
      });
    }
  }

  String? _extractUrlFromError(Object? error) {
    if (error == null) return null;
    try {
      final s = error.toString();
      final urlRegex = RegExp(r'https?://\S+');
      final match = urlRegex.firstMatch(s);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }

  Widget _buildFirebaseErrorWidget(Object error, Color textColor, Color hintColor) {
    final url = _extractUrlFromError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              svgString: CustomIcons.warning,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Índice necessário',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O Firestore precisa criar índices para esta consulta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: hintColor),
            ),
            const SizedBox(height: 12),
            if (url != null) ...[
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1877F2),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado')),
                      );
                    }
                  } catch (_) {}
                },
                icon: SvgIcon(
                  svgString: CustomIcons.copy,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('Copiar link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgIcon(
            svgString: CustomIcons.arrowLeft,
            size: 24,
            color: textColor,
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
                preferredSize: const Size.fromHeight(64),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFECECEC),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          dividerHeight: 0,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1877F2),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: textColor,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isScrollable: _isAdmin,
                          tabs: _isAdmin
                              ? const [
                                  Tab(text: 'Emails'),
                                  Tab(text: 'Usuários'),
                                  Tab(text: 'Enviar'),
                                  Tab(text: 'Pedidos'),
                                  Tab(text: 'Templates'),
                                ]
                              : const [
                                  Tab(text: 'Inbox'),
                                  Tab(text: 'Meus Pedidos'),
                                ],
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB),
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
                  : _buildUserTabs(cardColor, textColor, hintColor),
            ),
    );
  }

  List<Widget> _buildUserTabs(Color cardColor, Color textColor, Color hintColor) {
    return [
      _buildUserInbox(cardColor, textColor, hintColor),
      _buildUserRequests(cardColor, textColor, hintColor),
    ];
  }

  List<Widget> _buildAdminTabs(Color cardColor, Color textColor, Color hintColor) {
    final authProvider = context.watch<auth_provider.AuthProvider>();
    return [
      _buildAdminEmailsTab(cardColor, textColor, hintColor),
      _buildAdminUsersTab(cardColor, textColor, hintColor),
      _buildAdminSendTab(cardColor, textColor, hintColor, authProvider),
      _buildAdminRequestsTab(cardColor, textColor, hintColor),
      _buildAdminTemplatesTab(cardColor, textColor, hintColor),
    ];
  }

  Widget _buildUserRequests(Color cardColor, Color textColor, Color hintColor) {
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

    return StreamBuilder<List<DocumentRequest>>(
      stream: _documentService.getUserRequests(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  svgString: CustomIcons.inbox,
                  size: 64,
                  color: hintColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum pedido enviado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return RequestCard(
              request: requests[index],
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
            );
          },
        );
      },
    );
  }

  Widget _buildAdminRequestsTab(Color cardColor, Color textColor, Color hintColor) {
    return StreamBuilder<List<DocumentRequest>>(
      stream: _documentService.getAllRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  svgString: CustomIcons.inbox,
                  size: 64,
                  color: hintColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum pedido recebido',
                  style: TextStyle(color: hintColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return AdminRequestCard(
              request: requests[index],
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
              onStatusUpdate: (status, notes) async {
                await _documentService.updateRequestStatus(
                  requests[index].id,
                  status,
                  adminNotes: notes,
                );
              },
              onDelete: () async {
                await _documentService.deleteRequest(requests[index].id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAdminTemplatesTab(Color cardColor, Color textColor, Color hintColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTemplateDialog(cardColor, textColor, hintColor),
            icon: SvgIcon(
              svgString: CustomIcons.plus,
              size: 20,
              color: Colors.white,
            ),
            label: const Text('Adicionar Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<DocumentTemplate>>(
            stream: _documentService.getTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
              }

              final templates = snapshot.data ?? [];

              if (templates.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum template cadastrado',
                    style: TextStyle(color: hintColor),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          template.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: SvgIcon(
                                svgString: CustomIcons.image,
                                size: 24,
                                color: hintColor,
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        template.name,
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        '${template.usageCount} usos',
                        style: TextStyle(color: hintColor),
                      ),
                      trailing: IconButton(
                        icon: SvgIcon(
                          svgString: CustomIcons.trash,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await _documentService.deleteTemplate(template.id);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTemplateDialog(Color cardColor, Color textColor, Color hintColor) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final imageUrlController = TextEditingController();
    DocumentCategory selectedCategory = DocumentCategory.curriculum;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text('Novo Template', style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: imageUrlController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'URL da Imagem'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DocumentCategory>(
                      value: selectedCategory,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: DocumentCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final template = DocumentTemplate(
                      id: '',
                      name: nameController.text,
                      description: descController.text,
                      imageUrl: imageUrlController.text,
                      category: selectedCategory,
                      createdAt: DateTime.now(),
                    );
                    await _documentService.createTemplate(template);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
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
          return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
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
                  SvgIcon(
                    svgString: CustomIcons.inbox,
                    size: 80,
                    color: hintColor.withOpacity(0.5),
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
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final senderName = data['senderName'] ?? 'Sistema';
            final created = data['createdAt'] as Timestamp?;
            final read = data['read'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: read
                      ? Colors.transparent
                      : const Color(0xFF1877F2).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: read
                        ? (const Color(0xFF1877F2).withOpacity(0.1))
                        : const Color(0xFF1877F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SvgIcon(
                      svgString: CustomIcons.envelope,
                      size: 20,
                      color: read ? const Color(0xFF1877F2) : Colors.white,
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
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      SvgIcon(
                        svgString: CustomIcons.user,
                        size: 12,
                        color: hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$senderName • ${_formatTimestamp(created)}',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

  Widget _buildAdminEmailsTab(Color cardColor, Color textColor, Color hintColor) {
    final query = FirebaseFirestore.instance
        .collection('emails')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
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
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final subject = data['subject'] ?? '(Sem assunto)';
            final recipientName = data['recipientName'] ?? data['recipientId'];
            final created = data['createdAt'] as Timestamp?;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: SvgIcon(
                      svgString: CustomIcons.envelope,
                      size: 20,
                      color: const Color(0xFF1877F2),
                    ),
                  ),
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
                  icon: SvgIcon(
                    svgString: CustomIcons.trash,
                    size: 20,
                    color: Colors.red,
                  ),
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
          return _buildFirebaseErrorWidget(snapshot.error!, textColor, hintColor);
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
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Usuário';
            final email = data['email'] ?? '';
            final isBlocked = data['isBlocked'] == true;
            final userType = data['userType'] ?? 'user';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF1877F2),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (userType == 'admin')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgIcon(
                              svgString: CustomIcons.shield,
                              size: 12,
                              color: const Color(0xFF1877F2),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Admin',
                              style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bloqueado',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  email,
                  style: TextStyle(color: hintColor, fontSize: 13),
                ),
                trailing: PopupMenuButton<String>(
                  icon: SvgIcon(
                    svgString: CustomIcons.moreVertical,
                    size: 20,
                    color: textColor,
                  ),
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
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgIcon(
                    svgString: CustomIcons.user,
                    size: 20,
                    color: hintColor,
                  ),
                ),
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
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgIcon(
                    svgString: CustomIcons.tag,
                    size: 20,
                    color: hintColor,
                  ),
                ),
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
          ElevatedButton.icon(
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
            icon: SvgIcon(
              svgString: CustomIcons.send,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              'Enviar Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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