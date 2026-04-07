import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DoctionApp());
}

// ─── THEME TOKENS ────────────────────────────────────────────────────────────
class T {
  static const accent = Color(0xFF2563EB);
  static const accentBg = Color(0xFFEFF6FF);
  static const ink = Color(0xFF34322D);
  static const sub = Color(0xFF5E5E5B);
  static const muted = Color(0xFF858481);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF8F8F7);
  static const divider = Color(0x14000000);
  static const dark = Color(0xFF1C1C1E);

  static TextStyle dmSans({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color ?? ink);

  static TextStyle lora({
    double size = 16,
    FontWeight w = FontWeight.w400,
    Color? color,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.lora(
          fontSize: size, fontWeight: w, color: color ?? ink, fontStyle: style);
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

// ─── FONT DATA ────────────────────────────────────────────────────────────────
class FontEntry {
  final String label;
  final String family;
  final String group;
  const FontEntry(this.label, this.family, this.group);
}

const List<FontEntry> kFonts = [
  // Serif
  FontEntry('Lora', 'Lora', 'Serif'),
  FontEntry('Playfair Display', 'Playfair Display', 'Serif'),
  FontEntry('Merriweather', 'Merriweather', 'Serif'),
  FontEntry('Source Serif 4', 'Source Serif 4', 'Serif'),
  FontEntry('PT Serif', 'PT Serif', 'Serif'),
  FontEntry('Libre Baskerville', 'Libre Baskerville', 'Serif'),
  FontEntry('EB Garamond', 'EB Garamond', 'Serif'),
  FontEntry('Crimson Text', 'Crimson Text', 'Serif'),
  FontEntry('Cormorant Garamond', 'Cormorant Garamond', 'Serif'),
  FontEntry('Noto Serif', 'Noto Serif', 'Serif'),
  FontEntry('Spectral', 'Spectral', 'Serif'),
  FontEntry('Bitter', 'Bitter', 'Serif'),
  // Sans-serif
  FontEntry('Inter', 'Inter', 'Sans-serif'),
  FontEntry('Open Sans', 'Open Sans', 'Sans-serif'),
  FontEntry('Montserrat', 'Montserrat', 'Sans-serif'),
  FontEntry('DM Sans', 'DM Sans', 'Sans-serif'),
  FontEntry('Roboto', 'Roboto', 'Sans-serif'),
  FontEntry('Nunito', 'Nunito', 'Sans-serif'),
  FontEntry('Poppins', 'Poppins', 'Sans-serif'),
  FontEntry('Raleway', 'Raleway', 'Sans-serif'),
  FontEntry('Josefin Sans', 'Josefin Sans', 'Sans-serif'),
  FontEntry('Work Sans', 'Work Sans', 'Sans-serif'),
  FontEntry('Karla', 'Karla', 'Sans-serif'),
  FontEntry('Rubik', 'Rubik', 'Sans-serif'),
  FontEntry('IBM Plex Sans', 'IBM Plex Sans', 'Sans-serif'),
  FontEntry('Mulish', 'Mulish', 'Sans-serif'),
  FontEntry('Quicksand', 'Quicksand', 'Sans-serif'),
  // Monospace
  FontEntry('IBM Plex Mono', 'IBM Plex Mono', 'Monospace'),
  FontEntry('Source Code Pro', 'Source Code Pro', 'Monospace'),
  FontEntry('Fira Code', 'Fira Code', 'Monospace'),
  FontEntry('JetBrains Mono', 'JetBrains Mono', 'Monospace'),
  FontEntry('Space Mono', 'Space Mono', 'Monospace'),
  FontEntry('Inconsolata', 'Inconsolata', 'Monospace'),
  FontEntry('Ubuntu Mono', 'Ubuntu Mono', 'Monospace'),
  // Decorativa
  FontEntry('Cinzel', 'Cinzel', 'Decorativa'),
  FontEntry('Abril Fatface', 'Abril Fatface', 'Decorativa'),
  FontEntry('Pacifico', 'Pacifico', 'Decorativa'),
  FontEntry('Dancing Script', 'Dancing Script', 'Manuscrita'),
  FontEntry('Caveat', 'Caveat', 'Manuscrita'),
  FontEntry('Kalam', 'Kalam', 'Manuscrita'),
  FontEntry('Patrick Hand', 'Patrick Hand', 'Manuscrita'),
  FontEntry('Indie Flower', 'Indie Flower', 'Manuscrita'),
  FontEntry('Permanent Marker', 'Permanent Marker', 'Manuscrita'),
  FontEntry('Sacramento', 'Sacramento', 'Manuscrita'),
  FontEntry('Great Vibes', 'Great Vibes', 'Manuscrita'),
];

const List<Color> kColors = [
  Color(0xFF000000), Color(0xFF34322D), Color(0xFF5E5E5B), Color(0xFF858481),
  Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFFFFFFF),
  Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFCA8A04),
  Color(0xFF65A30D), Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB),
  Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777),
  Color(0xFFFCA5A5), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFF86EFAC),
  Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFF9A8D4), Color(0xFFFDE68A),
  Color(0xFF6EE7B7), Color(0xFFA5B4FC), Color(0xFFFBCFE8), Color(0xFFE9D5FF),
];

