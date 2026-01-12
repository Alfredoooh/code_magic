import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';

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
        primarySwatch: Colors.blue,
        fontFamily: '-apple-system',
        useMaterial3: true,
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: _buildCurrentTab(),
              ),
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
      return _buildSearchTab();
    } else if (_selectedBottomTab == 2) {
      return _buildNotificationsTab();
    } else {
      return _buildMessagesTab();
    }
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.8),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIOSButton(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=50'),
                  ),
                ),
                Text(
                  _getHeaderTitle(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                _buildIOSButton(
                  onTap: () {},
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade900,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedBottomTab == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSegmentedControl(),
            ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_selectedBottomTab) {
      case 0:
        return 'Feed';
      case 1:
        return 'Buscar';
      case 2:
        return 'Notificações';
      case 3:
        return 'Mensagens';
      default:
        return 'Feed';
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1F767680),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton('Para você', 0),
          _buildSegmentButton('Seguindo', 1),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String text, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _isLoading = true;
        });
        _loadContent();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
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
            Icons.people_outline,
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

  Widget _buildSearchTab() {
    return ListView(
      key: const ValueKey('search'),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Text(
                'Buscar',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tendências para você',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTrendingItem('Tecnologia', '#Flutter', '15.2K posts'),
        _buildTrendingItem('Design', '#UIUXDesign', '8.7K posts'),
        _buildTrendingItem('Programação', '#DevLife', '23.4K posts'),
        _buildTrendingItem('IA', '#MachineLearning', '45.1K posts'),
      ],
    );
  }

  Widget _buildTrendingItem(String category, String hashtag, String posts) {
    return _buildIOSButton(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hashtag,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  posts,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return ListView(
      key: const ValueKey('notifications'),
      children: [
        _buildNotificationItem(
          avatar: 'https://i.pravatar.cc/150?img=5',
          icon: Icons.favorite,
          iconColor: Colors.red,
          text: 'Maria Silva curtiu sua publicação',
          time: '5m',
        ),
        _buildNotificationItem(
          avatar: 'https://i.pravatar.cc/150?img=8',
          icon: Icons.repeat,
          iconColor: Colors.green,
          text: 'Carlos Mendes compartilhou sua publicação',
          time: '1h',
        ),
        _buildNotificationItem(
          avatar: 'https://i.pravatar.cc/150?img=15',
          icon: Icons.person_add,
          iconColor: Colors.blue,
          text: 'Ana Costa começou a seguir você',
          time: '3h',
        ),
        _buildNotificationItem(
          avatar: 'https://i.pravatar.cc/150?img=20',
          icon: Icons.chat_bubble,
          iconColor: Colors.blue,
          text: 'Pedro Alves comentou: "Muito bom!"',
          time: '5h',
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required String avatar,
    required IconData icon,
    required Color iconColor,
    required String text,
    required String time,
  }) {
    return _buildIOSButton(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatar),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return ListView(
      key: const ValueKey('messages'),
      children: [
        _buildMessageItem(
          avatar: 'https://i.pravatar.cc/150?img=25',
          name: 'Julia Santos',
          message: 'Oi! Tudo bem? Vi sua publicação...',
          time: '10m',
          unread: true,
        ),
        _buildMessageItem(
          avatar: 'https://i.pravatar.cc/150?img=30',
          name: 'Roberto Lima',
          message: 'Valeu pela dica!',
          time: '1h',
          unread: false,
        ),
        _buildMessageItem(
          avatar: 'https://i.pravatar.cc/150?img=35',
          name: 'Fernanda Costa',
          message: 'Podemos conversar sobre o projeto?',
          time: '3h',
          unread: true,
        ),
        _buildMessageItem(
          avatar: 'https://i.pravatar.cc/150?img=40',
          name: 'Lucas Oliveira',
          message: 'Perfeito! Até amanhã então',
          time: '1d',
          unread: false,
        ),
      ],
    );
  }

  Widget _buildMessageItem({
    required String avatar,
    required String name,
    required String message,
    required String time,
    required bool unread,
  }) {
    return _buildIOSButton(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(avatar),
                ),
                if (unread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: unread ? Colors.grey.shade900 : Colors.grey.shade500,
                      fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      Icon(Icons.verified, color: Colors.blue, size: 18),
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
                  if (hasVideo) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.grey.shade400,
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
                        Icons.chat_bubble_outline,
                        comments,
                      ),
                      _buildActionButton(
                        Icons.repeat,
                        retweets,
                      ),
                      _buildActionButton(
                        Icons.favorite_border,
                        likes,
                      ),
                      _buildActionButton(Icons.share_outlined, ''),
                      _buildActionButton(Icons.bookmark_border, ''),
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
        color: Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.8),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.home, Icons.home_outlined, 'Início', 0),
              _buildBottomNavItem(Icons.search, Icons.search, 'Buscar', 1),
              _buildBottomNavItem(Icons.notifications, Icons.notifications_outlined, 'Alertas', 2),
              _buildBottomNavItem(Icons.mail, Icons.mail_outline, 'Mensagens', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData filledIcon,
    IconData outlinedIcon,
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
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected ? Colors.blue : Colors.grey.shade500,
            size: 24,
          ),
          const SizedBox(height: 2),
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
