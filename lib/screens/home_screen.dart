// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';           // ← teus SVGs
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

  final List<String> _tabTitles = [
    'Início', 'Ativos', 'Apps', 'Diário', 'Novo Pedido',
  ];

  // === SVGs outlined e filled (adapta se os nomes forem diferentes no teu custom_icons.dart) ===
  final List<String> _outlined = [
    CustomIcons.home,
    CustomIcons.users,
    CustomIcons.apps,
    CustomIcons.book,
    CustomIcons.addCircle,
  ];

  final List<String?> _filled = [
    CustomIcons.homeFilled,
    CustomIcons.usersFilled,
    CustomIcons.appsFilled,
    CustomIcons.bookFilled,
    CustomIcons.addCircleFilled,
  ];

  Widget _getPage(int index) {
    if (_pages[index] != null) return _pages[index]!;
    switch (index) {
      case 1: _pages[1] = const UsersScreen(); break;
      case 2: _pages[2] = const AppsScreen(); break;
      case 3: _pages[3] = const DiaryScreen(); break;
      case 4: _pages[4] = const DocumentRequestsScreen(); break;
    }
    return _pages[index] ?? const SizedBox.shrink();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    FocusScope.of(context).unfocus(); // teclado desaparece limpo
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().needsOTPVerification) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OTPVerificationScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: const CustomDrawer(),
        resizeToAvoidBottomInset: false, // ← teclado desaparece sem deixar "buraco"
        body: Stack(
          children: [
            // Conteúdo principal (top bar + páginas)
            Column(
              children: [
                // Top bar igual ao teu código antigo
                Container(
                  color: isDark ? const Color(0xFF242526) : Colors.white,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _scaffoldKey.currentState?.openDrawer(),
                            child: SvgIcon(svgString: CustomIcons.menu, size: 24, color: theme.iconTheme.color),
                          ),
                          const SizedBox(width: 12),
                          Text(_tabTitles[_currentIndex], style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          // aqui podes voltar a pôr os botões de + / search / inbox se quiseres
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(5, _getPage),
                  ),
                ),
              ],
            ),

            // BOTTOM NAVBAR IGUALZINHO AO TEU PRIMEIRO EXEMPLO
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
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
                  children: List.generate(5, (i) {
                    final active = _currentIndex == i;
                    final svg = active && _filled[i] != null ? _filled[i]! : _outlined[i];
                    final color = active ? theme.primaryColor : unselectedColor;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTapped(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgIcon(svgString: svg, size: 17.3, color: color), // -20% de 21.6
                            const SizedBox(height: 4),
                            Text(
                              _tabTitles[i].split(' ').first, // só a primeira palavra para caber
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
    );
  }
}