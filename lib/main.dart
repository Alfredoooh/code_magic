// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/search_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurações de sistema UI (correção do teclado)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Configurações de orientação
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: 'PrinterLite',
            debugShowCheckedModeBanner: false,

            // Configurações para melhor comportamento do teclado
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  // Remove padding extra do teclado
                  viewInsets: EdgeInsets.zero,
                ),
                child: GestureDetector(
                  // Fecha o teclado ao tocar fora de campos de texto
                  onTap: () {
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus && 
                        currentFocus.focusedChild != null) {
                      currentFocus.focusedChild!.unfocus();
                    }
                  },
                  child: child!,
                ),
              );
            },

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
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
              // Configuração do input para evitar problemas com teclado
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              // Configuração do input para dark mode
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF3A3B3C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),

            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/otp': (context) => const OTPVerificationScreen(),
              '/home': (context) => HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/messages': (context) => const MessagesScreen(),
              '/search': (context) => const SearchScreen(),
            },
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
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isInitialized) {
      return const SplashScreen();
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    if (authProvider.needsOTPVerification) {
      return const OTPVerificationScreen();
    }

    return HomeScreen();
  }
}