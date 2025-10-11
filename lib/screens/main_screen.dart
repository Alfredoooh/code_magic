import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import 'chats_list_screen.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;

  MainScreen({required this.onThemeChanged, required this.onLocaleChanged});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'online': isOnline,
        'last_seen': FieldValue.serverTimestamp(),
      });
    }
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1C1C1E)
            : Colors.white,
        activeColor: Color(0xFFFF444F),
        inactiveColor: Colors.grey,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF38383A)
                : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        height: 60,
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.home_rounded, size: 26),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.shopping_bag_rounded, size: 26),
            ),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.newspaper_rounded, size: 26),
            ),
            label: 'Novidades',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.chat_rounded, size: 26),
            ),
            label: 'Chat',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) => HomeScreen(
                userData: _userData,
                onThemeChanged: widget.onThemeChanged,
                onLocaleChanged: widget.onLocaleChanged,
              ),
            );
          case 1:
            return CupertinoTabView(
              builder: (context) => MarketplaceScreen(userData: _userData),
            );
          case 2:
            return CupertinoTabView(
              builder: (context) => NewsScreen(userData: _userData),
            );
          case 3:
            return CupertinoTabView(
              builder: (context) => ChatsListScreen(userData: _userData),
            );
          default:
            return CupertinoTabView(
              builder: (context) => HomeScreen(
                userData: _userData,
                onThemeChanged: widget.onThemeChanged,
                onLocaleChanged: widget.onLocaleChanged,
              ),
            );
        }
      },
    );
  }
}