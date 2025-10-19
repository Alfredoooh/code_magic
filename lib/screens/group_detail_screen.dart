// lib/screens/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_colors.dart';
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
          setState(() => _userData = doc.data());
        }
      });
    }
  }

  Future<void> _createConversation(String otherUserId) async {
    final user = widget.currentUser;
    if (user == null) return;

    try {
      final existingConv = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .get();

      for (var doc in existingConv.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(otherUserId) && participants.length == 2) {
          _navigateToChat(otherUserId);
          return;
        }
      }

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
      if (mounted) {
        AppDialogs.showError(context, 'Erro', 'Erro ao criar conversa');
      }
    }
  }

  Future<void> _navigateToChat(String otherUserId) async {
    try {
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUserDoc.exists) {
        if (mounted) {
          AppDialogs.showError(context, 'Erro', 'Usuário não encontrado');
        }
        return;
      }

      final otherUserData = otherUserDoc.data();

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, 'Erro', 'Erro ao abrir conversa');
      }
    }
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: 260,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(text: 'Opções', fontSize: 18),
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.person_add_rounded,
              title: 'Nova Conversa',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _showUsersDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.group_add_rounded,
              title: 'Criar Grupo',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
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
                iconColor: color,
                backgroundColor: color.withOpacity(0.1),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();

    AppDialogs.showCustomDialog(
      context,
      title: 'Criar Grupo',
      content: AppTextField(
        controller: nameController,
        hintText: 'Nome do grupo',
        prefixIcon: const Icon(Icons.group_rounded, size: 20),
      ),
      actions: [
        AppTextButton(
          text: 'Cancelar',
          onPressed: () {
            nameController.dispose();
            Navigator.pop(context);
          },
        ),
        AppTextButton(
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
                  if (mounted) {
                    Navigator.pop(context);
                    AppDialogs.showSuccess(
                      context,
                      'Sucesso!',
                      'Grupo criado com sucesso!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    AppDialogs.showError(context, 'Erro', 'Erro ao criar grupo');
                  }
                }
              }
            }
          },
        ),
      ],
    );
  }

  void _showUsersDialog() {
    Navigator.push(
      context,
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(
        title: 'Conversas',
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.people_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _activeUsers > 99 ? '99+' : '$_activeUsers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: AppColors.primary),
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
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => _selectedTab = index),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              label: 'Chats',
              isSelected: _selectedTab == 0,
              onTap: () {
                setState(() => _selectedTab = 0);
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSegmentButton(
              label: 'Grupos',
              isSelected: _selectedTab == 1,
              onTap: () {
                setState(() => _selectedTab = 1);
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons(bool isDark) {
    final filters = ['Todas', 'Não lidas', 'Recentes'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          )
                        : null,
                    color: !isSelected
                        ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2,
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Nenhuma conversa',
            subtitle: 'Toque em + para começar',
            isDark: isDark,
          );
        }

        var conversations = snapshot.data!.docs;

        if (_selectedFilter == 1) {
          conversations = conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount = data['unreadCount_${currentUser.uid}'] ?? 0;
            return unreadCount > 0;
          }).toList();

          if (conversations.isEmpty) {
            return _buildEmptyState(
              icon: Icons.mark_chat_read_rounded,
              title: 'Tudo lido!',
              subtitle: 'Você não tem mensagens não lidas',
              isDark: isDark,
            );
          }
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            indent: 72,
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
            indent: 72,
          ),
          itemBuilder: (context, index) {
            final groupData = groups[index].data() as Map<String, dynamic>;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: AppIconCircle(
                icon: Icons.group_rounded,
                iconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                size: 56,
              ),
              title: Text(
                groupData['name'] ?? 'Grupo',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              subtitle: Text(
                groupData['lastMessage'] ?? 'Sem mensagens',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount_${currentUser.uid}'] ?? 0;
        final isOnline = userData['isOnline'] == true;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            userData['username'] ?? 'Usuário',
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              data['lastMessage'] ?? 'Sem mensagens',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing: unreadCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 22),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : null,
          onTap: () => onTap(otherUserId),
        );
      },
    );
  }
}