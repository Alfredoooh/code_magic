import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'providers/post_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'CashNet',
            debugShowCheckedModeBanner: false,
            
            // Theme Configuration
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: const Color(0xFFFDB52A),
              scaffoldBackgroundColor: Colors.grey[100],
              colorScheme: ColorScheme.light(
                primary: const Color(0xFFFDB52A),
                secondary: const Color(0xFFFDB52A),
                surface: Colors.white,
                background: Colors.grey[100]!,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              fontFamily: 'SF Pro Display',
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
              fontFamily: 'SF Pro Display',
            ),
            
            themeMode: appProvider.themeMode,
            
            // Initial Route
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Show loading while checking auth state
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFDB52A),
                      ),
                    ),
                  );
                }
                
                // Navigate based on auth state
                return authProvider.isAuthenticated
                    ? const MainScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

// Splash Screen (Optional)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDB52A), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.attach_money,
                size: 100,
                color: Colors.black,
              ),
              SizedBox(height: 20),
              Text(
                'Fintech Social',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your Social Finance Network',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}