const List<int> kSizes = [8, 10, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72];

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
      _isBold = style.containsKey(Attribute.bold);
      _isItalic = style.containsKey(Attribute.italic);
      _isUnderline = style.containsKey(Attribute.underline);
      _isStrike = style.containsKey(Attribute.strikeThrough);
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
    _exec(FontFamilyAttribute(family));
    setState(() => _currentFont = family);
  }

  void _setFontSize(int size) {
    _exec(SizeAttribute(size.toDouble()));
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
    // Insert a simple table as HTML-like text block
    final index = _qc.selection.baseOffset;
    // Quill doesn't natively support tables, we insert a visual representation
    final tableText =
        '┌──────────┬──────────┬──────────┐\n│          │          │          │\n├──────────┼──────────┼──────────┤\n│          │          │          │\n├──────────┼──────────┼──────────┤\n│          │          │          │\n└──────────┴──────────┴──────────┘\n';
    _qc.document.insert(index, tableText);
  }

  void _insertHR() {
    _closePopup();
    final index = _qc.selection.baseOffset;
    _qc.document.insert(index, BlockEmbed.horizontalRule);
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
    // Line height via custom attribute
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

    // Position above the trigger
    double left = triggerOffset.dx + triggerSize.width / 2 - width / 2;
    left = left.clamp(8.0, screenSize.width - width - 8);

    _activePopup = OverlayEntry(
      builder: (ctx) => _PopupOverlay(
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
          child: _ColorPopup(
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
          child: _FontPopup(
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
          child: _SizePopup(
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
          child: _StylesPopup(
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
          child: _InsertPopup(
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
          child: _FormatPopup(
            onCase: _transformCase,
            onSuperscript: () {
              _exec(Attribute.superScript);
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
      builder: (ctx) => _FontFullscreen(
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
                child: _TbIconBtn(
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
                    _TbIconBtn(
                      icon: LucideIcons.undo2,
                      onTap: () => _qc.undo(),
                    ),
                    _TbIconBtn(
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
          padding: EdgeInsets.fromLTRB(16, 28, 16, 200),
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
            null,
          ),
        ),
        selectionColor: const Color(0xFFBFDBFE),
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
                              _DrawerItem(
                                icon: _aiMode ? LucideIcons.bot : LucideIcons.keyboard,
                                label: _aiMode ? 'IA activa' : 'Toolbar / IA',
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
                              _DrawerItem(
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
                            ? const Center(child: _AiDots())
                            : Icon(
                                _aiMode ? LucideIcons.send : LucideLucideIcons.check,
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
              Builder(builder: (ctx) => _TbColorBtn(
                color: _currentColor,
                onTap: () => _onTbBtnTap(ctx, 'color-text'),
              )),
              const _TbDiv(),
              // Bold
              _TbFmtBtn(
                label: 'B',
                bold: true,
                active: _isBold,
                onTap: _toggleBold,
              ),
              _TbFmtBtn(
                label: 'I',
                italic: true,
                active: _isItalic,
                onTap: _toggleItalic,
              ),
              _TbFmtBtn(
                label: 'U',
                underline: true,
                active: _isUnderline,
                onTap: _toggleUnderline,
              ),
              _TbFmtBtn(
                label: 'S',
                strike: true,
                active: _isStrike,
                onTap: _toggleStrike,
              ),
              const _TbDiv(),
              // Font chip
              Builder(builder: (ctx) => _TbChip(
                label: _currentFont,
                onTap: () => _onTbBtnTap(ctx, 'font'),
              )),
              // Size chip
              Builder(builder: (ctx) => _TbChip(
                label: '$_currentSize',
                onTap: () => _onTbBtnTap(ctx, 'size'),
              )),
              const _TbDiv(),
              // Styles chip
              Builder(builder: (ctx) => _TbChip(
                label: 'Estilos',
                icon: LucideIcons.chevronDown,
                onTap: () => _onTbBtnTap(ctx, 'styles'),
              )),
              const _TbDiv(),
              // Align
              _TbAlignBtn(
                icon: LucideIcons.alignLeft,
                active: _currentAlign == 'left',
                onTap: () => _setAlign('left'),
              ),
              _TbAlignBtn(
                icon: LucideIcons.alignCenter,
                active: _currentAlign == 'center',
                onTap: () => _setAlign('center'),
              ),
              _TbAlignBtn(
                icon: LucideIcons.alignRight,
                active: _currentAlign == 'right',
                onTap: () => _setAlign('right'),
              ),
              _TbAlignBtn(
                icon: LucideIcons.alignJustify,
                active: _currentAlign == 'justify',
                onTap: () => _setAlign('justify'),
              ),
              const _TbDiv(),
              // List
              _TbIconBtnSm(icon: LucideIcons.list, onTap: _insertBulletList),
              _TbIconBtnSm(icon: LucideIcons.listOrdered, onTap: _insertNumberedList),
              _TbIconBtnSm(icon: LucideIcons.indent, onTap: _insertIndent),
              _TbIconBtnSm(icon: LucideIcons.outdent, onTap: () => _exec(Attribute.indentL1)),
              const _TbDiv(),
              // Insert chip
              Builder(builder: (ctx) => _TbChip(
                label: 'Inserir',
                icon: LucideIcons.plus,
                onTap: () => _onTbBtnTap(ctx, 'insert'),
              )),
              const _TbDiv(),
              // Format chip
              Builder(builder: (ctx) => _TbChip(
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

// ─── POPUP OVERLAY ───────────────────────────────────────────────────────────
class _PopupOverlay extends StatefulWidget {
  final double left;
  final double bottom;
  final double width;
  final double arrowLeft;
  final double originX;
  final Widget child;
  final VoidCallback onDismiss;

  const _PopupOverlay({
    required this.left,
    required this.bottom,
    required this.width,
    required this.arrowLeft,
    required this.originX,
    required this.child,
    required this.onDismiss,
  });

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const _SpringCurve()),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss mask
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Popup
        Positioned(
          left: widget.left,
          bottom: widget.bottom,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) => FadeTransition(
              opacity: _opacity,
              child: Transform.scale(
                scale: _scale.value,
                alignment: Alignment(
                  (widget.originX / widget.width) * 2 - 1,
                  1.0 + (14 / 100),
                ),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x21000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.child,
                  ),
                ),
                // Arrow
                Align(
                  alignment: Alignment(
                    ((widget.arrowLeft + 7) / widget.width) * 2 - 1,
                    0,
                  ),
                  child: CustomPaint(
                    size: const Size(18, 9),
                    painter: _ArrowPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    path.moveTo(size.width / 2 - 7, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 7, 0);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SpringCurve extends Curve {
  const _SpringCurve();
  @override
  double transform(double t) {
    // Approximate cubic-bezier(.34,1.56,.64,1)
    return 1.0 + (t - 1.0) * (t - 1.0) * ((1.56 + 1) * (t - 1.0) + 1.56);
  }
}

// ─── TOOLBAR WIDGETS ─────────────────────────────────────────────────────────
class _TbIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TbIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: T.sub),
      ),
    );
  }
}

class _TbColorBtn extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _TbColorBtn({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A',
              style: T.dmSans(size: 16, w: FontWeight.w900, color: T.sub),
            ),
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TbDiv extends StatelessWidget {
  const _TbDiv();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: T.divider,
    );
  }
}

class _TbFmtBtn extends StatelessWidget {
  final String label;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool active;
  final VoidCallback onTap;

  const _TbFmtBtn({
    required this.label,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        width: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? T.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : strike
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
            color: active ? T.accent : T.sub,
          ),
        ),
      ),
    );
  }
}

class _TbAlignBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TbAlignBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? T.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? T.accent : T.sub,
        ),
      ),
    );
  }
}

class _TbIconBtnSm extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TbIconBtnSm({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 17, color: T.sub),
      ),
    );
  }
}

class _TbChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _TbChip({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: T.divider, width: 1.5),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: T.dmSans(
                size: 12,
                w: FontWeight.w600,
                color: T.ink,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon!, size: 11, color: T.sub),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── POPUP CONTENTS ──────────────────────────────────────────────────────────

// POPUP HEADER
class _PopupHeader extends StatelessWidget {
  final String title;
  const _PopupHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.divider)),
      ),
      child: Text(
        title.toUpperCase(),
        style: T.dmSans(size: 10.5, w: FontWeight.w700, color: T.muted),
      ),
    );
  }
}

