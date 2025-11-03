/* import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/search_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Cashnet',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              primaryColor: const Color(0xFFFDB52A),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFDB52A),
                secondary: Color(0xFFFFD700),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1A1A1A),
              primaryColor: const Color(0xFFFDB52A),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFDB52A),
                secondary: Color(0xFFFFD700),
                surface: Color(0xFF242526),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF242526),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            themeMode: themeProvider.themeMode,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/messages': (context) => const MessagesScreen(),
              '/search': (context) => const SearchScreen(),
            },
          );
        },
      ),
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webview_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Modo edge-to-edge para o WebView ficar abaixo da status bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WebViewScreen(),
    );
  }
}