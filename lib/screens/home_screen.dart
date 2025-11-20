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
import 'apps_screen.dart';
import 'diary_screen.dart';
import 'unified_editor_screen.dart';
import 'document_requests_screen.dart';
import 'otp_verification_screen.dart';

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
    'Ativos',
    'Apps',
    'Diário',
    'Novo Pedido',
  ];

  final List<String> _outlinedSvgs = [
    CustomIcons.home,
    CustomIcons.users,
    CustomIcons.apps,
    CustomIcons.book,
    CustomIcons.addCircle,
  ];

  final List<String> _filledSvgs = [
    CustomIcons.homeFilled ?? CustomIcons.home,
    CustomIcons.usersFilled ?? CustomIcons.users,
    CustomIcons.appsFilled ?? CustomIcons.apps,
    CustomIcons.bookFilled ?? CustomIcons.book,
    CustomIcons.addCircleFilled ?? CustomIcons.addCircle,
  ];

  Widget _getPage(int index) {
    if (_pages[index] != null) return _pages[index]!;
    switch (index) {
      case 1:
        _pages[1] = const UsersScreen();
        break;
      case 2:
        _pages[2] = const AppsScreen();
        break;
      case 3:
        _pages[3] = const DiaryScreen();
        break;
      case 4:
        _pages[4] = const DocumentRequestsScreen();
        break;
      default:
        _pages[index] = const SizedBox.shrink();
    }
    return _pages[index]!;
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    _hideKeyboard();
    setState(() => _currentIndex = index);
  }

  Future<void> _handlePlusButton(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    _hideKeyboard();
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    if (_currentIndex == 0) {
      _showNewPostModal(context);
    } else if (_currentIndex == 3) {
      if (authProvider.user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedEditorScreen(
              userId: authProvider.user!.uid,
              editorType: EditorType.note,
            ),
          ),
        );
      }
    }
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
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.needsOTPVerification) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OTPVerificationScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final scaffoldBgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final unselectedColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final topBorderColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final authProvider = context.watch<AuthProvider>();
    final currentUid = authProvider.user?.uid;

    final bool showPlusButton = _currentIndex == 0 || _currentIndex == 3;
    final bool showSearchButton = _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3;
    final bool showInboxButton = _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2;
    final bool showLayoutMenu = _currentIndex == 4;

    return GestureDetector(
      onTap: _hideKeyboard,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: scaffoldBgColor,
        drawer: const CustomDrawer(),
        resizeToAvoidBottomInset: false,
        body: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
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
                                      icon: SvgPicture.string(
                                        CustomIcons.menu,
                                        width: 21.6,
                                        height: 21.6,
                                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                      ),
                                      onPressed: () {
                                        _hideKeyboard();
                                        _scaffoldKey.currentState?.openDrawer();
                                      },
                                    ),
                                    Text(
                                      _tabTitles[_currentIndex],
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: iconColor),
                                    ),
                                    const Spacer(),
                                    if (showLayoutMenu)
                                      PopupMenuButton<String>(
                                        icon: SvgPicture.string(
                                          CustomIcons.moreVert,
                                          width: 21.6,
                                          height: 21.6,
                                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        color: bgColor,
                                        offset: const Offset(0, 50),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'list',
                                            child: Row(
                                              children: [
                                                Icon(Icons.view_list, size: 20, color: iconColor),
                                                const SizedBox(width: 12),
                                                Text('Lista', style: TextStyle(color: iconColor)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'grid',
                                            child: Row(
                                              children: [
                                                Icon(Icons.grid_view, size: 20, color: iconColor),
                                                const SizedBox(width: 12),
                                                Text('Grade', style: TextStyle(color: iconColor)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'compact',
                                            child: Row(
                                              children: [
                                                Icon(Icons.view_compact, size: 20, color: iconColor),
                                                const SizedBox(width: 12),
                                                Text('Compacto', style: TextStyle(color: iconColor)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {},
                                      ),
                                    if (showPlusButton)
                                      IconButton(
                                        icon: SvgPicture.string(
                                          CustomIcons.plus,
                                          width: 21.6,
                                          height: 21.6,
                                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                        ),
                                        onPressed: () => _handlePlusButton(context),
                                      ),
                                    if (showSearchButton)
                                      IconButton(
                                        icon: SvgPicture.string(
                                          CustomIcons.search,
                                          width: 21.6,
                                          height: 21.6,
                                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                        ),
                                        onPressed: () {
                                          _hideKeyboard();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const SearchScreen()),
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
                                                icon: SvgPicture.string(
                                                  CustomIcons.inbox,
                                                  width: 21.6,
                                                  height: 21.6,
                                                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                                ),
                                                onPressed: () {
                                                  _hideKeyboard();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const MessagesScreen()),
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
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(5, (index) {
                          final active = _currentIndex == index;
                          final color = active ? _activeBlue : unselectedColor;
                          final svg = active ? _filledSvgs[index] : _outlinedSvgs[index];

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onTap(index),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.string(
                                    svg,
                                    width: 17.28,
                                    height: 17.28,
                                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _tabTitles[index],
                                    style: TextStyle(
                                      fontSize: 9.9,
                                      color: color,
                                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
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
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: topBorderColor, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(-4, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(5, (index) {
                              final active = _currentIndex == index;
                              final color = active ? _activeBlue : unselectedColor;
                              final svg = active ? _filledSvgs[index] : _outlinedSvgs[index];

                              return Expanded(
                                child: InkWell(
                                  onTap: () => _onTap(index),
                                  borderRadius: BorderRadius.circular(100),
                                  child: Center(
                                    child: SvgPicture.string(
                                      svg,
                                      width: 17.28,
                                      height: 17.28,
                                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              );
                            }),
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
      ),
    );
  }

  void _showNewPostModal(BuildContext context) async {
    _hideKeyboard();
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewPostModal(),
    );
  }
}