// POPUP ITEM BUTTON
class _PopupItemBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _PopupItemBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color ?? T.muted),
            const SizedBox(width: 10),
            Text(
              label,
              style: T.dmSans(size: 13, w: FontWeight.w500, color: color ?? T.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// COLOR POPUP
class _ColorPopup extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColor;

  const _ColorPopup({required this.currentColor, required this.onColor});

  @override
  State<_ColorPopup> createState() => _ColorPopupState();
}

class _ColorPopupState extends State<_ColorPopup> {
  final TextEditingController _hexCtrl = TextEditingController();
  Color _preview = T.ink;

  @override
  void initState() {
    super.initState();
    _preview = widget.currentColor;
    _hexCtrl.text =
        '#${widget.currentColor.red.toRadixString(16).padLeft(2, '0')}${widget.currentColor.green.toRadixString(16).padLeft(2, '0')}${widget.currentColor.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PopupHeader('Cor do texto'),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: kColors.map((c) {
              return GestureDetector(
                onTap: () => widget.onColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: c == Colors.white
                          ? const Color(0x26000000)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _preview,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x1F000000), width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  style: T.dmSans(size: 12, w: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: T.divider, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: T.divider, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                      setState(() {
                        _preview = Color(
                          int.parse('FF${v.substring(1)}', radix: 16),
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_hexCtrl.text)) {
                    widget.onColor(
                      Color(int.parse('FF${_hexCtrl.text.substring(1)}', radix: 16)),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _preview,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.check, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// FONT POPUP
class _FontPopup extends StatefulWidget {
  final String currentFont;
  final ValueChanged<String> onFont;
  final VoidCallback onOpenFullscreen;

  const _FontPopup({
    required this.currentFont,
    required this.onFont,
    required this.onOpenFullscreen,
  });

  @override
  State<_FontPopup> createState() => _FontPopupState();
}

class _FontPopupState extends State<_FontPopup> {
  String _query = '';
  FontEntry? _preview;

  List<FontEntry> get _filtered => _query.isEmpty
      ? kFonts
      : kFonts.where((f) => f.label.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with expand button
        Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: T.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'TIPO DE LETRA',
                  style: T.dmSans(size: 10.5, w: FontWeight.w700, color: T.muted),
                ),
              ),
              GestureDetector(
                onTap: widget.onOpenFullscreen,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.transparent,
                  ),
                  child: Icon(LucideIcons.maximize2, size: 14, color: T.muted),
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: T.dmSans(size: 12.5),
            decoration: InputDecoration(
              hintText: 'Pesquisar…',
              hintStyle: T.dmSans(size: 12.5, color: T.muted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: T.divider, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: T.divider, width: 1.5),
              ),
            ),
          ),
        ),
        // Font list
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final f = _filtered[i];
              final isActive = f.family == widget.currentFont;
              return GestureDetector(
                onTap: () => setState(() => _preview = f),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                  color: Colors.transparent,
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontFamily: f.family,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? T.accent : T.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Preview
        if (_preview != null)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F7),
              border: Border(top: BorderSide(color: T.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _preview!.group.toUpperCase(),
                  style: T.dmSans(size: 10, w: FontWeight.w700, color: T.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aa Bb Cc',
                  style: TextStyle(
                    fontFamily: _preview!.family,
                    fontSize: 26,
                    color: T.ink,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => widget.onFont(_preview!.family),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: T.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Aplicar',
                      style: T.dmSans(size: 12.5, w: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// SIZE POPUP
class _SizePopup extends StatefulWidget {
  final int currentSize;
  final ValueChanged<int> onSize;

  const _SizePopup({required this.currentSize, required this.onSize});

  @override
  State<_SizePopup> createState() => _SizePopupState();
}

class _SizePopupState extends State<_SizePopup> {
  late int _size;

  @override
  void initState() {
    super.initState();
    _size = widget.currentSize;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PopupHeader('Tamanho'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _size = math.max(6, _size - 1)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: T.divider, width: 1.5),
                    color: T.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text('−', style: T.dmSans(size: 18, color: T.sub)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_size',
                    style: T.dmSans(size: 20, w: FontWeight.w700),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _size = math.min(200, _size + 1)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: T.divider, width: 1.5),
                    color: T.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text('+', style: T.dmSans(size: 18, color: T.sub)),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: T.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: kSizes.map((s) {
              final active = s == _size;
              return GestureDetector(
                onTap: () {
                  widget.onSize(s);
                  setState(() => _size = s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? T.accent : T.divider,
                      width: 1.5,
                    ),
                    color: active ? T.accentBg : Colors.transparent,
                  ),
                  child: Text(
                    '$s',
                    style: T.dmSans(
                      size: 12,
                      w: FontWeight.w600,
                      color: active ? T.accent : T.sub,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// STYLES POPUP
class _StylesPopup extends StatelessWidget {
  final ValueChanged<String> onStyle;

  const _StylesPopup({required this.onStyle});

  @override
  Widget build(BuildContext context) {
    final styles = [
      (LucideIcons.pilcrow, 'Parágrafo', 'p'),
      (LucideIcons.heading1, 'Título 1', 'h1'),
      (LucideIcons.heading2, 'Título 2', 'h2'),
      (LucideIcons.caseSensitive, 'Título 3', 'h3'),
      (LucideIcons.heading4, 'Título 4', 'h4'),
      (LucideIcons.quote, 'Citação', 'blockquote'),
      (LucideIcons.code, 'Código', 'code'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PopupHeader('Estilo de parágrafo'),
        ...styles.map((s) => _PopupItemBtn(
              icon: s.$1,
              label: s.$2,
              onTap: () => onStyle(s.$3),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

// INSERT POPUP
class _InsertPopup extends StatelessWidget {
  final VoidCallback onLink;
  final VoidCallback onImage;
  final VoidCallback onTable;
  final VoidCallback onHR;
  final VoidCallback onDateTime;
  final ValueChanged<String> onCallout;

  const _InsertPopup({
    required this.onLink,
    required this.onImage,
    required this.onTable,
    required this.onHR,
    required this.onDateTime,
    required this.onCallout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupHeader('Inserir'),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              children: [
                _PopupItemBtn(icon: LucideIcons.link, label: 'Link', onTap: onLink),
                _PopupItemBtn(icon: LucideIcons.image, label: 'Imagem', onTap: onImage),
                _PopupItemBtn(icon: LucideIcons.table, label: 'Tabela 3×3', onTap: onTable),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              children: [
                _PopupItemBtn(icon: LucideIcons.minus, label: 'Linha divisória', onTap: onHR),
                _PopupItemBtn(
                  icon: LucideIcons.calendar,
                  label: 'Data e hora',
                  onTap: onDateTime,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CAIXAS DE DESTAQUE',
                style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
              ),
            ),
          ),
          _PopupItemBtn(icon: LucideIcons.alertTriangle, label: 'Aviso', onTap: () => onCallout('warn')),
          _PopupItemBtn(icon: LucideIcons.info, label: 'Informação', onTap: () => onCallout('info')),
          _PopupItemBtn(icon: LucideIcons.checkCircle, label: 'Sucesso', onTap: () => onCallout('success')),
          _PopupItemBtn(icon: LucideIcons.xCircle, label: 'Erro', onTap: () => onCallout('error')),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// FORMAT POPUP
class _FormatPopup extends StatelessWidget {
  final ValueChanged<String> onCase;
  final VoidCallback onSuperscript;
  final VoidCallback onSubscript;
  final VoidCallback onInlineCode;
  final ValueChanged<double> onLineHeight;
  final VoidCallback onClearFormat;

  const _FormatPopup({
    required this.onCase,
    required this.onSuperscript,
    required this.onSubscript,
    required this.onInlineCode,
    required this.onLineHeight,
    required this.onClearFormat,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupHeader('Formatar'),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'MAIÚSCULAS',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                _PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'MAIÚSCULAS', onTap: () => onCase('upper')),
                _PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'minúsculas', onTap: () => onCase('lower')),
                _PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'Primeira Maiúscula', onTap: () => onCase('title')),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'INLINE',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                _PopupItemBtn(icon: LucideIcons.superscript, label: 'Sobrescrito', onTap: onSuperscript),
                _PopupItemBtn(icon: LucideIcons.subscript, label: 'Subscrito', onTap: onSubscript),
                _PopupItemBtn(icon: LucideIcons.code, label: 'Código inline', onTap: onInlineCode),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'ESPAÇAMENTO',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                _PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '1.0 — Compacto',
                  onTap: () => onLineHeight(1.0),
                ),
                _PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '1.5 — Normal',
                  onTap: () => onLineHeight(1.5),
                ),
                _PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '2.0 — Espaçado',
                  onTap: () => onLineHeight(2.0),
                ),
              ],
            ),
          ),
          _PopupItemBtn(
            icon: LucideIcons.trash2,
            label: 'Limpar formatação',
            onTap: onClearFormat,
            color: Colors.red,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── FONT FULLSCREEN ─────────────────────────────────────────────────────────
class _FontFullscreen extends StatefulWidget {
  final String currentFont;
  final ValueChanged<String> onFont;

  const _FontFullscreen({required this.currentFont, required this.onFont});

  @override
  State<_FontFullscreen> createState() => _FontFullscreenState();
}

class _FontFullscreenState extends State<_FontFullscreen> {
  String _query = '';
  String _category = 'Todas';
  FontEntry? _selected;

  List<String> get _categories {
    final cats = ['Todas', ...kFonts.map((f) => f.group).toSet().toList()];
    return cats;
  }

  List<FontEntry> get _filtered {
    return kFonts.where((f) {
      final matchCat = _category == 'Todas' || f.group == _category;
      final matchQ = _query.isEmpty || f.label.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Row(
              children: [
                Text('Fontes', style: T.dmSans(size: 14, w: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: T.dmSans(size: 13),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar fonte…',
                      hintStyle: T.dmSans(size: 13, color: T.muted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: T.divider, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: T.divider, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.transparent,
                    ),
                    child: Icon(LucideIcons.x, size: 17, color: T.sub),
                  ),
                ),
              ],
            ),
          ),
          // Categories
          Container(
            height: 50,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: _categories.map((cat) {
                final active = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? T.accent : T.divider,
                        width: 1.5,
                      ),
                      color: active ? T.accentBg : Colors.transparent,
                    ),
                    child: Text(
                      cat,
                      style: T.dmSans(
                        size: 12,
                        w: FontWeight.w600,
                        color: active ? T.accent : T.sub,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final f = _filtered[i];
                final isSelected = _selected?.family == f.family;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? T.accent : T.divider,
                        width: 1.5,
                      ),
                      color: isSelected ? T.accentBg : Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.group.toUpperCase(),
                          style: T.dmSans(size: 10, w: FontWeight.w700, color: T.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            'Aa Bb',
                            style: TextStyle(
                              fontFamily: f.family,
                              fontSize: 20,
                              color: T.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          f.label,
                          style: T.dmSans(size: 10, color: T.sub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: T.divider)),
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _selected != null ? () => widget.onFont(_selected!.family) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selected != null ? T.accent : const Color(0x14000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selected != null
                        ? 'Aplicar "${_selected!.label}"'
                        : 'Aplicar fonte',
                    style: T.dmSans(
                      size: 13.5,
                      w: FontWeight.w600,
                      color: _selected != null ? Colors.white : T.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DRAWER ITEM ─────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive ? T.accentBg : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? T.accent : T.sub,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: T.dmSans(
                size: 14,
                w: FontWeight.w500,
                color: isActive ? T.accent : T.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AI DOTS ANIMATION ───────────────────────────────────────────────────────
class _AiDots extends StatefulWidget {
  const _AiDots();
  @override
  State<_AiDots> createState() => _AiDotsState();
}

class _AiDotsState extends State<_AiDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: false),
    );
    _anims = _ctrls.asMap().entries.map((e) {
      final delay = e.key * 0.2;
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 60),
      ]).animate(CurvedAnimation(
        parent: e.value,
        curve: Interval(delay, math.min(delay + 0.7, 1.0)),
      ));
    }).toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: (i * 200)), () {
        if (mounted) _ctrls[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (ctx, _) => Opacity(
            opacity: _anims[i].value,
            child: Transform.scale(
              scale: _anims[i].value,
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(
                  color: T.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
