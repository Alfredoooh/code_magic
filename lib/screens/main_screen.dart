import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/theme_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/hub_tab.dart';
import 'tabs/converter_tab.dart';
import 'tabs/news_tab.dart';
import 'tabs/chat_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    HomeTab(),
    HubTab(),
    ConverterTab(),
    NewsTab(),
    ChatTab(),
  ];

  @override
  void initState() {
    super.initState();
    _updateLastActivity();
  }

  Future<void> _updateLastActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ThemeService.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: ThemeService.backgroundColor,
            selectedItemColor: const Color(0xFF1877F2),
            unselectedItemColor: ThemeService.isDarkMode
                ? Colors.white.withOpacity(0.5)
                : Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            enableFeedback: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_grid_2x2),
                activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
                label: 'Hub',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.arrow_2_squarepath),
                activeIcon: Icon(CupertinoIcons.arrow_2_squarepath),
                label: 'Conversor',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.news),
                activeIcon: Icon(CupertinoIcons.news_solid),
                label: 'Atualidade',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble_2),
                activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                label: 'Chats',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
