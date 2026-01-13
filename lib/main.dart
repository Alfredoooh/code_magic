import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
        ),
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
      backgroundColor: Colors.white,
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
      color: Colors.white,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIOSButton(
              onTap: () {},
              child: Text(
                '𝕏',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
                '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M16.6725 16.6412L21 21M19 11C19 15.4183 15.4183 19 11 19C6.58172 19 3 15.4183 3 11C3 6.58172 6.58172 3 11 3C15.4183 3 19 6.58172 19 11Z" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>''',
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
              color: isActive ? Colors.black : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.transparent,
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
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Comece a seguir pessoas para ver\no conteúdo delas aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
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
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
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
                color: Colors.grey.shade300,
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
                      color: Colors.grey.shade300,
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
                      color: Colors.grey.shade300,
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
                      color: Colors.grey.shade300,
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
                      color: Colors.grey.shade300,
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
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
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
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Symbols.verified, color: Colors.blue, size: 18, fill: 1),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          username,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
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
                            color: Colors.grey.shade200,
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
                      _buildActionButton(
                        Symbols.mode_comment,
                        comments,
                      ),
                      _buildActionButton(
                        Symbols.repeat,
                        retweets,
                      ),
                      _buildActionButton(
                        Symbols.favorite,
                        likes,
                      ),
                      _buildActionButton(Symbols.share, ''),
                      _buildActionButton(Symbols.bookmark, ''),
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

  Widget _buildActionButton(IconData icon, String count) {
    return _buildIOSButton(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
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
        color: Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m12,14c-1.103,0-2-.897-2-2s.897-2,2-2,2,.897,2,2-.897,2-2,2ZM3,10H0v4h3v-4Zm18,4h3v-4h-3v4Zm-2,0v-4c0-1.103.897-2,2-2h3c0-2.757-2.243-5-5-5h-6v5.142c1.72.447,3,1.999,3,3.858s-1.28,3.411-3,3.858v5.142h6c2.757,0,5-2.243,5-5h-3c-1.103,0-2-.897-2-2Zm-8,1.858c-1.72-.447-3-1.999-3-3.858s1.28-3.411,3-3.858V3h-6C2.243,3,0,5.243,0,8h3c1.103,0,2,.897,2,2v4c0,1.103-.897,2-2,2H0c0,2.757,2.243,5,5,5h6v-5.142Z"/>
                </svg>''',
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m19,3H5C2.243,3,0,5.243,0,8v8c0,2.757,2.243,5,5,5h14c2.757,0,5-2.243,5-5v-8c0-2.757-2.243-5-5-5Zm3,11h-2v-4h2v4Zm-10,0c-1.103,0-2-.897-2-2s.897-2,2-2,2,.897,2,2-.897,2-2,2ZM2,10h2v4h-2v-4Zm0,6h2c1.103,0,2-.897,2-2v-4c0-1.103-.897-2-2-2h-2c0-1.654,1.346-3,3-3h6v3.142c-1.72.447-3,1.999-3,3.858s1.28,3.411,3,3.858v3.142h-6c-1.654,0-3-1.346-3-3Zm17,3h-6v-3.142c1.72-.447,3-1.999,3-3.858s-1.28-3.411-3-3.858v-3.142h6c1.654,0,3,1.346,3,3h-2c-1.103,0-2,.897-2,2v4c0,1.103.897,2,2,2h2c0,1.654-1.346,3-3,3Z"/>
                </svg>''',
                'Início',
                0,
              ),
              _buildBottomNavItem(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m19,3H5C2.243,3,0,5.243,0,8v8c0,2.757,2.243,5,5,5h14c2.757,0,5-2.243,5-5v-8c0-2.757-2.243-5-5-5Zm3,11h-2v-4h2v4Zm-10,0c-1.103,0-2-.897-2-2s.897-2,2-2,2,.897,2,2-.897,2-2,2ZM2,10h2v4h-2v-4Zm0,6h2c1.103,0,2-.897,2-2v-4c0-1.103-.897-2-2-2h-2c0-1.654,1.346-3,3-3h6v3.142c-1.72.447-3,1.999-3,3.858s1.28,3.411,3,3.858v3.142h-6c-1.654,0-3-1.346-3-3Zm17,3h-6v-3.142c1.72-.447,3-1.999,3-3.858s-1.28-3.411-3-3.858v-3.142h6c1.654,0,3,1.346,3,3h-2c-1.103,0-2,.897-2,2v4c0,1.103.897,2,2,2h2c0,1.654-1.346,3-3,3Z"/>
                </svg>''',
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m12,14c-1.103,0-2-.897-2-2s.897-2,2-2,2,.897,2,2-.897,2-2,2ZM3,10H0v4h3v-4Zm18,4h3v-4h-3v4Zm-2,0v-4c0-1.103.897-2,2-2h3c0-2.757-2.243-5-5-5h-6v5.142c1.72.447,3,1.999,3,3.858s-1.28,3.411-3,3.858v5.142h6c2.757,0,5-2.243,5-5h-3c-1.103,0-2-.897-2-2Zm-8,1.858c-1.72-.447-3-1.999-3-3.858s1.28-3.411,3-3.858V3h-6C2.243,3,0,5.243,0,8h3c1.103,0,2,.897,2,2v4c0,1.103-.897,2-2,2H0c0,2.757,2.243,5,5,5h6v-5.142Z"/>
                </svg>''',
                'Partidas',
                1,
              ),
              _buildBottomNavItem(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m12,0C5.383,0,0,5.383,0,12s5.383,12,12,12,12-5.383,12-12S18.617,0,12,0Zm-4,21.164v-.164c0-2.206,1.794-4,4-4s4,1.794,4,4v.164c-1.226.537-2.578.836-4,.836s-2.774-.299-4-.836Zm9.925-1.113c-.456-2.859-2.939-5.051-5.925-5.051s-5.468,2.192-5.925,5.051c-2.47-1.823-4.075-4.753-4.075-8.051C2,6.486,6.486,2,12,2s10,4.486,10,10c0,3.298-1.605,6.228-4.075,8.051Zm-5.925-15.051c-2.206,0-4,1.794-4,4s1.794,4,4,4,4-1.794,4-4-1.794-4-4-4Zm0,6c-1.103,0-2-.897-2-2s.897-2,2-2,2,.897,2,2-.897,2-2,2Z"/>
                </svg>''',
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                  <path d="m12,0C5.383,0,0,5.383,0,12s5.383,12,12,12,12-5.383,12-12S18.617,0,12,0Zm-3.48,20.299c.107-1.835,1.619-3.299,3.48-3.299s3.373,1.464,3.48,3.299c-1.071.451-2.247.701-3.48.701s-2.409-.25-3.48-.701Zm9.668-1.781c-.84-2.617-3.296-4.518-6.188-4.518s-5.348,1.901-6.188,4.518c-1.727-1.641-2.812-3.953-2.812-6.518C3,7.037,7.038,3,12,3s9,4.037,9,9c0,2.565-1.084,4.877-2.812,6.518Zm-2.689-10.018c0,1.933-1.567,3.5-3.5,3.5s-3.5-1.567-3.5-3.5,1.567-3.5,3.5-3.5,3.5,1.567,3.5,3.5Z"/>
                </svg>''',
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
              isSelected ? Colors.blue : Colors.grey.shade500,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.blue : Colors.grey.shade500,
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