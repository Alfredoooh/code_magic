import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Color(0xFFFF8C42),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFFF8C42),
          secondary: Color(0xFFFF8C42),
        ),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}