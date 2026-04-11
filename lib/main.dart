import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'editor_page.dart';

void main() => runApp(const EditorApp());

class EditorApp extends StatelessWidget {
  const EditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF8F8F7),
        fontFamily: 'DMSans',
        useMaterial3: true,
      ),
      home: const EditorPage(),
    );
  }
}