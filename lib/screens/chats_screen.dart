import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';
import 'group_detail_screen.dart';
import 'users_list_screen.dart';
import 'chats_widgets/conversation_list_item.dart';
import 'chats_widgets/group_list_item.dart';

class ChatsScreen extends StatefulWidget {
  final User? currentUser;

  const ChatsScreen({Key? key, this.currentUser}) : super(key: key);

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFFF444F);

  int _activeUsers = 0;
  Map<String, dynamic>? _userData;
  int _selectedTab = 0;
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _badgeController;
  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
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
    _searchController.dispose();
    _badgeController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
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
        }
      });
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
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId) && participants.length == 2) {
          // Conversa já existe, navegar para ela
          final otherUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
          
          final otherUserData = otherUserDoc.data();
          
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ChatDetailScreen(
                recipientId: otherUserId,
                recipientName: otherUserData?['username'] ?? 'Usuário',
                recipientImage: otherUserData?['profile_image'] ?? '',
              ),
            ),
          );
          return;
        }
      }

      // Criar nova conversa
      final conversationRef = await FirebaseFirestore.instance.collection('conversations').add({
        'participants': [user.uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${user.uid}': 0,
        'unreadCount_$otherUserId': 0,
      });

      // Navegar para a conversa
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      
      final otherUserData = otherUserDoc.data();
      
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ChatDetailScreen(
            recipientId: otherUserId,
            recipientName: otherUserData?['username'] ?? 'Usuário',
            recipientImage: otherUserData?['profile_image'] ?? '',
          ),
        ),
      );
    } catch (e) {
      print('Erro ao criar conversa: $e');
    }
  }

  void _showOptionsMenu() {
    if (!_isProOrAdmin) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Novas Conversas',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
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
                Icon(CupertinoIcons.person_add, color: primaryColor),
                const SizedBox(width: 8),
                Text('Nova Conversa', style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCreateGroupDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.group, color: primaryColor),
                const SizedBox(width: 8),
                Text('Criar Grupo', style: TextStyle(color: primaryColor)),
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
                      'groupImage': '',
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
          onUserSelected: _createConversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
        child: Center(child: CupertinoActivityIndicator(radius: 20)),
      );
    }

    // Tela bloqueada para usuários não PRO/Admin
    if (!_isProOrAdmin) {
      return CupertinoPageScaffold(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
        child: Stack(
          children: [
            // Conteúdo blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.3),
              ),
            ),
            // Mensagem centralizada
            Center(
              child: Container(
                margin: EdgeInsets.all(32),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.lock_shield_fill,
                      size: 64,
                      color: primaryColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Recursos PRO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'O acesso aos Chats é exclusivo para usuários PRO e Administradores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24),
                    CupertinoButton.filled(
                      child: Text('Atualizar para PRO'),
                      onPressed: () {
                        // Navegar para tela de planos
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              backgroundColor: isDark ? Color(0xFF000000).withOpacity(0.9) : CupertinoColors.white.withOpacity(0.9),
              border: null,
              largeTitle: Text('Conversas'),
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
                                  color: primaryColor,
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
                  SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed: _showOptionsMenu,
                    child: Icon(
                      CupertinoIcons.plus_circle_fill,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await _loadUserData();
              },
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSegmentedControl(isDark),
                  _buildFilterButtons(isDark),
                ],
              ),
            ),
            SliverFillRemaining(
              child: widget.currentUser == null
                  ? const Center(child: CupertinoActivityIndicator(radius: 15))
                  : PageView(
                      controller: _pageController,
                      physics: BouncingScrollPhysics(),
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
                          : CupertinoColors.systemGrey,
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
                          : CupertinoColors.systemGrey,
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
      {'label': 'Todas', 'icon': CupertinoIcons.globe},
      {'label': 'Não lidas', 'icon': CupertinoIcons.circle_fill},
      {'label': 'Recentes', 'icon': CupertinoIcons.time},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = _selectedFilter == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemGrey6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filters[index]['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filters[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? CupertinoColors.white
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

        // Filtro de não lidas
        if (_selectedFilter == 1) {
          conversations = conversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadCount = data['unreadCount_${currentUser.uid}'] ?? 0;
            return unreadCount > 0;
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

        return ListView.builder(
          padding: EdgeInsets.zero,
          physics: BouncingScrollPhysics(),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return ConversationListItem(
              conversation: conversations[index],
              currentUser: currentUser,
              isDark: isDark,
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
            subtitle: 'Toque em + para criar',
            isDark: isDark,
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          physics: BouncingScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return GroupListItem(
              group: groups[index],
              isDark: isDark,
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