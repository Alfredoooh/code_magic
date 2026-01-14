import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF18191A),
      extendBody: true,
      body: SafeArea(
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
      bottomNavigationBar: _buildBottomNavBar(),
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
      color: Color(0xFF18191A),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF242526),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3A3B3C), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIOSButton(
              onTap: () {},
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
              color: isActive ? Color(0xFFE4E6EB) : Color(0xFFB0B3B8),
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
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonPost(),
      );
    }

    return ListView(
      key: const ValueKey('para-voce'),
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
            Symbols.people_outline,
            size: 64,
            color: Color(0xFF3A3B3C),
          ),
          const SizedBox(height: 16),
          Text(
            'Comece a seguir pessoas para ver\no conteúdo delas aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFB0B3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3A3B3C), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF3A3B3C),
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
                      color: Color(0xFF3A3B3C),
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
                      color: Color(0xFF3A3B3C),
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
                      color: Color(0xFF3A3B3C),
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
                      color: Color(0xFF3A3B3C),
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
          color: Color(0xFF242526),
          border: Border(
            bottom: BorderSide(color: Color(0xFF3A3B3C), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE4E6EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Symbols.verified, color: Color(0xFF2374E1), size: 18, fill: 1),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          username,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFFB0B3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(' · ', style: TextStyle(color: Color(0xFFB0B3B8))),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFB0B3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: Color(0xFFE4E6EB),
                    ),
                  ),
                  if (hasVideo && videoUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                              Icon(
                                Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white,
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
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Color(0xFF3A3B3C),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(SvgIcons.comment, comments),
                      _buildActionButton(SvgIcons.retweet, retweets),
                      _buildActionButton(Symbols.favorite, likes),
                      _buildActionButton(Symbols.share, ''),
                      _buildActionButton(SvgIcons.bookmark, ''),
                    ],
                  ),
                ],
              ),
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
                Color(0xFFB0B3B8),
                BlendMode.srcIn,
              ),
            )
          else
            Icon(icon, size: 18, color: Color(0xFFB0B3B8)),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB0B3B8),
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
        color: Color(0xFF242526),
        border: Border(
          top: BorderSide(color: Color(0xFF3A3B3C), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? Color(0xFF2374E1) : Color(0xFFB0B3B8),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? Color(0xFF2374E1) : Color(0xFFB0B3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSButton({required VoidCallback onTap, required Widget child}) {
    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      closedBuilder: (context, action) => GestureDetector(
        onTap: onTap,
        child: child,
      ),
      openBuilder: (context, action) => Container(),
      tappable: false,
    );
  }
}