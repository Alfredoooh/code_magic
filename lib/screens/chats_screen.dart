import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';
import 'group_detail_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    _searchController.dispose();
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

  void _loadUserData() {
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

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Novas Conversas',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showUsersDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_add, color: Color(0xFFFF444F)),
                const SizedBox(width: 8),
                Text('Nova Conversa', style: TextStyle(color: Color(0xFFFF444F))),
              ],
            ),
          ),
          if (_userData?['pro'] == true)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.group, color: Color(0xFFFF444F)),
                  const SizedBox(width: 8),
                  Text('Criar Grupo', style: TextStyle(color: Color(0xFFFF444F))),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Criar Grupo'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Nome do grupo',
            placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
            style: TextStyle(color: isDark ? CupertinoColors.white : CupertinoColors.black),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              nameController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
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
                    });
                    nameController.dispose();
                    Navigator.pop(context);
                  } catch (e) {
                    print('Erro ao criar grupo: $e');
                  }
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => UsersListScreen(
          currentUser: widget.currentUser,
          userData: _userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        border: null,
        middle: Text(
          'Conversas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: _showUsersDialog,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 24,
                  ),
                  if (_activeUsers > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _badgeController,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF444F),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? CupertinoColors.black : CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _activeUsers > 99 ? '99+' : '$_activeUsers',
                            style: const TextStyle(
                              color: CupertinoColors.white,
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
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 32,
              onPressed: _showOptionsMenu,
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: Color(0xFFFF444F),
                size: 28,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSegmentedControl(isDark),
            _buildFilterButtons(isDark),
            Expanded(
              child: widget.currentUser == null
                  ? const Center(child: CupertinoActivityIndicator(radius: 15))
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
      ),
    );
  }

  Widget _buildSegmentedControl(bool isDark) {
    return Container(
      color: isDark ? CupertinoColors.black : CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = 0);
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: _selectedTab == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Chats',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTab == 0
                          ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                          : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey),
                      fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = 1);
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: _selectedTab == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Grupos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTab == 1
                          ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                          : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey),
                      fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons(bool isDark) {
    final filters = [
      {'label': 'Todas', 'icon': CupertinoIcons.chat_bubble_2},
      {'label': 'Não Lidas', 'icon': CupertinoIcons.circle_fill},
      {'label': 'Não Enviadas', 'icon': CupertinoIcons.exclamationmark_circle},
    ];

    return Container(
      color: isDark ? CupertinoColors.black : CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA))
                        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6))
                          : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filters[index]['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filters[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? CupertinoColors.white : CupertinoColors.black)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
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
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.chat_bubble_2,
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
        } else if (_selectedFilter == 2) {
          conversations = conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['lastMessage'] == '' || data['lastMessage'] == null;
          }).toList();
        }

        if (conversations.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.tray,
            title: 'Nenhuma conversa encontrada',
            subtitle: 'Não há conversas com esse filtro',
            isDark: isDark,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: conversations.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            indent: 88,
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
          ),
          itemBuilder: (context, index) {
            final conversation = conversations[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(conversation['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final isOnline = userData['isOnline'] == true;
                final lastMessage = conversation['lastMessage'] ?? '';
                final unreadCount = conversation['unreadCount_${currentUser.uid}'] ?? 0;

                return Container(
                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
                  child: CupertinoListTile(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF444F),
                          ),
                          child: userData['profile_image'] != null &&
                                  userData['profile_image'].isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    userData['profile_image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        (userData['username'] ?? 'U')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    (userData['username'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? CupertinoColors.black : CupertinoColors.white,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 15,
                      ),
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            constraints: const BoxConstraints(minWidth: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF444F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ChatDetailScreen(
                            recipientId: otherUserId,
                            recipientName: userData['username'] ?? 'Usuário',
                            recipientImage: userData['profile_image'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.group,
            title: 'Nenhum grupo',
            subtitle: _userData?['pro'] == true ? 'Toque em + para criar' : 'Apenas PRO',
            isDark: isDark,
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: groups.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.5,
            indent: 88,
            color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
          ),
          itemBuilder: (context, index) {
            final groupData = groups[index].data() as Map<String, dynamic>;
            final members = List.from(groupData['members'] ?? []);

            return Container(
              color: isDark ? CupertinoColors.black : CupertinoColors.white,
              child: CupertinoListTile(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30D158)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.group_solid,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  groupData['name'] ?? 'Grupo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                subtitle: Text(
                  '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: groups[index].id,
                        groupName: groupData['name'] ?? 'Grupo',
                      ),
                    ),
                  );
                },
              ),
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
    return Container(
      color: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsersListScreen extends StatefulWidget {
  final User? currentUser;
  final Map<String, dynamic>? userData;

  const UsersListScreen({
    Key? key,
    required this.currentUser,
    this.userData,
  }) : super(key: key);

  @override
  _UsersListScreenState createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFFFF444F)),
          ),
        ),
        middle: Text(
          'Novo Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: isDark ? CupertinoColors.black : CupertinoColors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar',
                style: TextStyle(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CupertinoActivityIndicator(radius: 15));
                  }

                  final allUsers = snapshot.data!.docs.where((doc) {
                    if (doc.id == widget.currentUser?.uid) return false;
                    if (_searchQuery.isNotEmpty) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username = (data['username'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return username.contains(_searchQuery) || email.contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (allUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.person_2,
                            size: 64,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'Nenhum usuário disponível' : 'Nenhum resultado',
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: allUsers.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 88,
                      color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey5,
                    ),
                    itemBuilder: (context, index) {
                      final userDoc = allUsers[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final isOnline = userData['isOnline'] == true;

                      return Container(
                        color: isDark ? CupertinoColors.black : CupertinoColors.white,
                        child: CupertinoListTile(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF444F),
                                ),
                                child: userData['profile_image'] != null &&
                                        userData['profile_image'].isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          userData['profile_image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              (userData['username'] ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 22,
                                                color: CupertinoColors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (userData['username'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            color: CupertinoColors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? CupertinoColors.black : CupertinoColors.white,
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
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                              fontSize: 15,
                            ),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 32,
                            child: const Icon(
                              CupertinoIcons.chat_bubble_fill,
                              color: Color(0xFFFF444F),
                              size: 24,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    recipientId: userDoc.id,
                                    recipientName: userData['username'] ?? 'Usuário',
                                    recipientImage: userData['profile_image'] ?? '',
                                  ),
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  recipientId: userDoc.id,
                                  recipientName: userData['username'] ?? 'Usuário',
                                  recipientImage: userData['profile_image'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}