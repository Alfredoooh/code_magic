import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EditorApp());
}

class EditorApp extends StatelessWidget {
  const EditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Editor',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F8F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final QuillController _controller = QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();

  bool _drawerOpen = false;
  bool _a4Mode = false;
  bool _showFontPicker = false;
  bool _showSizePicker = false;
  bool _showColorPicker = false;
  bool _showInsertMenu = false;
  bool _showFormatMenu = false;
  OverlayEntry? _overlay;

  static const List<String> _fonts = <String>[
    'Lora',
    'Georgia',
    'Times New Roman',
    'Arial',
    'Helvetica Neue',
    'Verdana',
    'Courier New',
    'DM Sans',
    'Roboto',
    'Poppins',
    'Montserrat',
    'Nunito',
    'Source Serif 4',
    'Merriweather',
    'Playfair Display',
    'Cormorant Garamond',
    'EB Garamond',
    'Libre Baskerville',
    'Crimson Text',
    'PT Serif',
    'Spectral',
    'Bitter',
    'Vollkorn',
    'Alegreya',
    'Cinzel',
    'Pacifico',
    'Dancing Script',
    'Great Vibes',
    'Sacramento',
    'Caveat',
    'Kalam',
    'Patrick Hand',
  ];

  static const List<double> _sizes = <double>[
    8, 10, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72,
  ];

  static const List<String> _colors = <String>[
    '#000000', '#34322d', '#5e5e5b', '#858481', '#d1d5db', '#e5e7eb', '#f3f4f6', '#ffffff',
    '#dc2626', '#ea580c', '#d97706', '#ca8a04', '#65a30d', '#16a34a', '#0891b2', '#2563eb',
    '#4f46e5', '#7c3aed', '#9333ea', '#db2777', '#fca5a5', '#fdba74', '#fcd34d', '#86efac',
    '#93c5fd', '#c4b5fd', '#f9a8d4', '#fde68a', '#6ee7b7', '#a5b4fc', '#fbcfe8', '#e9d5ff',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = '';
  }

