import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth_logic.dart';
import 'styles.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthLogic(),
      child: const ChatApp(),
    ),
  );
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthLogic>(
      builder: (context, authLogic, _) {
        return MaterialApp(
          title: 'Chat Firebase',
          theme: AppStyles.lightTheme,
          darkTheme: AppStyles.darkTheme,
          themeMode: authLogic.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthLogic>(
      builder: (context, authLogic, _) {
        if (authLogic.isAuthenticated) {
          return const ChatScreen();
        }
        return const LoginScreen();
      },
    );
  }
}