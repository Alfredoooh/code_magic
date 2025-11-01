import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_provider.dart';
import '../../localization/app_localizations.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../auth/login_screen.dart';
import '../posts/create_post_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await appProvider.loadUserSettings(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String t(String key) => AppLocalizations.translate(key, appProvider.currentLanguage);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
      
      // Facebook-style AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // Menu Button
              IconButton(
                icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              
              // Logo/Title
              const Text(
                'Fintech Social',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDB52A),
                ),
              ),
              
              const Spacer(),
              
              // Search
              IconButton(
                icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
                onPressed: () {},
              ),
              
              // Notifications
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () {},
              ),
              
              // Messages
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: isDark ? Colors.white : Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      
      // Drawer Menu
      drawer: _buildDrawer(context, authProvider, appProvider, isDark, t),
      
      // Body with Progress Bar
      body: _isLoading
          ? const Center(
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB52A)),
              ),
            )
          : _buildBody(isDark, t),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider authProvider,
    AppProvider appProvider,
    bool isDark,
    String Function(String) t,
  ) {
    final user = authProvider.currentUser;
    
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFDB52A),
                  const Color(0xFFFDB52A).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Profile Picture
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: user?.photoURL != null && user!.photoURL.isNotEmpty
                          ? ClipOval(
                              child: Image.network(user.photoURL, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.person, size: 40, color: Colors.black),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Name
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    // Nickname
                    Text(
                      user?.nickname ?? '@user',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // User Stats
          Container(
            color: isDark ? const Color(0xFF242526) : Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: t('online_users'),
                  value: '${appProvider.onlineUsersCount}',
                  isDark: isDark,
                ),
                const SizedBox(width: 20),
                if (user?.isPro == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (user?.isPremium == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Menu Items
          _buildDrawerItem(
            icon: Icons.home,
            title: t('home'),
            onTap: () => Navigator.pop(context),
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.person,
            title: t('profile'),
            onTap: () {},
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.settings,
            title: t('settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.notifications,
            title: t('notifications'),
            onTap: () {},
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.privacy_tip,
            title: t('privacy'),
            onTap: () {},
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.help,
            title: t('help'),
            onTap: () {},
            isDark: isDark,
          ),
          
          _buildDrawerItem(
            icon: Icons.info,
            title: t('about'),
            onTap: () {},
            isDark: isDark,
          ),
          
          const Divider(),
          
          _buildDrawerItem(
            icon: Icons.logout,
            title: t('logout'),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            isDark: isDark,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? (isDark ? Colors.white : Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black),
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBody(bool isDark, String Function(String) t) {
    final postProvider = Provider.of<PostProvider>(context);
    
    return CustomScrollView(
      slivers: [
        // Create Post Button
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242526) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: postProvider,
                      child: const CreatePostScreen(),
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFFDB52A),
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "What's on your mind?",
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFFFDB52A)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Posts Feed
        StreamBuilder<List<PostModel>>(
          stream: postProvider.getPostsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFFFDB52A),
                    ),
                  ),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.feed,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share something!',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return PostCard(post: snapshot.data![index]);
                  },
                  childCount: snapshot.data!.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}