  @override
  void dispose() {
    _overlay?.remove();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _drawerOpen = !_drawerOpen);
  }

  void _closeDrawer() {
    if (_drawerOpen) setState(() => _drawerOpen = false);
  }

  void _toggleMode() {
    setState(() => _a4Mode = !_a4Mode);
  }

  void _ensureFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _format(Attribute attr) {
    _ensureFocus();
    _controller.formatSelection(attr);
  }

  void _toggleStyle(Attribute attr) {
    _ensureFocus();
    _controller.formatSelection(attr);
  }

  void _setColor(String hex) {
    _format(Attribute.fromKeyValue(Attribute.color.key, hex));
  }

  void _setFont(String family) {
    _format(Attribute.fromKeyValue(Attribute.font.key, family));
  }

  void _setSize(double size) {
    _format(Attribute.fromKeyValue(Attribute.size.key, size.toString()));
  }

  void _setAlign(String value) {
    _format(Attribute.fromKeyValue(Attribute.align.key, value));
  }

  void _setList(String value) {
    _format(Attribute.fromKeyValue(Attribute.list.key, value));
  }

  void _insertText(String text) {
    _ensureFocus();
    final sel = _controller.selection;
    final start = sel.start < 0 ? 0 : sel.start;
    final end = sel.end < 0 ? start : sel.end;
    _controller.replaceText(
      start,
      end - start,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _insertDivider() {
    _insertText('\n────────────\n');
  }

  void _toggleMenu(OverlayEntry? Function() builder) {
    _overlay?.remove();
    _overlay = builder();
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  OverlayEntry _buildPopupMenu({
    required GlobalKey anchorKey,
    required Widget child,
    required double width,
    double bottomOffset = 12,
  }) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? const Size(40, 40);
    final screenW = MediaQuery.of(context).size.width;
    final left = (pos.dx + size.width / 2 - width / 2).clamp(8.0, screenW - width - 8.0);
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _hideOverlay(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            bottom: MediaQuery.of(context).size.height - pos.dy + bottomOffset,
            width: width,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 6)),
                  ],
                  border: Border.all(color: const Color(0x14000000)),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
    setState(() {
      _showFontPicker = false;
      _showSizePicker = false;
      _showColorPicker = false;
      _showInsertMenu = false;
      _showFormatMenu = false;
    });
  }

  void _showFontMenu(GlobalKey key) {
    _hideOverlay();
    setState(() => _showFontPicker = true);
    _toggleMenu(() {
      return _buildPopupMenu(
        anchorKey: key,
        width: 260,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PopupHeader(title: 'Tipo de letra', onClose: _hideOverlay),
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _fonts.length,
                  itemBuilder: (context, index) {
                    final font = _fonts[index];
                    return ListTile(
                      dense: true,
                      title: Text(font, style: TextStyle(fontFamily: font, fontSize: 14)),
                      onTap: () {
                        _setFont(font);
                        _hideOverlay();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showSizeMenu(GlobalKey key) {
    _hideOverlay();
    setState(() => _showSizePicker = true);
    _toggleMenu(() {
      return _buildPopupMenu(
        anchorKey: key,
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PopupHeader(title: 'Tamanho'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _sizes.map((s) {
                  return ChoiceChip(
                    label: Text(s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1)),
                    selected: false,
                    onSelected: (_) {
                      _setSize(s);
                      _hideOverlay();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showColorMenu(GlobalKey key) {
    _hideOverlay();
    setState(() => _showColorPicker = true);
    _toggleMenu(() {
      return _buildPopupMenu(
        anchorKey: key,
        width: 280,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PopupHeader(title: 'Cor do texto'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _colors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final hex = _colors[index];
                  final color = _hexToColor(hex);
                  return GestureDetector(
                    onTap: () {
                      _setColor(hex);
                      _hideOverlay();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0x22000000)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showInsertMenu(GlobalKey key) {
    _hideOverlay();
    setState(() => _showInsertMenu = true);
    _toggleMenu(() {
      return _buildPopupMenu(
        anchorKey: key,
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PopupHeader(title: 'Inserir'),
            _PopupItem(
              icon: LucideIcons.link2,
              label: 'Link',
              onTap: () async {
                final url = await _askText('URL');
                if (url != null && url.trim().isNotEmpty) {
                  _insertText(url.trim());
                }
                _hideOverlay();
              },
            ),
            _PopupItem(
              icon: LucideIcons.image,
              label: 'Imagem',
              onTap: () {
                _insertText('[imagem]');
                _hideOverlay();
              },
            ),
            _PopupItem(
              icon: LucideIcons.minus,
              label: 'Linha divisória',
              onTap: () {
                _insertDivider();
                _hideOverlay();
              },
            ),
            _PopupItem(
              icon: LucideIcons.calendar,
              label: 'Data e hora',
              onTap: () {
                _insertText(DateTime.now().toString());
                _hideOverlay();
              },
            ),
            const _PopupSectionTitle(title: 'Caixas de destaque'),
            _PopupItem(icon: LucideIcons.alertTriangle, label: 'Aviso', onTap: () { _insertText('AVISO'); _hideOverlay(); }),
            _PopupItem(icon: LucideIcons.info, label: 'Informação', onTap: () { _insertText('INFORMAÇÃO'); _hideOverlay(); }),
            _PopupItem(icon: LucideIcons.checkCircle2, label: 'Sucesso', onTap: () { _insertText('SUCESSO'); _hideOverlay(); }),
            _PopupItem(icon: LucideIcons.xCircle, label: 'Erro', onTap: () { _insertText('ERRO'); _hideOverlay(); }),
          ],
        ),
      );
    });
  }

  void _showFormatMenu(GlobalKey key) {
    _hideOverlay();
    setState(() => _showFormatMenu = true);
    _toggleMenu(() {
      return _buildPopupMenu(
        anchorKey: key,
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PopupHeader(title: 'Formatar'),
            _PopupItem(icon: LucideIcons.caseUpper, label: 'MAIÚSCULAS', onTap: () {
              final txt = _selectedPlainText();
              _insertText(txt.toUpperCase());
              _hideOverlay();
            }),
            _PopupItem(icon: LucideIcons.caseLower, label: 'Minúsculas', onTap: () {
              final txt = _selectedPlainText();
              _insertText(txt.toLowerCase());
              _hideOverlay();
            }),
            _PopupItem(icon: Icons.title, label: 'Título', onTap: () {
              final txt = _selectedPlainText();
              _insertText(txt.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' '));
              _hideOverlay();
            }),
            _PopupItem(icon: LucideIcons.superscript, label: 'Sobrescrito', onTap: () { _format(Attribute.fromKeyValue(Attribute.script.key, 'super')); _hideOverlay(); }),
            _PopupItem(icon: LucideIcons.subscript, label: 'Subscrito', onTap: () { _format(Attribute.fromKeyValue(Attribute.script.key, 'sub')); _hideOverlay(); }),
            _PopupItem(icon: LucideIcons.code2, label: 'Código', onTap: () {
              _format(Attribute.inlineCode);
              _hideOverlay();
            }),
            _PopupItem(icon: Icons.format_line_spacing, label: 'Linha 1.0', onTap: () { _format(Attribute.height); _hideOverlay(); }),
            _PopupItem(icon: Icons.format_line_spacing, label: 'Linha 1.5', onTap: () { _format(Attribute.fromKeyValue(Attribute.height.key, '1.5')); _hideOverlay(); }),
            _PopupItem(icon: Icons.format_line_spacing, label: 'Linha 2.0', onTap: () { _format(Attribute.fromKeyValue(Attribute.height.key, '2')); _hideOverlay(); }),
            _PopupItem(icon: Icons.format_clear, label: 'Limpar formatação', onTap: () { _controller.formatSelection(null); _hideOverlay(); }),
          ],
        ),
      );
    });
  }

  Future<String?> _askText(String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
          ],
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
    return Color(value);
  }

  String _selectedPlainText() {
    final plain = _controller.document.toPlainText();
    final sel = _controller.selection;
    final start = sel.start < 0 ? 0 : sel.start;
    final end = sel.end < 0 ? start : sel.end;
    if (plain.isEmpty || start >= end || start >= plain.length) return '';
    final safeEnd = end.clamp(0, plain.length);
    return plain.substring(start.clamp(0, plain.length), safeEnd);
  }

  String _currentText() => _controller.document.toPlainText();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final drawerX = _drawerOpen ? 0.0 : -260.0;
    final appX = _drawerOpen ? 110.0 : 0.0;

    return GestureDetector(
      onTap: _hideOverlay,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: drawerX,
            top: 0,
            bottom: 0,
            width: 260,
            child: _DrawerPanel(
              onClose: _closeDrawer,
              onToggleMode: _toggleMode,
              a4Mode: _a4Mode,
            ),
          ),
          AnimatedPositioned.fill(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: appX,
            child: Material(
              color: const Color(0xFFF8F8F7),
              child: Column(
                children: [
                  _TopBar(
                    onMenu: _toggleDrawer,
                    titleController: _titleController,
                    onUndo: _controller.undo,
                    onRedo: _controller.redo,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 220),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: _a4Mode ? 794 : width,
                              constraints: BoxConstraints(
                                minHeight: _a4Mode ? 1123 : 600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
                                ],
                              ),
                              child: QuillProvider(
                                configurations: QuillConfigurations(
                                  controller: _controller,
                                  sharedConfigurations: const QuillSharedConfigurations(
                                    locale: Locale('pt'),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    _a4Mode ? 88 : 24,
                                    _a4Mode ? 96 : 24,
                                    _a4Mode ? 88 : 24,
                                    _a4Mode ? 120 : 24,
                                  ),
                                  child: QuillEditor.basic(
                                    configurations: const QuillEditorConfigurations(
                                      readOnly: false,
                                      placeholder: 'Começa a escrever…',
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 14,
                          child: Center(
                            child: _ToolbarBar(
                              controller: _controller,
                              onColor: _showColorMenu,
                              onFont: _showFontMenu,
                              onSize: _showSizeMenu,
                              onStyles: _showFormatMenu,
                              onInsert: _showInsertMenu,
                              onFormat: _showFormatMenu,
                              onBold: () => _toggleStyle(Attribute.bold),
                              onItalic: () => _toggleStyle(Attribute.italic),
                              onUnderline: () => _toggleStyle(Attribute.underline),
                              onStrike: () => _toggleStyle(Attribute.strikeThrough),
                              onAlignLeft: () => _setAlign('left'),
                              onAlignCenter: () => _setAlign('center'),
                              onAlignRight: () => _setAlign('right'),
                              onAlignJustify: () => _setAlign('justify'),
                              onBullets: () => _setList('bullet'),
                              onOrdered: () => _setList('ordered'),
                              onIndent: () => _controller.indentSelection(true),
                              onOutdent: () => _controller.indentSelection(false),
                              onConfirm: () {
                                _hideOverlay();
                                _ensureFocus();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_drawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: const Color(0x2E000000)),
              ),
            ),
          if (_showFontPicker || _showSizePicker || _showColorPicker || _showInsertMenu || _showFormatMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideOverlay,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({
    required this.onClose,
    required this.onToggleMode,
    required this.a4Mode,
  });

  final VoidCallback onClose;
  final VoidCallback onToggleMode;
  final bool a4Mode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 52),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x14000000))),
            ),
            child: const Text('Funcionalidades', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF858481), letterSpacing: 0.6)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _DrawerButton(icon: LucideIcons.keyboard, label: 'Toolbar / IA', onTap: onClose),
                _DrawerButton(
                  icon: a4Mode ? LucideIcons.layout : LucideIcons.fileText,
                  label: a4Mode ? 'Formato: A4' : 'Formato: Scroll',
                  onTap: onToggleMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF5E5E5B)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF34322D))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onMenu,
    required this.titleController,
    required this.onUndo,
    required this.onRedo,
  });

  final VoidCallback onMenu;
  final TextEditingController titleController;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: IconButton(
                onPressed: onMenu,
                icon: const Icon(LucideIcons.menu, size: 20),
                color: const Color(0xFF5E5E5B),
                splashRadius: 22,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: titleController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Sem título',
                  hintStyle: TextStyle(color: Color(0xFF858481), fontWeight: FontWeight.w600),
                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF34322D)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopIconButton(icon: LucideIcons.undo2, onTap: onUndo),
                  _TopIconButton(icon: LucideIcons.redo2, onTap: onRedo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: const Color(0xFF5E5E5B),
      splashRadius: 22,
    );
  }
}

class _ToolbarBar extends StatefulWidget {
  const _ToolbarBar({
    required this.controller,
    required this.onColor,
    required this.onFont,
    required this.onSize,
    required this.onStyles,
    required this.onInsert,
    required this.onFormat,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrike,
    required this.onAlignLeft,
    required this.onAlignCenter,
    required this.onAlignRight,
    required this.onAlignJustify,
    required this.onBullets,
    required this.onOrdered,
    required this.onIndent,
    required this.onOutdent,
    required this.onConfirm,
  });

  final QuillController controller;
  final void Function(GlobalKey) onColor;
  final void Function(GlobalKey) onFont;
  final void Function(GlobalKey) onSize;
  final void Function(GlobalKey) onStyles;
  final void Function(GlobalKey) onInsert;
  final void Function(GlobalKey) onFormat;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onStrike;
  final VoidCallback onAlignLeft;
  final VoidCallback onAlignCenter;
  final VoidCallback onAlignRight;
  final VoidCallback onAlignJustify;
  final VoidCallback onBullets;
  final VoidCallback onOrdered;
  final VoidCallback onIndent;
  final VoidCallback onOutdent;
  final VoidCallback onConfirm;

  @override
  State<_ToolbarBar> createState() => _ToolbarBarState();
}

class _ToolbarBarState extends State<_ToolbarBar> {
  final GlobalKey _colorKey = GlobalKey();
  final GlobalKey _fontKey = GlobalKey();
  final GlobalKey _sizeKey = GlobalKey();
  final GlobalKey _stylesKey = GlobalKey();
  final GlobalKey _insertKey = GlobalKey();
  final GlobalKey _formatKey = GlobalKey();

  bool _isOn(Attribute attr) {
    final attrs = widget.controller.getSelectionStyle().attributes;
    if (attr.key == Attribute.align.key || attr.key == Attribute.list.key || attr.key == Attribute.script.key) {
      final current = attrs[attr.key];
      return current?.value == attr.value;
    }
    return attrs.containsKey(attr.key);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return SizedBox(
          width: MediaQuery.of(context).size.width.clamp(0, 460).toDouble(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x14000000)),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 4)),
                  BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _textChip(key: _colorKey, label: 'A', bottomBar: Colors.amber, onTap: () => widget.onColor(_colorKey)),
                  const _DividerItem(),
                  _toolbarButton(icon: LucideIcons.bold, active: _isOn(Attribute.bold), onTap: widget.onBold),
                  _toolbarButton(icon: LucideIcons.italic, active: _isOn(Attribute.italic), onTap: widget.onItalic),
                  _toolbarButton(icon: LucideIcons.underline, active: _isOn(Attribute.underline), onTap: widget.onUnderline),
                  _toolbarButton(icon: LucideIcons.strikethrough, active: _isOn(Attribute.strikeThrough), onTap: widget.onStrike),
                  const _DividerItem(),
                  _chip(key: _fontKey, label: 'Lora', onTap: () => widget.onFont(_fontKey)),
                  _chip(key: _sizeKey, label: '16', onTap: () => widget.onSize(_sizeKey)),
                  const _DividerItem(),
                  _chip(key: _stylesKey, label: 'Estilos', icon: LucideIcons.chevronDown, onTap: () => widget.onStyles(_stylesKey)),
                  const _DividerItem(),
                  _toolbarButton(icon: LucideIcons.alignLeft, active: _isOn(Attribute.fromKeyValue(Attribute.align.key, 'left')), selected: true, onTap: widget.onAlignLeft),
                  _toolbarButton(icon: LucideIcons.alignCenter, active: _isOn(Attribute.fromKeyValue(Attribute.align.key, 'center')), onTap: widget.onAlignCenter),
                  _toolbarButton(icon: LucideIcons.alignRight, active: _isOn(Attribute.fromKeyValue(Attribute.align.key, 'right')), onTap: widget.onAlignRight),
                  _toolbarButton(icon: LucideIcons.alignJustify, active: _isOn(Attribute.fromKeyValue(Attribute.align.key, 'justify')), onTap: widget.onAlignJustify),
                  const _DividerItem(),
                  _toolbarButton(icon: LucideIcons.list, active: _isOn(Attribute.fromKeyValue(Attribute.list.key, 'bullet')), onTap: widget.onBullets),
                  _toolbarButton(icon: LucideIcons.listOrdered, active: _isOn(Attribute.fromKeyValue(Attribute.list.key, 'ordered')), onTap: widget.onOrdered),
                  _toolbarButton(icon: LucideIcons.indentIncrease, active: false, onTap: widget.onIndent),
                  _toolbarButton(icon: LucideIcons.indentDecrease, active: false, onTap: widget.onOutdent),
                  const _DividerItem(),
                  _chip(key: _insertKey, label: 'Inserir', icon: LucideIcons.plus, onTap: () => widget.onInsert(_insertKey)),
                  const _DividerItem(),
                  _chip(key: _formatKey, label: 'Formatar', icon: LucideIcons.settings2, onTap: () => widget.onFormat(_formatKey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dividerButton(VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(LucideIcons.check, size: 18),
      color: const Color(0xFF5E5E5B),
      splashRadius: 18,
    );
  }

  Widget _textChip({required GlobalKey key, required String label, required Color bottomBar, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(height: 2),
              Container(width: 16, height: 3, decoration: BoxDecoration(color: bottomBar, borderRadius: BorderRadius.circular(2))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip({required GlobalKey key, required String label, IconData? icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x14000000), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF34322D))),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 11, color: const Color(0xFF34322D)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({required IconData icon, required VoidCallback onTap, bool active = false, bool selected = false}) {
    final bg = active || selected ? const Color(0xFFEFF6FF) : Colors.transparent;
    final fg = active || selected ? const Color(0xFF2563EB) : const Color(0xFF5E5E5B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Icon(icon, size: 17, color: fg),
        ),
      ),
    );
  }
}

class _DividerItem extends StatelessWidget {
  const _DividerItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      color: const Color(0x14000000),
    );
  }
}

class _PopupHeader extends StatelessWidget {
  const _PopupHeader({required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF858481), letterSpacing: 0.7),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(LucideIcons.x, size: 16),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

class _PopupSectionTitle extends StatelessWidget {
  const _PopupSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFCCCCCC), letterSpacing: 0.6),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  const _PopupItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF858481)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF34322D))),
          ],
        ),
      ),
    );
  }
}
