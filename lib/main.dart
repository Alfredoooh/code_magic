import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAyaGnNyc2tfV8hoQ6Pr4VM25iinM70AUM",
        authDomain: "chat00-7f1b1.firebaseapp.com",
        projectId: "chat00-7f1b1",
        storageBucket: "chat00-7f1b1.firebasestorage.app",
        messagingSenderId: "557234773917",
        appId: "1:557234773917:web:23702e6673d73d58835974",
        measurementId: "G-ZZKGKF1QN5",
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'CashNet',
            debugShowCheckedModeBanner: false,
            
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: const Color(0xFFFDB52A),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              colorScheme: ColorScheme.light(
                primary: const Color(0xFFFDB52A),
                secondary: const Color(0xFFFDB52A),
                surface: Colors.white,
                background: const Color(0xFFF5F5F5),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFFFDB52A),
              scaffoldBackgroundColor: const Color(0xFF1A1A1A),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFDB52A),
                secondary: Color(0xFFFDB52A),
                surface: Color(0xFF242526),
                background: Color(0xFF1A1A1A),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF242526),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            
            themeMode: appProvider.themeMode,
            
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFDB52A),
              ),
            ),
          );
        }
        
        return authProvider.isAuthenticated
            ? const MainScreen()
            : const LoginScreen();
      },
    );
  }
}