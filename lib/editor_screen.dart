import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme.dart';
import 'font_data.dart';
import 'popup_overlay.dart';
import 'toolbar_widgets.dart';
import 'popup_contents.dart';
import 'drawer_item.dart';
import 'ai_dots.dart';
import 'font_fullscreen.dart';

// ─── EDITOR SCREEN ────────────────────────────────────────────────────────────
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with TickerProviderStateMixin {
  // Editor
  late QuillController _qc;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScroll = ScrollController();

  // Title
  final TextEditingController _titleCtrl =
      TextEditingController(text: '');

  // Drawer
  late AnimationController _drawerAnim;
  late Animation<double> _drawerSlide;
  late Animation<double> _appSlide;
  late Animation<double> _overlayOpacity;
  bool _drawerOpen = false;

  // Page mode: false = scroll, true = a4
  bool _a4Mode = false;

  // Toolbar state
  bool _aiMode = false;
  bool _aiLoading = false;
  final TextEditingController _aiCtrl = TextEditingController();
  final FocusNode _aiFocus = FocusNode();
  Color _currentColor = T.ink;
  String _currentFont = 'Lora';
  int _currentSize = 16;

  // Bold/italic/underline/strike active states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrike = false;
  String _currentAlign = 'left';

  // Active popup
  OverlayEntry? _activePopup;
  OverlayEntry? _selectionMenu;

  @override
  void initState() {
    super.initState();
    _qc = QuillController.basic();
    _qc.addListener(_onQcChange);

    _drawerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _drawerSlide = Tween<double>(begin: -260, end: 0).animate(
      CurvedAnimation(parent: _drawerAnim, curve: Curves.easeOutCubic),
    );
    _appSlide = Tween<double>(begin: 0, end: 110).animate(
      CurvedAnimation(parent: _drawerAnim, curve: Curves.easeOutCubic),
    );
    _overlayOpacity = Tween<double>(begin: 0, end: 0.18).animate(
      CurvedAnimation(parent: _drawerAnim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _qc.removeListener(_onQcChange);
    _qc.dispose();
    _drawerAnim.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    _titleCtrl.dispose();
    _aiCtrl.dispose();
    _aiFocus.dispose();
    super.dispose();
  }

  void _onQcChange() {
    final style = _qc.getSelectionStyle();
    setState(() {
      // FIX: containsKey recebe String em v10.x — usar .key
      _isBold = style.containsKey(Attribute.bold.key);
      _isItalic = style.containsKey(Attribute.italic.key);
      _isUnderline = style.containsKey(Attribute.underline.key);
      _isStrike = style.containsKey(Attribute.strikeThrough.key);
      final align = style.attributes[Attribute.align.key];
      _currentAlign = align?.value ?? 'left';
      final color = style.attributes['color'];
      if (color?.value != null) {
        try {
          _currentColor =
              Color(int.parse('FF${color!.value.toString().replaceAll('#', '')}', radix: 16));
        } catch (_) {}
      }
      final size = style.attributes[Attribute.size.key];
      if (size?.value != null) {
        try {
          _currentSize = (size!.value as num).toInt();
        } catch (_) {}
      }
    });
  }

  void _toggleDrawer() {
    if (_drawerOpen) {
      _drawerAnim.reverse();
      _drawerOpen = false;
    } else {
      _drawerAnim.forward();
      _drawerOpen = true;
    }
    setState(() {});
  }

  void _closeDrawer() {
    if (_drawerOpen) {
      _drawerAnim.reverse();
      _drawerOpen = false;
      setState(() {});
    }
  }

  // Format operations
  void _exec(Attribute attr) {
    _qc.formatSelection(attr);
  }

  void _toggleBold() {
    _exec(_isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
  }

  void _toggleItalic() {
    _exec(_isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
  }

  void _toggleUnderline() {
    _exec(_isUnderline
        ? Attribute.clone(Attribute.underline, null)
        : Attribute.underline);
  }

  void _toggleStrike() {
    _exec(_isStrike
        ? Attribute.clone(Attribute.strikeThrough, null)
        : Attribute.strikeThrough);
  }

  void _setAlign(String align) {
    Attribute attr;
    switch (align) {
      case 'center':
        attr = Attribute.centerAlignment;
        break;
      case 'right':
        attr = Attribute.rightAlignment;
        break;
      case 'justify':
        attr = Attribute.justifyAlignment;
        break;
      default:
        attr = Attribute.leftAlignment;
    }
    _exec(attr);
    setState(() => _currentAlign = align);
  }

  void _setColor(Color c) {
    final hex =
        '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}';
    _exec(ColorAttribute(hex));
    setState(() => _currentColor = c);
  }

  void _setFontFamily(String family) {
    // FIX: FontFamilyAttribute não existe em v10.x — usar FontAttribute
    _exec(FontAttribute(family));
    setState(() => _currentFont = family);
  }

  void _setFontSize(int size) {
    // FIX: SizeAttribute(double) não existe em v10.x — usar SizeAttribute com String
    _exec(SizeAttribute('$size'));
    setState(() => _currentSize = size);
  }

  void _applyStyle(String tag) {
    switch (tag) {
      case 'h1':
        _exec(HeaderAttribute(level: 1));
        break;
      case 'h2':
        _exec(HeaderAttribute(level: 2));
        break;
      case 'h3':
        _exec(HeaderAttribute(level: 3));
        break;
      case 'h4':
        _exec(HeaderAttribute(level: 4));
        break;
      case 'blockquote':
        _exec(Attribute.blockQuote);
        break;
      case 'code':
        _exec(Attribute.codeBlock);
        break;
      default:
        _exec(HeaderAttribute(level: 0));
    }
  }

  void _insertBulletList() {
    _exec(Attribute.ul);
  }

  void _insertNumberedList() {
    _exec(Attribute.ol);
  }

  void _insertIndent() {
    _exec(Attribute.indentL1);
  }

  void _insertLink() {
    _closePopup();
    _showLinkDialog();
  }

  void _showLinkDialog() async {
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          backgroundColor: T.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Link', style: T.dmSans(size: 15, w: FontWeight.w600)),
          content: TextField(
            controller: c,
            decoration: InputDecoration(
              hintText: 'https://',
              hintStyle: T.dmSans(color: T.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: T.divider),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: T.dmSans(color: T.sub)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text('OK', style: T.dmSans(color: T.accent, w: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    if (url != null && url.isNotEmpty) {
      _exec(LinkAttribute(url));
    }
  }

  void _insertImage() async {
    _closePopup();
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = img.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final index = _qc.selection.baseOffset;
      _qc.document.insert(index, BlockEmbed.image('data:$mime;base64,$b64'));
    }
  }

  void _insertTable() {
    _closePopup();
    final index = _qc.selection.baseOffset;
    final tableText =
        '┌──────────┬──────────┬──────────┐\n│          │          │          │\n├──────────┼──────────┼──────────┤\n│          │          │          │\n├──────────┼──────────┼──────────┤\n│          │          │          │\n└──────────┴──────────┴──────────┘\n';
    _qc.document.insert(index, tableText);
  }

  void _insertHR() {
    _closePopup();
    final index = _qc.selection.baseOffset;
    // FIX: BlockEmbed.horizontalRule não existe em v10.x — usar BlockEmbed.custom com CustomBlockEmbed
    _qc.document.insert(index, BlockEmbed.custom(const DividerBlockEmbed()));
  }

  void _insertDateTime() {
    _closePopup();
    final now = DateTime.now();
    final formatted =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final index = _qc.selection.baseOffset;
    _qc.document.insert(index, formatted);
  }

  void _transformCase(String mode) {
    final sel = _qc.selection;
    if (sel.isCollapsed) return;
    final text = _qc.document.getPlainText(sel.start, sel.end - sel.start);
    String result;
    switch (mode) {
      case 'upper':
        result = text.toUpperCase();
        break;
      case 'lower':
        result = text.toLowerCase();
        break;
      case 'title':
        result = text.replaceAllMapped(
            RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
        break;
      default:
        result = text;
    }
    _qc.replaceText(sel.start, sel.end - sel.start, result, null);
    _closePopup();
  }

  void _setLineHeight(double h) {
    _closePopup();
  }

  void _clearFormat() {
    _qc.formatSelection(Attribute.clone(Attribute.bold, null));
    _qc.formatSelection(Attribute.clone(Attribute.italic, null));
    _qc.formatSelection(Attribute.clone(Attribute.underline, null));
    _qc.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
    _closePopup();
  }

  Future<void> _doAI() async {
    final prompt = _aiCtrl.text.trim();
    if (prompt.isEmpty) return;
    _aiCtrl.clear();
    setState(() => _aiLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'system':
              'Responde APENAS com o texto a inserir no editor, sem explicações nem markdown extra. Responde em português.',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );
      final data = jsonDecode(res.body);
      final txt = (data['content'] as List?)
              ?.map((i) => i['text'] ?? '')
              .join('') ??
          '(sem resposta)';
      final index = _qc.selection.baseOffset;
      _qc.document.insert(index, txt);
    } catch (_) {
      final index = _qc.selection.baseOffset;
      _qc.document.insert(index, '[Erro IA]');
    } finally {
      setState(() => _aiLoading = false);
      _aiFocus.requestFocus();
    }
  }

  // ── POPUP SYSTEM ─────────────────────────────────────────────────────────
  void _closePopup() {
    _activePopup?.remove();
    _activePopup = null;
  }

  void _showPopup({
    required BuildContext triggerContext,
    required RenderBox triggerBox,
    required Widget child,
    double width = 240,
  }) {
    _closePopup();
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final triggerOffset = triggerBox.localToGlobal(Offset.zero);
    final triggerSize = triggerBox.size;

    double left = triggerOffset.dx + triggerSize.width / 2 - width / 2;
    left = left.clamp(8.0, screenSize.width - width - 8);

    _activePopup = OverlayEntry(
      builder: (ctx) => PopupOverlay(
        left: left,
        bottom: screenSize.height - triggerOffset.dy + 12,
        width: width,
        arrowLeft: (triggerOffset.dx + triggerSize.width / 2 - left - 7).clamp(12.0, width - 24.0),
        originX: (triggerOffset.dx + triggerSize.width / 2 - left).clamp(20.0, width - 20.0),
        child: child,
        onDismiss: _closePopup,
      ),
    );
    overlay.insert(_activePopup!);
  }

  void _onTbBtnTap(BuildContext ctx, String popup) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    if (_activePopup != null) {
      _closePopup();
      return;
    }
    switch (popup) {
      case 'color-text':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 254,
          child: ColorPopup(
            currentColor: _currentColor,
            onColor: (c) {
              _setColor(c);
              _closePopup();
            },
          ),
        );
        break;
      case 'font':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 240,
          child: FontPopup(
            currentFont: _currentFont,
            onFont: (f) {
              _setFontFamily(f);
              _closePopup();
            },
            onOpenFullscreen: () {
              _closePopup();
              _showFontFullscreen();
            },
          ),
        );
        break;
      case 'size':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 220,
          child: SizePopup(
            currentSize: _currentSize,
            onSize: (s) {
              _setFontSize(s);
              _closePopup();
            },
          ),
        );
        break;
      case 'styles':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 200,
          child: StylesPopup(
            onStyle: (tag) {
              _applyStyle(tag);
              _closePopup();
            },
          ),
        );
        break;
      case 'insert':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 240,
          child: InsertPopup(
            onLink: _insertLink,
            onImage: _insertImage,
            onTable: _insertTable,
            onHR: _insertHR,
            onDateTime: _insertDateTime,
            onCallout: (type) {
              _insertCallout(type);
              _closePopup();
            },
          ),
        );
        break;
      case 'format':
        _showPopup(
          triggerContext: ctx,
          triggerBox: box,
          width: 240,
          child: FormatPopup(
            onCase: _transformCase,
            onSuperscript: () {
              // FIX: Attribute.superScript → Attribute.superscript (minúsculo)
              _exec(Attribute.superscript);
              _closePopup();
            },
            onSubscript: () {
              _exec(Attribute.subscript);
              _closePopup();
            },
            onInlineCode: () {
              _exec(Attribute.inlineCode);
              _closePopup();
            },
            onLineHeight: _setLineHeight,
            onClearFormat: _clearFormat,
          ),
        );
        break;
    }
  }

  void _insertCallout(String type) {
    final index = _qc.selection.baseOffset;
    final text = switch (type) {
      'warn' => '▲ Aviso',
      'info' => 'ℹ Informação',
      'success' => '✓ Sucesso',
      'error' => '✕ Erro',
      _ => ''
    };
    _qc.document.insert(index, text);
  }

  void _showFontFullscreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FontFullscreen(
        currentFont: _currentFont,
        onFont: (f) {
          _setFontFamily(f);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: T.bg,
        body: AnimatedBuilder(
          animation: _drawerAnim,
          builder: (ctx, _) {
            return Stack(
              children: [
                // ── MAIN APP ──────────────────────────────────
                Transform.translate(
                  offset: Offset(_appSlide.value, 0),
                  child: _buildMainApp(),
                ),
                // ── OVERLAY ───────────────────────────────────
                if (_drawerOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        color: Color.fromRGBO(0, 0, 0, _overlayOpacity.value),
                      ),
                    ),
                  ),
                // ── DRAWER ────────────────────────────────────
                Transform.translate(
                  offset: Offset(_drawerSlide.value, 0),
                  child: _buildDrawer(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainApp() {
    return Column(
      children: [
        _buildTopbar(),
        Expanded(child: _buildCanvas()),
        _buildFloatingToolbar(),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
      ],
    );
  }

  // ── TOPBAR ────────────────────────────────────────────────────────────────
  Widget _buildTopbar() {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(bottom: BorderSide(color: T.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Stack(
            children: [
              // Menu button
              Positioned(
                left: 6,
                top: 4,
                child: TbIconBtn(
                  icon: LucideIcons.menu,
                  onTap: _toggleDrawer,
                ),
              ),
              // Title
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _titleCtrl,
                        textAlign: TextAlign.center,
                        style: T.dmSans(size: 15, w: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Sem título',
                          hintStyle: T.dmSans(size: 15, w: FontWeight.w600, color: T.muted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Undo/Redo
              Positioned(
                right: 6,
                top: 4,
                child: Row(
                  children: [
                    TbIconBtn(
                      icon: LucideIcons.undo2,
                      onTap: () => _qc.undo(),
                    ),
                    TbIconBtn(
                      icon: LucideIcons.redo2,
                      onTap: () => _qc.redo(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CANVAS ────────────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double availableWidth = constraints.maxWidth - 32;
        final double scale = availableWidth < 794 ? availableWidth / 794 : 1.0;

        return SingleChildScrollView(
          controller: _editorScroll,
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
          child: Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 794,
                child: _a4Mode ? _buildA4Pages() : _buildScrollPage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollPage() {
    return Container(
      width: 794,
      constraints: const BoxConstraints(minHeight: 1123),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(88, 96, 88, 120),
      child: _buildEditor(),
    );
  }

  Widget _buildA4Pages() {
    return Container(
      width: 794,
      height: 1123,
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(88, 96, 88, 96),
      child: _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return QuillEditor.basic(
      controller: _qc,
      focusNode: _editorFocus,
      configurations: QuillEditorConfigurations(
        scrollable: false,
        autoFocus: false,
        expands: false,
        padding: EdgeInsets.zero,
        placeholder: 'Começa a escrever…',
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 16,
              height: 1.85,
              color: T.ink,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
          h1: DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: T.ink,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(8, 4),
            const VerticalSpacing(0, 0),
            null,
          ),
          h2: DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: T.ink,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(6, 3),
            const VerticalSpacing(0, 0),
            null,
          ),
          h3: DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: T.ink,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(4, 2),
            const VerticalSpacing(0, 0),
            null,
          ),
          bold: const TextStyle(fontWeight: FontWeight.w700),
          italic: const TextStyle(fontStyle: FontStyle.italic),
          underline: const TextStyle(decoration: TextDecoration.underline),
          strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
          placeHolder: DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 16,
              height: 1.85,
              color: T.muted,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }

  // ── DRAWER ────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          width: 260,
          decoration: const BoxDecoration(
            color: T.surface,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: T.divider)),
                ),
                child: Text(
                  'Funcionalidades',
                  style: T.dmSans(
                    size: 13,
                    w: FontWeight.w700,
                    color: T.muted,
                  ),
                ),
              ),
              // Items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: T.divider)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              DrawerItem(
                                icon: _aiMode ? LucideIcons.bot : LucideIcons.keyboard,
                                label: _aiMode ? 'IA ativa' : 'Toolbar / IA',
                                isActive: _aiMode,
                                onTap: () {
                                  _closeDrawer();
                                  setState(() {
                                    if (_aiMode) {
                                      _aiMode = false;
                                    } else {
                                      _aiMode = true;
                                    }
                                  });
                                },
                              ),
                              DrawerItem(
                                icon: _a4Mode ? LucideIcons.layoutGrid : LucideIcons.fileText,
                                label: _a4Mode ? 'Formato: A4' : 'Formato: Scroll',
                                isActive: _a4Mode,
                                onTap: () {
                                  setState(() => _a4Mode = !_a4Mode);
                                  _closeDrawer();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FLOATING TOOLBAR ─────────────────────────────────────────────────────
  Widget _buildFloatingToolbar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: math.max(14, MediaQuery.of(context).padding.bottom + 4),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Center(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFAFFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: T.divider),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _aiMode ? _buildAIRow() : _buildTbButtons(),
                  ),
                  // Confirm / Send button
                  Padding(
                    padding: const EdgeInsets.only(right: 6, left: 2),
                    child: GestureDetector(
                      onTap: () {
                        if (_aiMode) {
                          _doAI();
                        } else {
                          _closePopup();
                          _editorFocus.requestFocus();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _aiMode ? T.accent : T.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _aiMode ? Colors.transparent : T.divider,
                          ),
                        ),
                        child: _aiLoading
                            ? const Center(child: AiDots())
                            : Icon(
                                _aiMode ? LucideIcons.send : LucideIcons.check,
                                size: 16,
                                color: _aiMode ? Colors.white : T.sub,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _aiCtrl,
        focusNode: _aiFocus,
        style: T.dmSans(size: 14),
        decoration: InputDecoration(
          hintText: 'Pergunta à IA…',
          hintStyle: T.dmSans(size: 14, color: T.muted),
          border: InputBorder.none,
          isDense: true,
        ),
        onSubmitted: (_) => _doAI(),
        textInputAction: TextInputAction.send,
      ),
    );
  }

  Widget _buildTbButtons() {
    return Stack(
      children: [
        // Left fade
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(999),
                  bottomLeft: Radius.circular(999),
                ),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.97), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Right fade
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 14,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.white.withOpacity(0.97), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              // Color
              Builder(builder: (ctx) => TbColorBtn(
                color: _currentColor,
                onTap: () => _onTbBtnTap(ctx, 'color-text'),
              )),
              const TbDiv(),
              // Bold
              TbFmtBtn(
                label: 'B',
                bold: true,
                active: _isBold,
                onTap: _toggleBold,
              ),
              TbFmtBtn(
                label: 'I',
                italic: true,
                active: _isItalic,
                onTap: _toggleItalic,
              ),
              TbFmtBtn(
                label: 'U',
                underline: true,
                active: _isUnderline,
                onTap: _toggleUnderline,
              ),
              TbFmtBtn(
                label: 'S',
                strike: true,
                active: _isStrike,
                onTap: _toggleStrike,
              ),
              const TbDiv(),
              // Font chip
              Builder(builder: (ctx) => TbChip(
                label: _currentFont,
                onTap: () => _onTbBtnTap(ctx, 'font'),
              )),
              // Size chip
              Builder(builder: (ctx) => TbChip(
                label: '$_currentSize',
                onTap: () => _onTbBtnTap(ctx, 'size'),
              )),
              const TbDiv(),
              // Styles chip
              Builder(builder: (ctx) => TbChip(
                label: 'Estilos',
                icon: LucideIcons.chevronDown,
                onTap: () => _onTbBtnTap(ctx, 'styles'),
              )),
              const TbDiv(),
              // Align
              TbAlignBtn(
                icon: LucideIcons.alignLeft,
                active: _currentAlign == 'left',
                onTap: () => _setAlign('left'),
              ),
              TbAlignBtn(
                icon: LucideIcons.alignCenter,
                active: _currentAlign == 'center',
                onTap: () => _setAlign('center'),
              ),
              TbAlignBtn(
                icon: LucideIcons.alignRight,
                active: _currentAlign == 'right',
                onTap: () => _setAlign('right'),
              ),
              TbAlignBtn(
                icon: LucideIcons.alignJustify,
                active: _currentAlign == 'justify',
                onTap: () => _setAlign('justify'),
              ),
              const TbDiv(),
              // List
              TbIconBtnSm(icon: LucideIcons.list, onTap: _insertBulletList),
              TbIconBtnSm(icon: LucideIcons.listOrdered, onTap: _insertNumberedList),
              TbIconBtnSm(icon: LucideIcons.indent, onTap: _insertIndent),
              TbIconBtnSm(icon: LucideIcons.outdent, onTap: () => _exec(Attribute.indentL1)),
              const TbDiv(),
              // Insert chip
              Builder(builder: (ctx) => TbChip(
                label: 'Inserir',
                icon: LucideIcons.plus,
                onTap: () => _onTbBtnTap(ctx, 'insert'),
              )),
              const TbDiv(),
              // Format chip
              Builder(builder: (ctx) => TbChip(
                label: 'Formatar',
                icon: LucideIcons.settings2,
                onTap: () => _onTbBtnTap(ctx, 'format'),
              )),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class DividerBlockEmbed extends CustomBlockEmbed {
  const DividerBlockEmbed() : super('divider', '');
}
