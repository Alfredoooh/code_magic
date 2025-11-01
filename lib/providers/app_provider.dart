import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AppProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _currentLanguage = 'pt';
  ThemeMode _themeMode = ThemeMode.dark;
  int _onlineUsersCount = 0;
  UserSettings? _userSettings;
  
  String get currentLanguage => _currentLanguage;
  ThemeMode get themeMode => _themeMode;
  int get onlineUsersCount => _onlineUsersCount;
  UserSettings? get userSettings => _userSettings;

  AppProvider() {
    _loadPreferences();
    _listenToOnlineUsers();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'pt';
    String? theme = prefs.getString('theme');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> loadUserSettings(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('userSettings')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        _userSettings = UserSettings.fromFirestore(doc);
        _currentLanguage = _userSettings!.language;
        
        switch (_userSettings!.theme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        
        await _savePreferences();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  Future<void> changeLanguage(String languageCode, String? userId) async {
    _currentLanguage = languageCode;
    
    if (userId != null) {
      await _firestore.collection('userSettings').doc(userId).update({
        'language': languageCode,
      });
    }
    
    await _savePreferences();
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode, String? userId) async {
    _themeMode = mode;
    
    String themeString = 'system';
    if (mode == ThemeMode.light) {
      themeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeString = 'dark';
    }
    
    if (userId != null) {
      await _firestore.collection('userSettings').doc(userId).update({
        'theme': themeString,
      });
    }
    
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    
    String theme = 'system';
    if (_themeMode == ThemeMode.light) {
      theme = 'light';
    } else if (_themeMode == ThemeMode.dark) {
      theme = 'dark';
    }
    await prefs.setString('theme', theme);
  }

  void _listenToOnlineUsers() {
    _firestore.collection('onlineUsers').snapshots().listen((snapshot) {
      _onlineUsersCount = snapshot.docs.where((doc) => doc.data()['isOnline'] == true).length;
      notifyListeners();
    });
  }

  Future<void> clearAllActivities(String userId) async {
    try {
      // Clear user's posts
      QuerySnapshot posts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in posts.docs) {
        await doc.reference.delete();
      }
      
      // You can add more cleanup here (messages, notifications, etc.)
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing activities: $e');
    }
  }
}