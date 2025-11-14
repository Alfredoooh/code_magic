import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
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
import 'services/push_notification_service.dart';
import 'services/reminder_scheduler_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar timezone para notificações locais
  tz.initializeTimeZones();
  
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
          // Inicializar serviços quando usuário faz login
          if (authProvider.isAuthenticated && authProvider.user != null) {
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
    // Inicializar push notifications
    PushNotificationService().initialize(userId);
    
    // Inicializar scheduler de lembretes
    ReminderSchedulerService().initialize(userId);
    
    print('✅ Serviços de notificações e lembretes inicializados para o usuário: $userId');
  }
}

// Widget que decide qual tela mostrar baseado no estado de autenticação
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Aguarda a inicialização - mostra splash
    if (!authProvider.isInitialized) {
      return const SplashScreen();
    }

    // Se não está autenticado, vai para login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Se está autenticado mas precisa verificar OTP, vai para OTP
    if (authProvider.needsOTPVerification) {
      return const OTPVerificationScreen();
    }

    // Se está tudo OK, vai para home
    return const HomeScreen();
  }
}