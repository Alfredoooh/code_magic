import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'models/app_theme.dart';
import 'models/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatefulWidget {
  static final GlobalKey<_ChatAppState> appKey = GlobalKey<_ChatAppState>();

  ChatApp() : super(key: appKey);

  @override
  _ChatAppState createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'pt';

  void updateTheme(String theme) {
    setState(() {
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void updateLanguage(String language) {
    setState(() {
      _language = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K Paga',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AuthGate(language: _language),
      debugShowCheckedModeBanner: false,
      locale: Locale(_language),
    );
  }
}

class AuthGate extends StatelessWidget {
  final String language;

  const AuthGate({required this.language});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF444F)),
                  ),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                _createUserDocument(snapshot.data!);
                return Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF444F)),
                  ),
                );
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              
              if (userData['access'] == false) {
                return _buildAccessDeniedScreen(context);
              }

              return MainScreen(language: language);
            },
          );
        }
        return AuthScreen();
      },
    );
  }

  Future<void> _createUserDocument(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'id': user.uid,
      'username': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'email': user.email,
      'full_name': user.displayName ?? '',
      'phone': '',
      'access': true,
      'expiration_date': DateTime.now().add(Duration(days: 7)).toIso8601String(),
      'user_key': 'FREE-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': FieldValue.serverTimestamp(),
      'profile_image': 'https://ui-avatars.com/api/?name=${user.displayName ?? 'User'}&background=FF444F&color=fff',
      'role': 'user',
      'blocked': false,
      'failed_attempts': 0,
      'blocked_until': null,
      'theme': 'dark',
      'language': 'pt',
      'is_pro': false,
      'is_admin': false,
      'tokens_used_today': 0,
      'max_daily_tokens': 50,
      'last_token_reset': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block_rounded,
                size: 100,
                color: Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                'Acesso Negado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Sua conta não tem permissão de acesso.\nEntre em contato com o administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF444F),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sair',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}