/*import 'package:flutter/material.dart';
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
}*/

// pubspec.yaml
// dependencies:
//   flutter_quill: ^10.8.2
//   flutter:
//     sdk: flutter

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor de Texto Rico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearEditor() {
    _controller.clear();
  }

  void _showContent() {
    final json = _controller.document.toDelta().toJson();
    final plainText = _controller.document.toPlainText();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conteúdo do Editor'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Texto puro:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(plainText.trim().isEmpty ? '(vazio)' : plainText),
              const Divider(height: 24),
              const Text('Delta JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(json.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quill Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar',
            onPressed: _clearEditor,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Ver conteúdo',
            onPressed: _showContent,
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _controller,
              configurations: QuillSimpleToolbarConfigurations(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showClearFormat: true,
                showAlignmentButtons: true,
                showHeaderStyle: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: true,
                showCodeBlock: true,
                showQuote: true,
                showIndent: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
              ),
            ),
          ),

          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                configurations: const QuillEditorConfigurations(
                  placeholder: 'Comece a escrever algo incrível...',
                  padding: EdgeInsets.all(8),
                  autoFocus: false,
                  expands: true,
                  scrollable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}