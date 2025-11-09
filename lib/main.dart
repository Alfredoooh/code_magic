import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/invest_screen.dart';
import 'screens/bets_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/search_screen.dart';
import 'screens/otp_verification_screen.dart';
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
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: 'PrinterLite',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF0F2F5),
              primaryColor: const Color(0xFF1877F2),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1877F2),
                secondary: Color(0xFF42B72A),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF18191A),
              primaryColor: const Color(0xFF1877F2),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF1877F2),
                secondary: Color(0xFF42B72A),
                surface: Color(0xFF242526),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF242526),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: _getInitialScreen(authProvider),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/otp-verification': (context) => const OTPVerificationScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/invest': (context) => const InvestScreen(),
              '/bets': (context) => const BetsScreen(),
              '/messages': (context) => const MessagesScreen(),
              '/search': (context) => const SearchScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AuthProvider authProvider) {
    // Enquanto está inicializando, mostra splash
    if (!authProvider.isInitialized) {
      return const SplashScreen();
    }

    // Se está autenticado
    if (authProvider.isAuthenticated) {
      // Verifica se o email foi verificado
      final isEmailVerified = authProvider.userData?['emailVerified'] == true;
      
      if (!isEmailVerified) {
        // FORÇA a tela de OTP se o email não foi verificado
        return const OTPVerificationScreen();
      }
      
      // Se tudo ok, vai para home
      return const HomeScreen();
    }

    // Se não está autenticado, vai para login
    return const LoginScreen();
  }
}