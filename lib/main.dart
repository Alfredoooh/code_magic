import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/main_screen.dart';
import 'services/theme_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ThemeService.init();
  // força statusbar style compatível com tema
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarBrightness: ThemeService.isDarkMode ? Brightness.dark : Brightness.light));
  runApp(const ChatApp());
}

/// Global scroll behaviour para bounce estilo iOS
class BouncingScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics();
}

class ChatApp extends StatefulWidget {
  const ChatApp({Key? key}) : super(key: key);
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easify',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.getThemeData(),
      scrollBehavior: BouncingScrollBehavior(), // iOS-like scrolling
      home: const AuthGate(),
      routes: {
        '/main': (context) => MainScreen(),
      },
      // Força uso de Cupertino-style overlays (more iOS look)
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ThemeService.isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
