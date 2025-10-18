import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
import 'chat_detail_screen.dart';
import 'group_detail_screen.dart';
import 'users_list_screen.dart';

class ChatsScreen extends StatefulWidget {
  final User? currentUser;

  const ChatsScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  int _activeUsers = 0;
  Map<String, dynamic>? _userData;
  int _selectedTab = 0;
  int _selectedFilter = 0;
  late AnimationController _badgeController;
  late PageController _pageController;
  bool _isProOrAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeUsers = snapshot.docs.length;
          _badgeController.forward(from: 0);
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = widget.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _userData = data;
            _isProOrAdmin = (data?['pro'] == true) || (data?['admin'] == true);
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createConversation(String otherUserId) async {
    final user = widget.currentUser;
    if (user == null) return;

    try {
      // Verificar se já existe uma conversa
      final existingConv = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .get();

      for (var doc in existingConv.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(otherUserId) && participants.length == 2) {
          // Conversa já existe, navegar para ela
          _navigateToChat(otherUserId);
          return;
        }
      }

      // Criar nova conversa
      await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [user.uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${user.uid}': 0,
        'unreadCount_$otherUserId': 0,
      });

      _navigateToChat(otherUserId);
    } catch (e) {
      print('❌ Erro ao criar conversa: $e');
      _showErrorDialog('Erro ao criar conversa');
    }
  }

  Future<void> _navigateToChat(String otherUserId) async {
    try {
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUserDoc.exists) {
        _showErrorDialog('Usuário não encontrado');
        return;
      }

      final otherUserData = otherUserDoc.data();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            recipientId: otherUserId,
            recipientName: otherUserData?['username'] ?? 'Usuário',
            recipientImage: otherUserData?['profile_image'] ?? '',
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao navegar para chat: $e');
      _showErrorDialog('Erro ao abrir conversa');
    }
  }

  void _showErrorDialog(String message) {
    AppDialogs.showError(context, 'Erro', message);
  }

  void _showOptionsMenu() {
    if (!_isProOrAdmin) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.lightCard,
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
              ListTile(
                leading: Icon(Icons.person_add, color: AppColors.primary),
                title: Text('Nova Conversa'),
                onTap: () {
                  Navigator.pop(context);
                  _showUsersDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.group_add, color: AppColors.primary),
                title: Text('Criar Grupo'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateGroupDialog();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Criar Grupo'),
        content: AppTextField(
          controller: nameController,
          hintText: 'Nome do grupo',
        ),
        actions: [
          AppSecondaryButton(
            text: 'Cancelar',
            onPressed: () {
              nameController.dispose();
              Navigator.pop(context);
            },
          ),
          AppPrimaryButton(
            text: 'Criar',
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final user = widget.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance.collection('groups').add({
                      'name': nameController.text.trim(),
                      'createdBy': user.uid,
                      'creatorName': _userData?['username'] ?? 'Usuário',
                      'members': [user.uid],
                      'timestamp': FieldValue.serverTimestamp(),
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                      'groupImage': '',
                    });
                    nameController.dispose();
                    Navigator.pop(context);
                  } catch (e) {
                    print('❌ Erro ao criar grupo: $e');
                    _showErrorDialog('Erro ao criar grupo');
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUsersDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => UsersListScreen(
          currentUser: widget.currentUser,
          userData: _userData,
          onUserSelected: _createConversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Tela bloqueada para usuários não PRO/Admin
    if (!_isProOrAdmin) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: AppCard(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconCircle(icon: Icons.lock_outline, size: 60),
                  SizedBox(height: 24),
                  AppSectionTitle(text: 'Recursos PRO', fontSize: 24),
                  SizedBox(height: 12),
                  Text(
                    'O acesso aos Chats é exclusivo para usuários PRO e Administradores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  AppPrimaryButton(
                    text: 'Atualizar para PRO',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(
        title: 'Conversas',
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.people),
                onPressed: _showUsersDialog,
              ),
              if (_activeUsers > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _badgeController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _activeUsers > 99 ? '99+' : '$_activeUsers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedControl(isDark),
          _buildFilterButtons(isDark),
          Expanded(
            child: widget.currentUser == null
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                    children: [
                      _buildConversationsList(widget.currentUser!, isDark),
                      _buildGroupsList(widget.currentUser!, isDark),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 0);
                _pageController.animateToPage(0,
                    duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Chats',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 0 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 1);
                _pageController.animateToPage(1,
                    duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Grupos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 1 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons(bool isDark) {
    final filters = ['Todas', 'Não lidas', 'Recentes'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildConversationsList(User currentUser, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          print('❌ Erro no stream: ${snapshot.error}');
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Erro ao carregar',
            subtitle: 'Tente novamente',
            isDark: isDark,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Nenhuma conversa',
            subtitle: 'Toque em + para começar',
            isDark: isDark,
          );
        }

        var conversations = snapshot.data!.docs;

        // Filtro de não lidas
        if (_selectedFilter == 1) {
          conversations = conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount = data['unreadCount_${currentUser.uid}'] ?? 0;
            return unreadCount > 0;
          }).toList();

          if (conversations.isEmpty) {
            return _buildEmptyState(
              icon: Icons.mark_chat_read,
              title: 'Tudo lido!',
              subtitle: 'Você não tem mensagens não lidas',
              isDark: isDark,
            );
          }
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          separatorBuilder: (context, index) => Divider(height: 1),
          itemBuilder: (context, index) {
            return _ConversationItem(
              conversation: conversations[index],
              currentUser: currentUser,
              isDark: isDark,
              onTap: _navigateToChat,
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(User currentUser, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          print('❌ Erro no stream: ${snapshot.error}');
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Erro ao carregar',
            subtitle: 'Tente novamente',
            isDark: isDark,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.group_outlined,
            title: 'Nenhum grupo',
            subtitle: 'Toque em + para criar',
            isDark: isDark,
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          separatorBuilder: (context, index) => Divider(height: 1),
          itemBuilder: (context, index) {
            final groupData = groups[index].data() as Map<String, dynamic>;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.group, color: Colors.white),
              ),
              title: Text(groupData['name'] ?? 'Grupo'),
              subtitle: Text(groupData['lastMessage'] ?? 'Sem mensagens'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(
                      groupId: groups[index].id,
                      groupName: groupData['name'] ?? 'Grupo',
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Widget separado para item de conversa
class _ConversationItem extends StatelessWidget {
  final QueryDocumentSnapshot conversation;
  final User currentUser;
  final bool isDark;
  final Function(String) onTap;

  const _ConversationItem({
    required this.conversation,
    required this.currentUser,
    required this.isDark,
    required this.onTap,
  });

  String _getOtherUserId(Map<String, dynamic> data) {
    final participants = data['participants'];
    if (participants is List) {
      final list = List<String>.from(participants);
      return list.firstWhere((id) => id != currentUser.uid, orElse: () => '');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final data = conversation.data() as Map<String, dynamic>;
    final otherUserId = _getOtherUserId(data);

    if (otherUserId.isEmpty) {
      return SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount_${currentUser.uid}'] ?? 0;

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                backgroundImage: userData['profile_image'] != null && userData['profile_image'].toString().isNotEmpty
                    ? NetworkImage(userData['profile_image'])
                    : null,
                child: userData['profile_image'] == null || userData['profile_image'].toString().isEmpty
                    ? Text(
                        (userData['username'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              if (userData['isOnline'] == true)
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
          title: Text(
            userData['username'] ?? 'Usuário',
            style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            data['lastMessage'] ?? 'Sem mensagens',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: unreadCount > 0
              ? Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          onTap: () => onTap(otherUserId),
        );
      },
    );
  }
}