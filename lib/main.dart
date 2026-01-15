import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import 'svg_icons.dart';

void main() {
  runApp(const SocialFeedApp());
}

class SocialFeedApp extends StatelessWidget {
  const SocialFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed Social',
      theme: ThemeData(
        fontFamily: '-apple-system',
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF2374E1),
          secondary: Color(0xFF2374E1),
          background: Color(0xFF18191A),
          surface: Color(0xFF242526),
        ),
        scaffoldBackgroundColor: Color(0xFF18191A),
      ),
      home: const SocialFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({Key? key}) : super(key: key);

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  bool _isLoading = true;
  bool _isDrawerOpen = false;
  bool _isDarkTheme = true;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _drawerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
    _contentSlideAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
    if (_isDrawerOpen) {
      _drawerAnimationController.forward();
    } else {
      _drawerAnimationController.reverse();
    }
  }

  Color get _bgColor => _isDarkTheme ? Color(0xFF18191A) : Color(0xFFF0F2F5);
  Color get _surfaceColor => _isDarkTheme ? Color(0xFF242526) : Colors.white;
  Color get _textColor => _isDarkTheme ? Color(0xFFE4E6EB) : Color(0xFF050505);
  Color get _subTextColor => _isDarkTheme ? Color(0xFFB0B3B8) : Color(0xFF65676B);
  Color get _borderColor => _isDarkTheme ? Color(0xFF3A3B3C) : Color(0xFFDDDFE2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      body: Stack(
        children: [
          // Main content with slide animation
          AnimatedBuilder(
            animation: _contentSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * _contentSlideAnimation.value,
                  0,
                ),
                child: Transform.scale(
                  scale: 1.0 - (_contentSlideAnimation.value * 0.1),
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_contentSlideAnimation.value * 20),
                    child: AbsorbPointer(
                      absorbing: _isDrawerOpen,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            _buildHeader(),
                            Expanded(
                              child: _buildCurrentTab(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Drawer overlay
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: AnimatedOpacity(
                opacity: _isDrawerOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          // Drawer
          AnimatedBuilder(
            animation: _drawerSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * _drawerSlideAnimation.value,
                  0,
                ),
                child: _buildDrawer(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _contentSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width * _contentSlideAnimation.value,
              0,
            ),
            child: _buildBottomNavBar(),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: _surfaceColor,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header do drawer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20'),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu Nome',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        Text(
                          '@seunome',
                          style: TextStyle(
                            fontSize: 14,
                            color: _subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleDrawer,
                    icon: Icon(Icons.close, color: _textColor),
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor, height: 1),
            // Switch de tema
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    _isDarkTheme ? Ionicons.moon : Ionicons.sunny,
                    color: _textColor,
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isDarkTheme ? 'Modo Escuro' : 'Modo Claro',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textColor,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isDarkTheme,
                    activeColor: Color(0xFF2374E1),
                    onChanged: (value) {
                      setState(() {
                        _isDarkTheme = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(color: _borderColor, height: 1),
            // Menu items
            _buildDrawerItem(Ionicons.person_outline, 'Perfil'),
            _buildDrawerItem(Ionicons.settings_outline, 'Configurações'),
            _buildDrawerItem(Ionicons.bookmark_outline, 'Salvos'),
            _buildDrawerItem(Ionicons.notifications_outline, 'Notificações'),
            _buildDrawerItem(Ionicons.help_circle_outline, 'Ajuda'),
            Spacer(),
            Divider(color: _borderColor, height: 1),
            _buildDrawerItem(Ionicons.log_out_outline, 'Sair', isLogout: true),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isLogout = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : _textColor,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isLogout ? Colors.red : _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_selectedBottomTab == 0) {
      return _selectedTab == 0 ? _buildParaVoceTab() : _buildSeguindoTab();
    } else if (_selectedBottomTab == 1) {
      return _buildEmptyTab('Partidas');
    } else {
      return _buildEmptyTab('Perfil');
    }
  }

  Widget _buildEmptyTab(String title) {
    return Container(
      key: ValueKey(title),
      color: _bgColor,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIOSButton(
              onTap: _toggleDrawer,
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFF2374E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'F',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopTabButton('Para você', 0),
                const SizedBox(width: 24),
                _buildTopTabButton('Seguindo', 1),
              ],
            ),
            _buildIOSButton(
              onTap: () {},
              child: SvgPicture.string(
                SvgIcons.search,
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabButton(String text, int index) {
    final isActive = _selectedTab == index;
    return _buildIOSButton(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _isLoading = true;
        });
        _loadContent();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? _textColor : _subTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF2374E1) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParaVoceTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonPost(),
      );
    }

    return ListView(
      key: const ValueKey('para-voce'),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        _buildPost(
          avatar: 'https://i.pravatar.cc/150?img=1',
          name: 'João Silva',
          username: '@joaosilva',
          time: '2h',
          content: 'Acabei de testar o novo recurso e está incrível! 🚀',
          hasVideo: true,
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          comments: '389',
          retweets: '3.5K',
          likes: '4.6M',
        ),
        SizedBox(height: 12),
        _buildPost(
          avatar: 'https://i.pravatar.cc/150?img=12',
          name: 'Manoj Kumar',
          username: '@manojdotdev',
          time: '7h',
          content: 'is there any laptop better than MacBook ?',
          imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
          comments: '112',
          retweets: '2',
          likes: '182',
        ),
        SizedBox(height: 12),
        _buildPost(
          avatar: 'https://i.pravatar.cc/150?img=33',
          name: 'UI/UX Savior',
          username: '@UiSavior',
          time: '3h',
          content: 'A or B?',
          imageUrl: 'https://images.unsplash.com/photo-1581291518633-83b4ebd1d83e?w=800',
          comments: '45',
          retweets: '12',
          likes: '234',
        ),
      ],
    );
  }

  Widget _buildSeguindoTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 3,
        itemBuilder: (context, index) => _buildSkeletonPost(),
      );
    }

    return Center(
      key: const ValueKey('seguindo'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.people_outline,
            size: 64,
            color: _borderColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Comece a seguir pessoas para ver\no conteúdo delas aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: _subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _borderColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(
                  child: Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildShimmer(
                  child: Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildShimmer(
                  child: Container(
                    width: 200,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildShimmer(
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      onEnd: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      },
      child: child,
    );
  }

  Widget _buildPost({
    required String avatar,
    required String name,
    required String username,
    required String time,
    required String content,
    String? imageUrl,
    bool hasVideo = false,
    String? videoUrl,
    required String comments,
    required String retweets,
    required String likes,
  }) {
    return _buildIOSButton(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIOSButton(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatar),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Symbols.verified, color: Color(0xFF2374E1), size: 16, fill: 1),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 13,
                              color: _subTextColor,
                            ),
                          ),
                          Text(' · ', style: TextStyle(color: _subTextColor)),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 13,
                              color: _subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Ionicons.ellipsis_horizontal, color: _subTextColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: _textColor,
              ),
            ),
            if (hasVideo && videoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=800',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Ionicons.play,
                            size: 32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: _borderColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(SvgIcons.comment, comments),
                _buildActionButton(SvgIcons.retweet, retweets),
                _buildActionButton(Symbols.favorite, likes),
                _buildActionButton(Symbols.share, ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(dynamic icon, String count) {
    return _buildIOSButton(
      onTap: () {},
      child: Row(
        children: [
          if (icon is String)
            SvgPicture.string(
              icon,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                _subTextColor,
                BlendMode.srcIn,
              ),
            )
          else
            Icon(icon, size: 18, color: _subTextColor),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _subTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          top: BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                SvgIcons.homeOutline,
                SvgIcons.homeFilled,
                'Início',
                0,
              ),
              _buildBottomNavItem(
                SvgIcons.matchesOutline,
                SvgIcons.matchesFilled,
                'Partidas',
                1,
              ),
              _buildBottomNavItem(
                SvgIcons.profileOutline,
                SvgIcons.profileFilled,
                'Perfil',
                2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String outlinedSvg,
    String filledSvg,
    String label,
    int index,
  ) {
    final isSelected = _selectedBottomTab == index;
    return _buildIOSButton(
      onTap: () {
        setState(() {
          _selectedBottomTab = index;
          if (index == 0) {
            _isLoading = true;
            _loadContent();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.string(
            isSelected ? filledSvg : outlinedSvg,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              isSelected ? Color(0xFF2374E1) : _subTextColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? Color(0xFF2374E1) : _subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}