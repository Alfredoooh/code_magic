import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DoctionApp());
}

// ─── APP ─────────────────────────────────────────────────────────────────────
class DoctionApp extends StatelessWidget {
  const DoctionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doction',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: T.accent,
        scaffoldBackgroundColor: T.bg,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      ),
      home: const EditorScreen(),
    );
  }
}
