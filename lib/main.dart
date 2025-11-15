// lib/main.dart (versão corrigida)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz; // Adicionado import estático
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/search_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

// Imports condicionais - só carrega no mobile
import 'services/push_notification_service.dart' if (dart.library.html) 'services/push_notification_service.dart';
import 'services/reminder_scheduler_service.dart' if (dart.library.html) 'services/reminder_scheduler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar timezone apenas no mobile
  if (!kIsWeb) {
    try {
      tz.initializeTimeZones(); // Corrigido para chamada estática
    } catch (e) {
      print('⚠️ Timezone não disponível na web');
    }
  }

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
          // Inicializar serviços apenas no mobile
          if (!kIsWeb && authProvider.isAuthenticated && authProvider.user != null) {
            _initializeUserServices(authProvider.user!.uid);
          }

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
            home: const AuthWrapper(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/otp': (context) => const OTPVerificationScreen(),
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/messages': (context) => const MessagesScreen(),
              '/search': (context) => const SearchScreen(),
            },
          );
        },
      ),
    );
  }

  void _initializeUserServices(String userId) {
    // Só inicializa notificações no mobile
    if (!kIsWeb) {
      try {
        PushNotificationService().initialize(userId);
        ReminderSchedulerService().initialize(userId);
        print('✅ Serviços de notificações inicializados');
      } catch (e) {
        print('⚠️ Erro ao inicializar serviços: $e');
      }
    }
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

    return const HomeScreen();
  }
}