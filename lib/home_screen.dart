// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// IMPORTS DAS OUTRAS TELAS
import 'markets_screen.dart';
import 'posts_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  late final List<Widget> _tabs;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabs = [
      MarketsScreen(token: widget.token),
      PostsScreen(token: widget.token),
    ];
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openTradeScreen() {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => TradeScreen(token: widget.token),
      ),
    );
  }

  void _openBotsScreen() {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => BotsScreen(token: widget.token),
      ),
    );
  }

  void _openCreatePostScreen() {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => CreatePostScreen(token: widget.token),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    
    if (details.primaryVelocity! > 0) {
      // Deslizar para direita - vai para Mercados
      if (_currentTabIndex == 1) {
        setState(() => _currentTabIndex = 0);
      }
    } else if (details.primaryVelocity! < 0) {
      // Deslizar para esquerda - vai para Publicações
      if (_currentTabIndex == 0) {
        setState(() => _currentTabIndex = 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);
    final isPostsTab = _currentTabIndex == 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF1A1A1A),
              const Color(0xFF2A2A2A),
              opacity,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isPostsTab ? Icons.add_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
              onPressed: isPostsTab ? _openCreatePostScreen : _toggleSearch,
            ),
            title: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: const Color(0xFF2A2A2A),
              thumbColor: const Color(0xFF0066FF),
              groupValue: _currentTabIndex,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentTabIndex = value;
                    _showSearchBar = false;
                    _searchController.clear();
                  });
                }
              },
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Mercados', style: TextStyle(fontSize: 14)),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Publicações', style: TextStyle(fontSize: 14)),
                ),
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PortfolioScreen(token: widget.token),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: _tabs,
            ),
            // Search Bar Overlay
            if (_showSearchBar && !isPostsTab)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showSearchBar ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      color: Colors.black.withOpacity(0.95),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: const Color(0xFF0066FF).withOpacity(0.3),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'Pesquisar mercados...',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                            color: Color(0xFF0066FF),
                                          ),
                                          suffixIcon: _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.white54,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _searchController.clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 15,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: _toggleSearch,
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Color(0xFF0066FF),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _searchController.text.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_rounded,
                                            size: 64,
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Pesquisar mercados',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        Text(
                                          'Resultados para "${_searchController.text}"',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Aqui você pode adicionar os resultados da pesquisa
                                        Center(
                                          child: Text(
                                            'Nenhum resultado encontrado',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Search Bar for Posts Tab
            if (isPostsTab)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar publicações...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onTap: () {
                          // Implementar busca de publicações
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: !isPostsTab
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openTradeScreen,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(28),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C896), Color(0xFF00A075)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C896).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Negociar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 56,
                      color: Colors.black,
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openBotsScreen,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(28),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Automatizar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Animação iOS Slide Up
class IOSSlideUpRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  IOSSlideUpRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;
            var curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}