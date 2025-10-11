// admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        middle: Text(
          'Painel Administrativo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF0E0E0E),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                thumbColor: Color(0xFFFF444F),
                groupValue: _selectedTab,
                children: {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Usuários',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Mensagens',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Sistema',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  setState(() => _selectedTab = value!);
                },
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? UsersManagementTab()
                  : _selectedTab == 1
                      ? MessagesManagementTab()
                      : SystemSettingsTab(),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab de Gerenciamento de Usuários
class UsersManagementTab extends StatelessWidget {
  void _showUserDetails(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: UserDetailsPanel(userId: userId, userData: userData),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CupertinoActivityIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUserDetails(context, userId, userData),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: userData['blocked'] == true
                            ? Colors.red.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                userData['profile_image'] ??
                                    'https://alfredoooh.github.io/database/gallery/app_icon.png',
                              ),
                            ),
                            if (userData['online'] == true)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Color(0xFF1C1C1E)
                                          : Colors.white,
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
                                      userData['full_name'] ?? 'Usuário',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Color(0xFF0E0E0E),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (userData['isAdmin'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF444F)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF444F),
                                        ),
                                      ),
                                    ),
                                  if (userData['isPro'] == true)
                                    Container(
                                      margin: EdgeInsets.only(left: 4),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                userData['email'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${userData['tokens'] ?? 0} tokens',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF444F),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: userData['access'] == true
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userData['access'] == true ? 'Ativo' : 'Bloqueado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: userData['access'] == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Painel de Detalhes do Usuário
class UserDetailsPanel extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  UserDetailsPanel({required this.userId, required this.userData});

  @override
  _UserDetailsPanelState createState() => _UserDetailsPanelState();
}

class _UserDetailsPanelState extends State<UserDetailsPanel> {
  late TextEditingController _tokensController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _tokensController = TextEditingController(
      text: widget.userData['tokens']?.toString() ?? '0',
    );
    _messageController = TextEditingController();
  }

  Future<void> _updateUserData(Map<String, dynamic> updates) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update(updates);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuário atualizado com sucesso!')),
    );
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'user_id': widget.userId,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificação enviada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      widget.userData['profile_image'] ??
                          'https://alfredoooh.github.io/database/gallery/app_icon.png',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userData['full_name'] ?? 'Usuário',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Color(0xFF0E0E0E),
                          ),
                        ),
                        Text(
                          widget.userData['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Controles Rápidos
              Text(
                'Controles Rápidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.block_rounded,
                      label: widget.userData['access'] == true
                          ? 'Bloquear'
                          : 'Desbloquear',
                      color: widget.userData['access'] == true
                          ? Colors.red
                          : Colors.green,
                      onTap: () {
                        _updateUserData({
                          'access': !(widget.userData['access'] ?? true),
                          'blocked': !(widget.userData['blocked'] ?? false),
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.star_rounded,
                      label: widget.userData['isPro'] == true
                          ? 'Remover PRO'
                          : 'Tornar PRO',
                      color: Colors.amber,
                      onTap: () {
                        _updateUserData({
                          'isPro': !(widget.userData['isPro'] ?? false),
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.admin_panel_settings_rounded,
                      label: widget.userData['isAdmin'] == true
                          ? 'Remover Admin'
                          : 'Tornar Admin',
                      color: Color(0xFFFF444F),
                      onTap: () {
                        _updateUserData({
                          'isAdmin': !(widget.userData['isAdmin'] ?? false),
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.delete_rounded,
                      label: 'Excluir',
                      color: Colors.red[700]!,
                      onTap: () {
                        _showDeleteConfirmation();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Tokens
              Text(
                'Gerenciar Tokens',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _tokensController,
                      keyboardType: TextInputType.number,
                      placeholder: 'Número de tokens',
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () {
                      final tokens = int.tryParse(_tokensController.text);
                      if (tokens != null) {
                        _updateUserData({'tokens': tokens});
                      }
                    },
                    child: Text('Atualizar'),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Enviar Notificação
              Text(
                'Enviar Mensagem ao Usuário',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 12),
              CupertinoTextField(
                controller: _messageController,
                placeholder: 'Digite sua mensagem',
                maxLines: 3,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: Color(0xFFFF444F),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _sendNotification,
                  child: Text('Enviar Notificação'),
                ),
              ),
              SizedBox(height: 24),

              // Informações Adicionais
              Text(
                'Informações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF0E0E0E),
                ),
              ),
              SizedBox(height: 12),
              _buildInfoCard('ID', widget.userId),
              _buildInfoCard('Tema', widget.userData['theme'] ?? 'dark'),
              _buildInfoCard('Idioma', widget.userData['language'] ?? 'pt'),
              _buildInfoCard(
                'Criado em',
                _formatDate(widget.userData['created_at']),
              ),
              if (widget.userData['expiration_date'] != null)
                _buildInfoCard(
                  'Expiração',
                  widget.userData['expiration_date'],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Color(0xFF0E0E0E),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Excluir Usuário'),
        content: Text(
          'Tem certeza que deseja excluir este usuário? Esta ação não pode ser desfeita.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .delete();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Usuário excluído!')),
              );
            },
            isDestructiveAction: true,
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tokensController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

// Tab de Gerenciamento de Mensagens
class MessagesManagementTab extends StatelessWidget {
  Future<void> _deleteMessage(String chatId, String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> _scheduleAutoDeletion(
      BuildContext context, String chatId, String messageId) async {
    final TextEditingController hoursController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Agendar Exclusão'),
        content: Column(
          children: [
            SizedBox(height: 12),
            Text('Excluir automaticamente após (horas):'),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              placeholder: 'Horas',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              final hours = int.tryParse(hoursController.text);
              if (hours != null) {
                final deleteAt =
                    DateTime.now().add(Duration(hours: hours));
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .doc(messageId)
                    .update({
                  'delete_at': Timestamp.fromDate(deleteAt),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Exclusão agendada para $hours horas')),
                );
              }
            },
            isDefaultAction: true,
            child: Text('Agendar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CupertinoActivityIndicator());
        }

        final chats = snapshot.data!.docs;

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Nenhuma mensagem encontrada',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final chatId = chats[index].id;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, messagesSnapshot) {
                if (!messagesSnapshot.hasData) return SizedBox.shrink();

                final messages = messagesSnapshot.data!.docs;

                return Column(
                  children: messages.map((messageDoc) {
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;
                    final messageId = messageDoc.id;

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onLongPress: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                title: Text('Opções da Mensagem'),
                                actions: [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _scheduleAutoDeletion(
                                          context, chatId, messageId);
                                    },
                                    child: Text('Agendar Exclusão'),
                                  ),
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteMessage(chatId, messageId);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Mensagem excluída!')),
                                      );
                                    },
                                    isDestructiveAction: true,
                                    child: Text('Excluir Agora'),
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancelar'),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Color(0xFF1C1C1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        messageData['sender_name'] ??
                                            'Usuário',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Color(0xFF0E0E0E),
                                        ),
                                      ),
                                    ),
                                    if (messageData['delete_at'] != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Agendada',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  messageData['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(
                                      messageData['timestamp']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

// Tab de Configurações do Sistema
class SystemSettingsTab extends StatefulWidget {
  @override
  _SystemSettingsTabState createState() => _SystemSettingsTabState();
}

class _SystemSettingsTabState extends State<SystemSettingsTab> {
  final TextEditingController _autoDeleteHoursController =
      TextEditingController();

  Future<void> _updateSystemSettings(Map<String, dynamic> settings) async {
    await FirebaseFirestore.instance
        .collection('system_settings')
        .doc('config')
        .set(settings, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configurações atualizadas!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .snapshots(),
      builder: (context, snapshot) {
        final settings = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Configurações Globais',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF0E0E0E),
              ),
            ),
            SizedBox(height: 20),

            // Auto Delete
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exclusão Automática de Mensagens',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF0E0E0E),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _autoDeleteHoursController,
                          keyboardType: TextInputType.number,
                          placeholder: 'Horas (0 para desativar)',
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF2C2C2E)
                                : Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        color: Color(0xFFFF444F),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          final hours = int.tryParse(
                              _autoDeleteHoursController.text);
                          if (hours != null) {
                            _updateSystemSettings({
                              'auto_delete_messages_hours': hours,
                            });
                          }
                        },
                        child: Text('Salvar'),
                      ),
                    ],
                  ),
                  if (settings['auto_delete_messages_hours'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Atual: ${settings['auto_delete_messages_hours']} horas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tokens Diários para Freemium
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tokens Diários (Freemium)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF0E0E0E),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${settings['daily_tokens_freemium'] ?? 50}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF444F),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'tokens/dia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  CupertinoSlider(
                    value: (settings['daily_tokens_freemium'] ?? 50)
                        .toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: Color(0xFFFF444F),
                    onChanged: (value) {
                      _updateSystemSettings({
                        'daily_tokens_freemium': value.toInt(),
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Modo Manutenção
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Manutenção',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF0E0E0E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bloqueia acesso de usuários',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  CupertinoSwitch(
                    value: settings['maintenance_mode'] ?? false,
                    activeColor: Color(0xFFFF444F),
                    onChanged: (value) {
                      _updateSystemSettings({
                        'maintenance_mode': value,
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Estatísticas
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estatísticas do Sistema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Color(0xFF0E0E0E),
                    ),
                  ),
                  SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, usersSnapshot) {
                      final totalUsers = usersSnapshot.data?.docs.length ?? 0;
                      final onlineUsers = usersSnapshot.data?.docs
                              .where((doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['online'] ==
                                  true)
                              .length ??
                          0;

                      return Column(
                        children: [
                          _buildStatRow(
                              'Total de Usuários', '$totalUsers'),
                          _buildStatRow(
                              'Usuários Online', '$onlineUsers'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF444F),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoDeleteHoursController.dispose();
    super.dispose();
  }
}