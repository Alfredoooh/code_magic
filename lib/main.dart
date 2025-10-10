import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/converter_screen.dart';
import 'widgets/design_system.dart';
import 'localization/app_localizations.dart';
// Remove duplicate import - keep only one NotificationsScreen
import 'screens/notifications_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppProvider()),
    ],
    child: KPagaApp(),
  ));
}

class KPagaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'K_paga',
          theme: appProvider.currentTheme,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('pt', 'PT'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('de', 'DE'),
            Locale('it', 'IT'),
            Locale('ru', 'RU'),
            Locale('zh', 'CN'),
            Locale('ja', 'JP'),
            Locale('ko', 'KR'),
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: appProvider.locale,
          home: AuthGate(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/send_receive': (context) => SendReceiveScreen(),
            '/deposit': (context) => DepositScreen(),
            '/converter': (context) => ConverterScreen(),
            '/notifications': (context) => NotificationsScreen(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}

// Placeholder screens if they don't exist yet
class SendReceiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send/Receive')),
      body: Center(child: Text('Send/Receive Screen')),
    );
  }
}

class DepositScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deposit')),
      body: Center(child: Text('Deposit Screen')),
    );
  }
}