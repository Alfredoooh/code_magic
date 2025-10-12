import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import '../services/language_service.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const MainScreen({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, dynamic>? _userData;

  final List<bool> _hasNavigatedInTab = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _navigatorKeys = List.generate(
      4,
      (index) => GlobalKey<NavigatorState>(),
    );

    _screens = [
      HomeScreen(
        onThemeChanged: widget.onThemeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
      ),
      MarketplaceScreen(),
      NewsScreen(),
      ChatsScreen(),
    ];
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  void _updateUserStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': online,
        'last_seen': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();

    if (isFirstRouteInCurrentTab) {
      if (_currentIndex != 0) {
        _onTabTapped(0);
        return false;
      }
      return true;
    }

    return false;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      setState(() => _hasNavigatedInTab[index] = false);
    } else {
      setState(() => _currentIndex = index);
      _animationController.forward(from: 0);
    }
  }

  bool _shouldShowBottomBar() {
    final navigatorState = _navigatorKeys[_currentIndex].currentState;
    if (navigatorState != null) {
      final canPop = navigatorState.canPop();
      return !canPop;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showBottomBar = _shouldShowBottomBar();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: List.generate(_screens.length, (index) {
            return Offstage(
              offstage: _currentIndex != index,
              child: Navigator(
                key: _navigatorKeys[index],
                observers: [
                  _NavigatorObserver(
                    onPush: () {
                      setState(() => _hasNavigatedInTab[index] = true);
                    },
                    onPop: () {
                      Future.microtask(() {
                        if (_navigatorKeys[index].currentState?.canPop() == false) {
                          setState(() => _hasNavigatedInTab[index] = false);
                        }
                      });
                    },
                  ),
                ],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => _screens[index],
                  );
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: showBottomBar
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  height: 62,
                  backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
                  indicatorColor: Color(0xFFFF444F).withOpacity(0.15),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  elevation: 0,
                  animationDuration: Duration(milliseconds: 400),
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.home_rounded, size: 24),
                      selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFFF444F), size: 26),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.shopping_bag_rounded, size: 24),
                      selectedIcon: Icon(Icons.shopping_bag_rounded, color: Color(0xFFFF444F), size: 26),
                      label: 'Mercado',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.article_rounded, size: 24),
                      selectedIcon: Icon(Icons.article_rounded, color: Color(0xFFFF444F), size: 26),
                      label: 'Notícias',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_rounded, size: 24),
                      selectedIcon: Icon(Icons.chat_rounded, color: Color(0xFFFF444F), size: 26),
                      label: 'Chat',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _NavigatorObserver extends NavigatorObserver {
  final VoidCallback onPush;
  final VoidCallback onPop;

  _NavigatorObserver({
    required this.onPush,
    required this.onPop,
  });

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      onPush();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    onPop();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    onPop();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null && newRoute != null) {
      onPush();
    }
  }
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  int _activeUsers = 0;
  Map<String, dynamic>? _userData;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _getActiveUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  void _getActiveUsers() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .get();
    setState(() => _activeUsers = usersSnapshot.docs.length);
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.group_add_rounded, color: Color(0xFFFF444F)),
              title: Text('Criar Grupo', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_userData?['pro'] == true ? 'Disponível' : 'Apenas PRO'),
              enabled: _userData?['pro'] == true,
              onTap: () {
                if (_userData?['pro'] == true) {
                  Navigator.pop(context);
                  _showCreateGroupDialog();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add_rounded, color: Color(0xFFFF444F)),
              title: Text('Nova Conversa', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showUsersDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        title: Text('Criar Grupo', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Nome do grupo',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Grupo criado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao criar grupo: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF444F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Usuários Disponíveis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar usuários...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: Icon(Icons.search_rounded, color: Color(0xFFFF444F)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey),
                              onPressed: () {
                                setModalState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setModalState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                    }

                    final allUsers = snapshot.data!.docs.where((doc) {
                      if (doc.id == currentUser!.uid) return false;

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
                            Icon(Icons.people_rounded, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Nenhum usuário disponível' : 'Nenhum resultado encontrado',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = allUsers[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final isOnline = userData['isOnline'] == true;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFFFF444F),
                                  backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                                      ? NetworkImage(userData['profile_image'])
                                      : null,
                                  child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                                      ? Text(
                                          (userData['username'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5), width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              userData['username'] ?? 'Usuário',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '$_activeUsers online',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: Color(0xFFFF444F)),
            onPressed: _showOptionsMenu,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFFFF444F),
          labelColor: Color(0xFFFF444F),
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
            Tab(text: 'Conversas'),
            Tab(text: 'Grupos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsList(currentUser!, isDark),
          _buildGroupsList(currentUser, isDark),
        ],
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
          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma conversa ainda',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Toque em + para começar',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(conversation['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');

            if (otherUserId.isEmpty) return SizedBox.shrink();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final isOnline = userData['isOnline'] == true;
                final lastMessage = conversation['lastMessage'] ?? '';
                final unreadCount = conversation['unreadCount_${currentUser.uid}'] ?? 0;

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFFF444F),
                          backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                              ? NetworkImage(userData['profile_image'])
                              : null,
                          child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                              ? Text(
                                  (userData['username'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? Color(0xFF1A1A1A) : Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      userData['username'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (unreadCount > 0)
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF444F),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
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
          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum grupo ainda',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  _userData?['pro'] == true ? 'Toque em + para criar' : 'Apenas usuários PRO',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupData = groups[index].data() as Map<String, dynamic>;
            final members = List.from(groupData['members'] ?? []);

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.group_rounded, color: Colors.white, size: 28),
                ),
                title: Text(
                  groupData['name'] ?? 'Grupo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '${members.length} membros',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
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
              ),
            );
          },
        );
      },
    );
  }
}