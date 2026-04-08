// ============================================================
// pubspec.yaml — adicione estas dependências:
//
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_quill: ^10.8.2
//   flutter_quill_extensions: ^10.8.2   # imagens, vídeos, fórmulas
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor Rico Completo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
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
  bool _readOnly = false;
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _controller.addListener(_updateCounts);
  }

  void _updateCounts() {
    final text = _controller.document.toPlainText().trim();
    setState(() {
      _charCount = text.isEmpty ? 0 : text.length;
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCounts);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleReadOnly() {
    setState(() => _readOnly = !_readOnly);
  }

  void _clearEditor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar editor'),
        content: const Text('Tem certeza que deseja apagar todo o conteúdo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showDeltaJson() {
    final json = _controller.document.toDelta().toJson().toString();
    final plain = _controller.document.toPlainText();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conteúdo do documento'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(tabs: [Tab(text: 'Texto puro'), Tab(text: 'Delta JSON')]),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12),
                        child: SelectableText(plain.trim().isEmpty ? '(vazio)' : plain),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12),
                        child: SelectableText(json, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Rico'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          // Contador de palavras
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$_wordCount pal · $_charCount car',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          IconButton(
            icon: Icon(_readOnly ? Icons.edit : Icons.visibility),
            tooltip: _readOnly ? 'Editar' : 'Visualizar',
            onPressed: _toggleReadOnly,
          ),
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: 'Ver JSON',
            onPressed: _showDeltaJson,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar',
            onPressed: _clearEditor,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Toolbar completa ──────────────────────────────────
          if (!_readOnly)
            Container(
              color: theme.colorScheme.surfaceVariant,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: _controller,
                  configurations: QuillSimpleToolbarConfigurations(
                    // Histórico
                    showUndo: true,
                    showRedo: true,

                    // Fonte e tamanho
                    showFontFamily: true,
                    showFontSize: true,

                    // Formatação inline
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showInlineCode: true,
                    showSubscript: true,
                    showSuperscript: true,

                    // Cor
                    showColorButton: true,
                    showBackgroundColorButton: true,

                    // Limpeza
                    showClearFormat: true,

                    // Alinhamento
                    showAlignmentButtons: true,
                    showLeftAlignment: true,
                    showCenterAlignment: true,
                    showRightAlignment: true,
                    showJustifyAlignment: true,

                    // Direção de texto
                    showDirection: true,

                    // Cabeçalhos
                    showHeaderStyle: true,

                    // Listas
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: true,

                    // Indentação
                    showIndent: true,

                    // Blocos
                    showQuote: true,
                    showCodeBlock: true,

                    // Linha divisória
                    showDividers: true,

                    // Links
                    showLink: true,

                    // Busca
                    showSearchButton: true,

                    // Mídia (via flutter_quill_extensions)
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(
                      imageButtonOptions: QuillToolbarImageButtonOptions(),
                      videoButtonOptions: QuillToolbarVideoButtonOptions(),
                    ),
                  ),
                ),
              ),
            ),

          // Divider visual
          Divider(height: 1, color: theme.dividerColor),

          // ── Área de edição ────────────────────────────────────
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                configurations: QuillEditorConfigurations(
                  placeholder: 'Comece a escrever...',
                  padding: const EdgeInsets.all(8),
                  autoFocus: false,
                  expands: true,
                  scrollable: true,
                  readOnly: _readOnly,
                  showCursor: !_readOnly,
                  // Suporte a embeds (imagens e vídeos)
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
          ),

          // ── Barra de status ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: theme.colorScheme.surfaceVariant,
            child: Row(
              children: [
                Icon(
                  _readOnly ? Icons.lock_outline : Icons.edit_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  _readOnly ? 'Modo leitura' : 'Modo edição',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'flutter_quill 10.8.2',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}