// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/post_feed.dart';
import '../widgets/new_post_modal.dart';
import 'search_screen.dart';
import 'messages_screen.dart';
import 'users_screen.dart';
import 'marketplace_screen.dart';
import 'marketplace/add_book_screen.dart';
import 'diary_screen.dart';
import 'diary_editor_screen.dart';
import 'new_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Widget?> _pages = [const PostFeed(), null, null, null, null];
  static const Color _activeBlue = Color(0xFF1877F2);

  final List<String> _tabTitles = [
    'Início',
    'Usuários',
    'Marketplace',
    'Diário',
    'Novo Pedido',
  ];

  Widget _getPage(int index) {
    if (_pages[index] != null) return _pages[index]!;
    switch (index) {
      case 1:
        _pages[1] = const UsersScreen();
        break;
      case 2:
        _pages[2] = const MarketplaceScreen();
        break;
      case 3:
        _pages[3] = const DiaryScreen();
        break;
      case 4:
        _pages[4] = const NewRequestScreen();
        break;
      default:
        _pages[index] = const SizedBox.shrink();
    }
    return _pages[index]!;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _handlePlusButton(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (_currentIndex == 0) {
      // Feed - criar novo post
      _showNewPostModal(context);
    } else if (_currentIndex == 2) {
      // Marketplace - adicionar livro
      final bool canAddBook = authProvider.userData?['isPro'] == true || 
                              authProvider.userData?['isPremium'] == true;

      if (canAddBook) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddBookScreen(),
          ),
        );
      } else {
        _showProRequiredDialog(context);
      }
    } else if (_currentIndex == 3) {
      // Diário - criar nova entrada
      if (authProvider.user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryEditorScreen(userId: authProvider.user!.uid),
          ),
        );
      }
    }
  }

  void _showProRequiredDialog(BuildContext context) {
    final themeProv = context.read<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFF1877F2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recurso Pro',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apenas usuários Pro ou Premium podem adicionar livros ao Marketplace.',
          style: TextStyle(color: hintColor, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendi',
              style: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ver Planos'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(int count) {
    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final unselectedColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final topBorderColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final authProvider = context.watch<AuthProvider>();
    final currentUid = authProvider.user?.uid;

    // Botão + aparece em: Feed (0), Marketplace (2) e Diário (3)
    final bool showPlusButton = _currentIndex == 0 || _currentIndex == 2 || _currentIndex == 3;
    final bool showSearchButton = _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3;
    final bool showInboxButton = _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: const CustomDrawer(),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  color: bgColor,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: [
                              IconButton(
                                icon: SvgIcon(
                                  svgString: CustomIcons.menu,
                                  color: iconColor,
                                ),
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              Text(
                                _tabTitles[_currentIndex],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: iconColor,
                                ),
                              ),
                              const Spacer(),
                              if (showPlusButton)
                                IconButton(
                                  icon: SvgIcon(
                                    svgString: CustomIcons.plus,
                                    color: iconColor,
                                  ),
                                  onPressed: () => _handlePlusButton(context),
                                ),
                              if (showSearchButton)
                                IconButton(
                                  icon: SvgIcon(
                                    svgString: CustomIcons.search,
                                    color: iconColor,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SearchScreen(),
                                      ),
                                    );
                                  },
                                ),
                              if (showInboxButton && currentUid != null)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('document_requests')
                                      .where('userId', isEqualTo: currentUid)
                                      .where('status', whereIn: ['in_progress', 'completed'])
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data?.docs.length ?? 0;
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: SvgIcon(
                                            svgString: CustomIcons.inbox,
                                            color: iconColor,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const MessagesScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildNotificationBadge(unreadCount),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        Container(color: topBorderColor, height: 0.5),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(5, (i) => _getPage(i)),
                  ),
                ),
              ],
            ),
          ),
          if (isWideScreen)
            Container(
              width: 80,
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: topBorderColor,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(-4, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildVerticalTabItem(
                              index: 0,
                              svg: CustomIcons.home,
                              unselectedColor: unselectedColor,
                            ),
                            _buildVerticalTabItem(
                              index: 1,
                              svg: CustomIcons.users,
                              unselectedColor: unselectedColor,
                            ),
                            _buildVerticalTabItem(
                              index: 2,
                              svg: CustomIcons.marketplace,
                              unselectedColor: unselectedColor,
                            ),
                            _buildVerticalTabItem(
                              index: 3,
                              svg: CustomIcons.book,
                              unselectedColor: unselectedColor,
                            ),
                            _buildVerticalTabItem(
                              index: 4,
                              svg: CustomIcons.addCircle,
                              unselectedColor: unselectedColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !isWideScreen
          ? Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: topBorderColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(
                      index: 0,
                      svg: CustomIcons.home,
                      unselectedColor: unselectedColor,
                    ),
                    _buildTabItem(
                      index: 1,
                      svg: CustomIcons.users,
                      unselectedColor: unselectedColor,
                    ),
                    _buildTabItem(
                      index: 2,
                      svg: CustomIcons.marketplace,
                      unselectedColor: unselectedColor,
                    ),
                    _buildTabItem(
                      index: 3,
                      svg: CustomIcons.book,
                      unselectedColor: unselectedColor,
                    ),
                    _buildTabItem(
                      index: 4,
                      svg: CustomIcons.addCircle,
                      unselectedColor: unselectedColor,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabItem({
    required int index,
    required String svg,
    required Color unselectedColor,
  }) {
    final bool active = _currentIndex == index;
    final Color iconColor = active ? _activeBlue : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(100),
        child: Center(
          child: SvgIcon(svgString: svg, size: 24, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildVerticalTabItem({
    required int index,
    required String svg,
    required Color unselectedColor,
  }) {
    final bool active = _currentIndex == index;
    final Color iconColor = active ? _activeBlue : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(100),
        child: Center(
          child: SvgIcon(svgString: svg, size: 24, color: iconColor),
        ),
      ),
    );
  }
}

void _showNewPostModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NewPostModal(),
  );
}