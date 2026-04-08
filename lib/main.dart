import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS / THEME
// ─────────────────────────────────────────────────────────────────────────────
const kAccent = Color(0xFF2563EB);
const kAccentBg = Color(0xFFEFF6FF);
const kInk = Color(0xFF34322D);
const kSub = Color(0xFF5E5E5B);
const kMuted = Color(0xFF858481);
const kSurface = Color(0xFFFFFFFF);
const kBg = Color(0xFFF8F8F7);
const kBorder = Color(0x14000000);
const kDivider = Color(0x14000000);

TextStyle dmSans({double size = 14, FontWeight fw = FontWeight.w400, Color? color}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: fw, color: color ?? kInk);

// ─────────────────────────────────────────────────────────────────────────────
// FONT DATA
// ─────────────────────────────────────────────────────────────────────────────
class FontEntry {
  final String label;
  final String family;
  final String group;
  const FontEntry(this.label, this.family, this.group);
}

final kFonts = <FontEntry>[
  // Serif
  FontEntry('Lora', 'Lora', 'Serif'),
  FontEntry('Playfair Display', 'Playfair Display', 'Serif'),
  FontEntry('Merriweather', 'Merriweather', 'Serif'),
  FontEntry('PT Serif', 'PT Serif', 'Serif'),
  FontEntry('Libre Baskerville', 'Libre Baskerville', 'Serif'),
  FontEntry('EB Garamond', 'EB Garamond', 'Serif'),
  FontEntry('Crimson Text', 'Crimson Text', 'Serif'),
  FontEntry('Cormorant Garamond', 'Cormorant Garamond', 'Serif'),
  FontEntry('Spectral', 'Spectral', 'Serif'),
  FontEntry('Bitter', 'Bitter', 'Serif'),
  FontEntry('Arvo', 'Arvo', 'Serif'),
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
  FontEntry('Quicksand', 'Quicksand', 'Sans-serif'),
  FontEntry('Mulish', 'Mulish', 'Sans-serif'),
  FontEntry('Work Sans', 'Work Sans', 'Sans-serif'),
  FontEntry('Karla', 'Karla', 'Sans-serif'),
  FontEntry('Cabin', 'Cabin', 'Sans-serif'),
  FontEntry('Fira Sans', 'Fira Sans', 'Sans-serif'),
  FontEntry('Rubik', 'Rubik', 'Sans-serif'),
  FontEntry('IBM Plex Sans', 'IBM Plex Sans', 'Sans-serif'),
  FontEntry('Lato', 'Lato', 'Sans-serif'),
  FontEntry('Oxygen', 'Oxygen', 'Sans-serif'),
  FontEntry('Ubuntu', 'Ubuntu', 'Sans-serif'),
  FontEntry('Manrope', 'Manrope', 'Sans-serif'),
  FontEntry('Outfit', 'Outfit', 'Sans-serif'),
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
  FontEntry('Comfortaa', 'Comfortaa', 'Decorativa'),
  // Manuscrita
  FontEntry('Dancing Script', 'Dancing Script', 'Manuscrita'),
  FontEntry('Great Vibes', 'Great Vibes', 'Manuscrita'),
  FontEntry('Sacramento', 'Sacramento', 'Manuscrita'),
  FontEntry('Caveat', 'Caveat', 'Manuscrita'),
  FontEntry('Kalam', 'Kalam', 'Manuscrita'),
  FontEntry('Patrick Hand', 'Patrick Hand', 'Manuscrita'),
  FontEntry('Indie Flower', 'Indie Flower', 'Manuscrita'),
  FontEntry('Permanent Marker', 'Permanent Marker', 'Manuscrita'),
];

final kFontGroups = ['Todas', 'Serif', 'Sans-serif', 'Monospace', 'Decorativa', 'Manuscrita'];

const kSizes = [8, 10, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72];

const kColors = [
  Color(0xFF000000), Color(0xFF34322D), Color(0xFF5E5E5B), Color(0xFF858481),
  Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFFFFFFF),
  Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFCA8A04),
  Color(0xFF65A30D), Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB),
  Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777),
  Color(0xFFFCA5A5), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFF86EFAC),
  Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFF9A8D4), Color(0xFFFDE68A),
  Color(0xFF6EE7B7), Color(0xFFA5B4FC), Color(0xFFFBCFE8), Color(0xFFE9D5FF),
];

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const EditorApp());
}

class EditorApp extends StatelessWidget {
  const EditorApp({super.key});
  @override
  Widget build(BuildContext ctx) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
          scaffoldBackgroundColor: kBg,
          fontFamily: GoogleFonts.dmSans().fontFamily,
          useMaterial3: true,
        ),
        home: const EditorPage(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EDITOR PAGE
// ─────────────────────────────────────────────────────────────────────────────
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with TickerProviderStateMixin {
  // Controllers
  late quill.QuillController _qc;
  final _titleCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  // Drawer animation
  late AnimationController _drawerCtrl;
  late Animation<double> _drawerAnim;
  bool _drawerOpen = false;

  // Toolbar state
  bool _aiMode = false;
  final _aiCtrl = TextEditingController();
  bool _aiLoading = false;
  String _curFont = 'Lora';
  int _curSize = 16;
  Color _curColor = kInk;
  String _curAlign = 'left';
  bool _a4Mode = false;

  // Active popup overlay
  OverlayEntry? _activeOverlay;

  // Format active states
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrike = false;

  @override
  void initState() {
    super.initState();
    _qc = quill.QuillController.basic();
    _qc.addListener(_onDocChange);
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _drawerAnim = CurvedAnimation(
      parent: _drawerCtrl,
      curve: const Cubic(0.22, 1, 0.36, 1),
      reverseCurve: const Cubic(0.22, 1, 0.36, 1),
    );
  }

  void _onDocChange() {
    final attrs = _qc.getSelectionStyle().attributes;
    setState(() {
      _isBold = attrs.containsKey(quill.Attribute.bold.key) &&
          attrs[quill.Attribute.bold.key]?.value == true;
      _isItalic = attrs.containsKey(quill.Attribute.italic.key) &&
          attrs[quill.Attribute.italic.key]?.value == true;
      _isUnderline = attrs.containsKey(quill.Attribute.underline.key) &&
          attrs[quill.Attribute.underline.key]?.value == true;
      _isStrike = attrs.containsKey(quill.Attribute.strikeThrough.key) &&
          attrs[quill.Attribute.strikeThrough.key]?.value == true;
    });
  }

  @override
  void dispose() {
    _qc.removeListener(_onDocChange);
    _qc.dispose();
    _titleCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _drawerCtrl.dispose();
    _aiCtrl.dispose();
    super.dispose();
  }

  // ── DRAWER ──────────────────────────────────────────────
  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerCtrl.forward();
  }

  void _closeDrawer() {
    _drawerCtrl.reverse().then((_) => setState(() => _drawerOpen = false));
  }

  // ── FORMAT ──────────────────────────────────────────────
  void _toggleBold() {
    _qc.formatSelection(quill.Attribute.bold);
    setState(() => _isBold = !_isBold);
  }

  void _toggleItalic() {
    _qc.formatSelection(quill.Attribute.italic);
    setState(() => _isItalic = !_isItalic);
  }

  void _toggleUnderline() {
    _qc.formatSelection(quill.Attribute.underline);
    setState(() => _isUnderline = !_isUnderline);
  }

  void _toggleStrike() {
    _qc.formatSelection(quill.Attribute.strikeThrough);
    setState(() => _isStrike = !_isStrike);
  }

  void _setAlign(String align) {
    quill.Attribute attr;
    switch (align) {
      case 'center':
        attr = quill.Attribute.centerAlignment;
        break;
      case 'right':
        attr = quill.Attribute.rightAlignment;
        break;
      case 'justify':
        attr = quill.Attribute.justifyAlignment;
        break;
      default:
        attr = quill.Attribute.leftAlignment;
    }
    _qc.formatSelection(attr);
    setState(() => _curAlign = align);
  }

  void _setFont(String family) {
    final attr = quill.Attribute.fromKeyValue('font', family);
    _qc.formatSelection(attr);
    setState(() => _curFont = family);
    _closePopup();
  }

  void _setSize(int sz) {
    final attr = quill.Attribute.fromKeyValue('size', '${sz}px');
    _qc.formatSelection(attr);
    setState(() => _curSize = sz);
  }

  void _setColor(Color c) {
    final hex = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
    final attr = quill.Attribute.fromKeyValue('color', hex);
    _qc.formatSelection(attr);
    setState(() => _curColor = c);
  }

  void _insertBulletList() =>
      _qc.formatSelection(quill.Attribute.ul);

  void _insertOrderedList() =>
      _qc.formatSelection(quill.Attribute.ol);

  void _indent() =>
      _qc.formatSelection(const quill.IndentAttribute(level: 1));

  void _outdent() =>
      _qc.formatSelection(const quill.IndentAttribute(level: -1));

  void _setBlockStyle(quill.Attribute attr) {
    _qc.formatSelection(attr);
    _closePopup();
  }

  // ── POPUP SYSTEM ─────────────────────────────────────────
  void _closePopup() {
    _activeOverlay?.remove();
    _activeOverlay = null;
  }

  void _showPopup({
    required BuildContext triggerCtx,
    required Widget Function(BuildContext, VoidCallback) builder,
    double width = 240,
  }) {
    _closePopup();
    final box = triggerCtx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    double left = pos.dx + size.width / 2 - width / 2;
    left = left.clamp(8.0, screenW - width - 8);
    final bottom = screenH - pos.dy + 12;
    final arrowLeft = (pos.dx + size.width / 2 - left - 9).clamp(12.0, width - 24.0);

    _activeOverlay = OverlayEntry(builder: (ctx) => Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: _closePopup,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
      Positioned(
        left: left,
        bottom: bottom,
        width: width,
        child: _PopupCard(
          arrowLeft: arrowLeft,
          child: builder(ctx, _closePopup),
        ),
      ),
    ]));
    Overlay.of(context).insert(_activeOverlay!);
  }

  // ── AI ───────────────────────────────────────────────────
  void _toggleAI() => setState(() => _aiMode = !_aiMode);

  Future<void> _doAI() async {
    final prompt = _aiCtrl.text.trim();
    if (prompt.isEmpty) return;
    _aiCtrl.clear();
    setState(() => _aiLoading = true);
    try {
      final resp = await _httpPost(
        'https://api.anthropic.com/v1/messages',
        {
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'system': 'Responde APENAS com o texto a inserir no editor, sem explicações nem markdown extra. Responde em português.',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        },
      );
      final txt = (resp['content'] as List?)
              ?.whereType<Map>()
              .map((e) => e['text'] ?? '')
              .join('') ??
          '(sem resposta)';
      final idx = _qc.selection.extentOffset;
      _qc.document.insert(idx, txt);
    } catch (_) {
      final idx = _qc.selection.extentOffset;
      _qc.document.insert(idx, '[Erro IA]');
    }
    setState(() => _aiLoading = false);
  }

  Future<Map<String, dynamic>> _httpPost(String url, Map body) async {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final req = await client.postUrl(uri);
    req.headers.set('Content-Type', 'application/json');
    req.write(jsonEncode(body));
    final resp = await req.close();
    final raw = await resp.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── IMAGE INSERT ─────────────────────────────────────────
  Future<void> _pickImage() async {
    _closePopup();
    final picker = ImagePicker();
    final xf = await picker.pickImage(source: ImageSource.gallery);
    if (xf == null) return;
    final bytes = await xf.readAsBytes();
    final b64 = base64Encode(bytes);
    final ext = xf.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,$b64';
    final idx = _qc.selection.extentOffset;
    _qc.document.insert(idx, quill.BlockEmbed.image(dataUrl));
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext ctx) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final pageW = 794.0;
      final scale = w < pageW + 32 ? (w - 32) / pageW : 1.0;
      return Scaffold(
        backgroundColor: kBg,
        body: AnimatedBuilder(
          animation: _drawerAnim,
          builder: (ctx, _) {
            final dx = _drawerAnim.value * 110.0;
            return Stack(children: [
              // ── APP LAYER ──────────────────────────
              Transform.translate(
                offset: Offset(dx, 0),
                child: Column(children: [
                  _Topbar(
                    titleCtrl: _titleCtrl,
                    onMenu: _openDrawer,
                    onUndo: () => _qc.undo(),
                    onRedo: () => _qc.redo(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
                      child: Center(
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topCenter,
                          child: _a4Mode
                              ? _buildA4Pages()
                              : _buildScrollPage(),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              // ── OVERLAY ────────────────────────────
              if (_drawerOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeDrawer,
                    child: AnimatedOpacity(
                      opacity: _drawerAnim.value * 0.18,
                      duration: Duration.zero,
                      child: Container(color: Colors.black),
                    ),
                  ),
                ),
              // ── DRAWER ─────────────────────────────
              Transform.translate(
                offset: Offset((_drawerAnim.value - 1) * 260, 0),
                child: _Drawer(
                  a4Mode: _a4Mode,
                  aiMode: _aiMode,
                  onToggleAI: () { _toggleAI(); _closeDrawer(); },
                  onToggleA4: () {
                    setState(() => _a4Mode = !_a4Mode);
                    _closeDrawer();
                  },
                ),
              ),
              // ── FLOATING TOOLBAR ───────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                    child: _FloatingToolbar(
                      aiMode: _aiMode,
                      aiLoading: _aiLoading,
                      aiCtrl: _aiCtrl,
                      isBold: _isBold,
                      isItalic: _isItalic,
                      isUnderline: _isUnderline,
                      isStrike: _isStrike,
                      curFont: _curFont,
                      curSize: _curSize,
                      curColor: _curColor,
                      curAlign: _curAlign,
                      onBold: _toggleBold,
                      onItalic: _toggleItalic,
                      onUnderline: _toggleUnderline,
                      onStrike: _toggleStrike,
                      onAlignLeft: () => _setAlign('left'),
                      onAlignCenter: () => _setAlign('center'),
                      onAlignRight: () => _setAlign('right'),
                      onAlignJustify: () => _setAlign('justify'),
                      onList: _insertBulletList,
                      onListOrdered: _insertOrderedList,
                      onIndent: _indent,
                      onOutdent: _outdent,
                      onAISubmit: _doAI,
                      onConfirm: () { _closePopup(); _focusNode.requestFocus(); },
                      onColorTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 254,
                        builder: (_, close) => _ColorPopup(
                          curColor: _curColor,
                          onPick: (c) { _setColor(c); close(); },
                        ),
                      ),
                      onFontTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 240,
                        builder: (_, close) => _FontPopup(
                          curFont: _curFont,
                          onSelect: _setFont,
                          onExpand: () {
                            close();
                            _openFontFullscreen();
                          },
                        ),
                      ),
                      onSizeTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 220,
                        builder: (_, close) => _SizePopup(
                          curSize: _curSize,
                          onSize: (s) { _setSize(s); setState(() => _curSize = s); close(); },
                          onInc: () => setState(() { _curSize = math.min(200, _curSize + 1); _setSize(_curSize); }),
                          onDec: () => setState(() { _curSize = math.max(6, _curSize - 1); _setSize(_curSize); }),
                        ),
                      ),
                      onStylesTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 200,
                        builder: (_, close) => _StylesPopup(
                          onStyle: (attr) { _setBlockStyle(attr); close(); },
                        ),
                      ),
                      onInsertTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 240,
                        builder: (_, close) => _InsertPopup(
                          onImage: _pickImage,
                          onLink: () {
                            close();
                            _showLinkDialog();
                          },
                          onTable: () { _insertTable(); close(); },
                          onHr: () { _insertHr(); close(); },
                          onDate: () { _insertDate(); close(); },
                          onCallout: (type) { _insertCallout(type); close(); },
                        ),
                      ),
                      onFormatTap: (trigCtx) => _showPopup(
                        triggerCtx: trigCtx,
                        width: 240,
                        builder: (_, close) => _FormatPopup(
                          qc: _qc,
                          onDone: close,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
      );
    });
  }

  // ── PAGE BUILDERS ────────────────────────────────────────
  Widget _buildScrollPage() => Container(
        width: 794,
        constraints: const BoxConstraints(minHeight: 1123),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
            BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(88, 96, 88, 120),
        child: _buildEditor(),
      );

  Widget _buildA4Pages() => SizedBox(
        width: 794,
        child: Column(
          children: [
            Container(
              width: 794,
              height: 1123,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
                  BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(88, 96, 88, 96),
              child: Stack(children: [
                _buildEditor(),
                Positioned(
                  right: 20,
                  bottom: 14,
                  child: Text('1', style: dmSans(size: 10, fw: FontWeight.w600, color: kMuted)),
                ),
              ]),
            ),
          ],
        ),
      );

  // ── FIX 1: QuillEditor sem `configurations:`, parâmetros directos.
  // ── FIX 2: DefaultTextBlockStyle com 5 argumentos (+ BoxDecoration? null).
  Widget _buildEditor() => quill.QuillEditor(
        controller: _qc,
        focusNode: _focusNode,
        scrollController: ScrollController(),
        placeholder: 'Começa a escrever…',
        autoFocus: false,
        expands: false,
        scrollable: false,
        padding: EdgeInsets.zero,
        customStyles: quill.DefaultStyles(
          paragraph: quill.DefaultTextBlockStyle(
            GoogleFonts.lora(
              fontSize: 16,
              height: 1.85,
              color: kInk,
            ),
            const quill.HorizontalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            const quill.VerticalSpacing(0, 0),
            null, // BoxDecoration? — 5.º argumento obrigatório na v11
          ),
        ),
      );

  // ── DIALOGS / INSERTS ────────────────────────────────────
  void _showLinkDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Link', style: dmSans(size: 16, fw: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'https://...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: dmSans())),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.isNotEmpty) {
                _qc.formatSelection(quill.LinkAttribute(ctrl.text));
              }
            },
            child: Text('Inserir', style: dmSans(color: kAccent)),
          ),
        ],
      ),
    );
  }

  void _insertTable() {
    final idx = _qc.selection.extentOffset;
    _qc.document.insert(idx, '\n[Tabela 3×3]\n');
  }

  void _insertHr() {
    final idx = _qc.selection.extentOffset;
    _qc.document.insert(idx, '\n──────────────────────\n');
  }

  void _insertDate() {
    final now = DateTime.now();
    final s = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final idx = _qc.selection.extentOffset;
    _qc.document.insert(idx, s);
  }

  void _insertCallout(String type) {
    final labels = {'warning': '▲ Aviso', 'info': 'i Informação', 'success': '✓ Sucesso', 'error': '✕ Erro'};
    final idx = _qc.selection.extentOffset;
    _qc.document.insert(idx, '\n${labels[type] ?? 'Nota'}: Escreve aqui.\n');
  }

  // ── FONT FULLSCREEN ──────────────────────────────────────
  void _openFontFullscreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FontFullscreen(
        curFont: _curFont,
        onSelect: _setFont,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final TextEditingController titleCtrl;
  final VoidCallback onMenu, onUndo, onRedo;
  const _Topbar({required this.titleCtrl, required this.onMenu, required this.onUndo, required this.onRedo});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
          left: 6,
          child: _TbBtn(icon: LucideIcons.menu, onTap: onMenu),
        ),
        SizedBox(
          width: MediaQuery.of(ctx).size.width - 160,
          child: TextField(
            controller: titleCtrl,
            textAlign: TextAlign.center,
            style: dmSans(size: 15, fw: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Sem título',
              hintStyle: dmSans(size: 15, fw: FontWeight.w600, color: kMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
          ),
        ),
        Positioned(
          right: 6,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _TbBtn(icon: LucideIcons.undo2, onTap: onUndo),
            _TbBtn(icon: LucideIcons.redo2, onTap: onRedo),
          ]),
        ),
      ]),
    );
  }
}

class _TbBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _TbBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? kAccentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: active ? kAccent : kSub),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _Drawer extends StatelessWidget {
  final bool a4Mode, aiMode;
  final VoidCallback onToggleAI, onToggleA4;
  const _Drawer({required this.a4Mode, required this.aiMode, required this.onToggleAI, required this.onToggleA4});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: 260,
      height: double.infinity,
      color: kSurface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: MediaQuery.of(ctx).padding.top + 52 + 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text('Funcionalidades',
              style: dmSans(size: 13, fw: FontWeight.w700, color: kMuted)),
        ),
        const Divider(height: 1, color: kBorder),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            _DrawerItem(
              icon: aiMode ? LucideIcons.bot : LucideIcons.keyboard,
              label: aiMode ? 'IA activa' : 'Toolbar / IA',
              active: aiMode,
              onTap: onToggleAI,
            ),
            _DrawerItem(
              icon: a4Mode ? LucideIcons.layout : LucideIcons.fileText,
              label: a4Mode ? 'Formato: A4' : 'Formato: Scroll',
              active: a4Mode,
              onTap: onToggleA4,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: active ? kAccentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: active ? kAccent : kSub),
            const SizedBox(width: 12),
            Text(label, style: dmSans(size: 14, fw: FontWeight.w500, color: active ? kAccent : kInk)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingToolbar extends StatelessWidget {
  final bool aiMode, aiLoading;
  final TextEditingController aiCtrl;
  final bool isBold, isItalic, isUnderline, isStrike;
  final String curFont, curAlign;
  final int curSize;
  final Color curColor;
  final VoidCallback onBold, onItalic, onUnderline, onStrike;
  final VoidCallback onAlignLeft, onAlignCenter, onAlignRight, onAlignJustify;
  final VoidCallback onList, onListOrdered, onIndent, onOutdent;
  final VoidCallback onAISubmit, onConfirm;
  final void Function(BuildContext) onColorTap, onFontTap, onSizeTap, onStylesTap, onInsertTap, onFormatTap;

  const _FloatingToolbar({
    required this.aiMode, required this.aiLoading, required this.aiCtrl,
    required this.isBold, required this.isItalic, required this.isUnderline, required this.isStrike,
    required this.curFont, required this.curAlign, required this.curSize, required this.curColor,
    required this.onBold, required this.onItalic, required this.onUnderline, required this.onStrike,
    required this.onAlignLeft, required this.onAlignCenter, required this.onAlignRight, required this.onAlignJustify,
    required this.onList, required this.onListOrdered, required this.onIndent, required this.onOutdent,
    required this.onAISubmit, required this.onConfirm,
    required this.onColorTap, required this.onFontTap, required this.onSizeTap,
    required this.onStylesTap, required this.onInsertTap, required this.onFormatTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final maxW = math.min(MediaQuery.of(ctx).size.width * 0.96, 460.0);
    return Center(
      child: SizedBox(
        width: maxW,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFAFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
              BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: aiMode
                  ? _buildAIRow(ctx)
                  : _buildToolsRow(ctx),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6, left: 2),
              child: GestureDetector(
                onTap: aiMode ? onAISubmit : onConfirm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: aiMode ? kAccent : kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: aiMode ? Colors.transparent : kBorder, width: 1.5),
                  ),
                  child: Center(
                    child: aiLoading
                        ? const _AIDots()
                        : Icon(
                            aiMode ? LucideIcons.send : LucideIcons.check,
                            size: 16,
                            color: aiMode ? Colors.white : kSub,
                          ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAIRow(BuildContext ctx) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: TextField(
          controller: aiCtrl,
          enabled: !aiLoading,
          style: dmSans(size: 14),
          decoration: InputDecoration(
            hintText: 'Pergunta à IA…',
            hintStyle: dmSans(size: 14, color: kMuted),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => onAISubmit(),
        ),
      );

  Widget _buildToolsRow(BuildContext ctx) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(children: [
        // Color
        Builder(builder: (c) => GestureDetector(
          onTap: () => onColorTap(c),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('A', style: dmSans(size: 16, fw: FontWeight.w900, color: kSub)),
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: curColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
          ),
        )),
        _Divider(),
        // B I U S
        _FmtBtn(label: 'B', bold: true, active: isBold, onTap: onBold),
        _FmtBtn(label: 'I', italic: true, active: isItalic, onTap: onItalic),
        _FmtBtn(label: 'U', underline: true, active: isUnderline, onTap: onUnderline),
        _FmtBtn(label: 'S', strike: true, active: isStrike, onTap: onStrike),
        _Divider(),
        // Font chip
        Builder(builder: (c) => _Chip(
          label: curFont,
          onTap: () => onFontTap(c),
          icon: LucideIcons.chevronDown,
        )),
        const SizedBox(width: 3),
        // Size chip
        Builder(builder: (c) => _Chip(
          label: '$curSize',
          onTap: () => onSizeTap(c),
          icon: LucideIcons.chevronDown,
        )),
        _Divider(),
        // Styles chip
        Builder(builder: (c) => _Chip(
          label: 'Estilos',
          onTap: () => onStylesTap(c),
          icon: LucideIcons.chevronDown,
        )),
        _Divider(),
        // Align
        _IconBtn(icon: LucideIcons.alignLeft, active: curAlign == 'left', onTap: onAlignLeft),
        _IconBtn(icon: LucideIcons.alignCenter, active: curAlign == 'center', onTap: onAlignCenter),
        _IconBtn(icon: LucideIcons.alignRight, active: curAlign == 'right', onTap: onAlignRight),
        _IconBtn(icon: LucideIcons.alignJustify, active: curAlign == 'justify', onTap: onAlignJustify),
        _Divider(),
        // Lists
        _IconBtn(icon: LucideIcons.list, onTap: onList),
        _IconBtn(icon: LucideIcons.listOrdered, onTap: onListOrdered),
        _IconBtn(icon: LucideIcons.indent, onTap: onIndent),
        _IconBtn(icon: LucideIcons.outdent, onTap: onOutdent),
        _Divider(),
        // Insert
        Builder(builder: (c) => _Chip(
          label: 'Inserir',
          onTap: () => onInsertTap(c),
          icon: LucideIcons.plus,
        )),
        _Divider(),
        // Format
        Builder(builder: (c) => _Chip(
          label: 'Formatar',
          onTap: () => onFormatTap(c),
          icon: LucideIcons.settings2,
        )),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
        width: 1, height: 20, color: kBorder,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _FmtBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool bold, italic, underline, strike;
  final VoidCallback onTap;
  const _FmtBtn({required this.label, required this.onTap, this.active = false,
      this.bold = false, this.italic = false, this.underline = false, this.strike = false});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: active ? kAccentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
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
                        : null,
                color: active ? kAccent : kSub,
                fontFamily: GoogleFonts.dmSans().fontFamily,
                height: 1,
              ),
            ),
          ),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: active ? kAccentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(child: Icon(icon, size: 17, color: active ? kAccent : kSub)),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: dmSans(size: 12, fw: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(icon, size: 11, color: kInk),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AI DOTS ANIMATION
// ─────────────────────────────────────────────────────────────────────────────
class _AIDots extends StatefulWidget {
  const _AIDots();
  @override
  State<_AIDots> createState() => _AIDotsState();
}

class _AIDotsState extends State<_AIDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.22).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * math.sin(t * math.pi);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 5, height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
              ),
            );
          }),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// POPUP CARD (with arrow + spring animation)
// ─────────────────────────────────────────────────────────────────────────────
class _PopupCard extends StatefulWidget {
  final Widget child;
  final double arrowLeft;
  const _PopupCard({required this.child, required this.arrowLeft});

  @override
  State<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends State<_PopupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scaleAnim = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Cubic(0.34, 1.56, 0.64, 1)),
    );
    _opacAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _opacAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x21000000), blurRadius: 32, offset: Offset(0, 8)),
                  BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.child,
              ),
            ),
            // Arrow
            SizedBox(
              height: 9,
              child: Stack(children: [
                Positioned(
                  left: widget.arrowLeft,
                  top: 0,
                  child: CustomPaint(
                    size: const Size(18, 9),
                    painter: _ArrowPainter(),
                  ),
                ),
              ]),
            ),
          ],
        ),
      );
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kSurface
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = kBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR POPUP
// ─────────────────────────────────────────────────────────────────────────────
class _ColorPopup extends StatefulWidget {
  final Color curColor;
  final void Function(Color) onPick;
  const _ColorPopup({required this.curColor, required this.onPick});

  @override
  State<_ColorPopup> createState() => _ColorPopupState();
}

class _ColorPopupState extends State<_ColorPopup> {
  late TextEditingController _hexCtrl;
  Color _preview = kInk;

  @override
  void initState() {
    super.initState();
    _preview = widget.curColor;
    _hexCtrl = TextEditingController(
      text: '#${widget.curColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() { _hexCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PopupHeader('Cor do texto'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: kColors.map((c) {
                return GestureDetector(
                  onTap: () => widget.onPick(c),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: c == Colors.white ? const Color(0x26000000) : Colors.transparent,
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
            child: Row(children: [
              Container(
                width: 26, height: 26,
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
                  style: dmSans(size: 12, fw: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kAccent, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                      setState(() => _preview = Color(int.parse('FF${v.substring(1)}', radix: 16)));
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  final v = _hexCtrl.text;
                  if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                    widget.onPick(Color(int.parse('FF${v.substring(1)}', radix: 16)));
                  }
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _preview,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 14))),
                ),
              ),
            ]),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FONT POPUP (inline)
// ─────────────────────────────────────────────────────────────────────────────
class _FontPopup extends StatefulWidget {
  final String curFont;
  final void Function(String) onSelect;
  final VoidCallback onExpand;
  const _FontPopup({required this.curFont, required this.onSelect, required this.onExpand});

  @override
  State<_FontPopup> createState() => _FontPopupState();
}

class _FontPopupState extends State<_FontPopup> {
  final _searchCtrl = TextEditingController();
  FontEntry? _preview;
  String _q = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<FontEntry> get _filtered => kFonts.where((f) => f.label.toLowerCase().contains(_q.toLowerCase())).toList();

  @override
  Widget build(BuildContext ctx) {
    final fonts = _filtered;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child: _PopupHeader('Tipo de letra')),
        GestureDetector(
          onTap: widget.onExpand,
          child: Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
            child: const Icon(LucideIcons.maximize2, size: 14, color: kMuted),
          ),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
        child: TextField(
          controller: _searchCtrl,
          style: dmSans(size: 12.5),
          decoration: InputDecoration(
            hintText: 'Pesquisar…',
            hintStyle: dmSans(size: 12.5, color: kMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      SizedBox(
        height: 190,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildFontList(fonts),
          ),
        ),
      ),
      if (_preview != null) _buildPreview(),
    ]);
  }

  List<Widget> _buildFontList(List<FontEntry> fonts) {
    final items = <Widget>[];
    String? lastGroup;
    for (final f in fonts) {
      if (_q.isEmpty && f.group != lastGroup) {
        if (lastGroup != null) items.add(const Divider(height: 1, color: kBorder));
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
          child: Text(f.group, style: dmSans(size: 10, fw: FontWeight.w700, color: const Color(0xFFCCCCCC))),
        ));
        lastGroup = f.group;
      }
      final active = f.family == widget.curFont;
      items.add(GestureDetector(
        onTap: () => setState(() => _preview = f),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          color: Colors.transparent,
          child: Text(
            f.label,
            style: GoogleFonts.getFont(
              f.family,
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? kAccent : kInk,
            ),
          ),
        ),
      ));
    }
    return items;
  }

  Widget _buildPreview() => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kBorder)),
          color: Color(0xFFFAFAFA),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_preview!.label.toUpperCase(),
              style: dmSans(size: 10, fw: FontWeight.w700, color: kMuted)),
          const SizedBox(height: 4),
          Text('Aa Bb Cc',
              style: GoogleFonts.getFont(_preview!.family, fontSize: 26, color: kInk, height: 1.2)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => widget.onSelect(_preview!.family),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('Aplicar', style: dmSans(size: 12.5, fw: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE POPUP
// ─────────────────────────────────────────────────────────────────────────────
class _SizePopup extends StatefulWidget {
  final int curSize;
  final void Function(int) onSize;
  final VoidCallback onInc, onDec;
  const _SizePopup({required this.curSize, required this.onSize, required this.onInc, required this.onDec});

  @override
  State<_SizePopup> createState() => _SizePopupState();
}

class _SizePopupState extends State<_SizePopup> {
  late int _sz;

  @override
  void initState() { super.initState(); _sz = widget.curSize; }

  @override
  Widget build(BuildContext ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        _PopupHeader('Tamanho'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            _StepBtn(label: '−', onTap: () { setState(() => _sz = math.max(6, _sz - 1)); widget.onSize(_sz); }),
            Expanded(
              child: Center(
                child: Text('$_sz', style: dmSans(size: 20, fw: FontWeight.w700)),
              ),
            ),
            _StepBtn(label: '+', onTap: () { setState(() => _sz = math.min(200, _sz + 1)); widget.onSize(_sz); }),
          ]),
        ),
        const Divider(height: 1, color: kBorder),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: kSizes.map((s) {
              final active = s == _sz;
              return GestureDetector(
                onTap: () { setState(() => _sz = s); widget.onSize(s); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active ? kAccent : kBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    color: active ? kAccentBg : Colors.transparent,
                  ),
                  child: Text('$s',
                      style: dmSans(size: 12, fw: FontWeight.w600, color: active ? kAccent : kSub)),
                ),
              );
            }).toList(),
          ),
        ),
      ]);
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: kBorder, width: 1.5),
            borderRadius: BorderRadius.circular(9),
            color: kSurface,
          ),
          child: Center(child: Text(label, style: dmSans(size: 18, color: kSub))),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STYLES POPUP
// FIX 3: lista tipada como (String, IconData, quill.Attribute) — sem nullable.
// ─────────────────────────────────────────────────────────────────────────────
class _StylesPopup extends StatelessWidget {
  final void Function(quill.Attribute) onStyle;
  const _StylesPopup({required this.onStyle});

  static final List<(String, IconData, quill.Attribute)> _items = [
    ('Parágrafo', LucideIcons.pilcrow, quill.Attribute.fromKeyValue('blockquote', null) as quill.Attribute),
    ('Título 1', LucideIcons.heading1, quill.HeaderAttribute(level: 1)),
    ('Título 2', LucideIcons.heading2, quill.HeaderAttribute(level: 2)),
    ('Título 3', LucideIcons.heading3, quill.HeaderAttribute(level: 3)),
    ('Citação', LucideIcons.quote, quill.Attribute.blockQuote),
    ('Código', LucideIcons.code, quill.Attribute.codeBlock),
  ];

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupHeader('Estilo de parágrafo'),
          ..._items.map((t) => _PopupItem(
                label: t.$1,
                icon: t.$2,
                // FIX 3: t.$3 já é Attribute não-nullable — sem cast adicional.
                onTap: () => onStyle(t.$3),
              )),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// INSERT POPUP
// ─────────────────────────────────────────────────────────────────────────────
class _InsertPopup extends StatelessWidget {
  final VoidCallback onImage, onLink, onTable, onHr, onDate;
  final void Function(String) onCallout;
  const _InsertPopup({
    required this.onImage, required this.onLink, required this.onTable,
    required this.onHr, required this.onDate, required this.onCallout,
  });

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupHeader('Inserir'),
          _PopupItem(label: 'Link', icon: LucideIcons.link, onTap: onLink),
          _PopupItem(label: 'Imagem', icon: LucideIcons.image, onTap: onImage),
          _PopupItem(label: 'Tabela 3×3', icon: LucideIcons.table, onTap: onTable),
          const Divider(height: 1, color: kBorder),
          _PopupItem(label: 'Linha divisória', icon: LucideIcons.minus, onTap: onHr),
          _PopupItem(label: 'Data e hora', icon: LucideIcons.calendar, onTap: onDate),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
            child: Text('CAIXAS DE DESTAQUE',
                style: dmSans(size: 10, fw: FontWeight.w700, color: const Color(0xFFCCCCCC))),
          ),
          _PopupItem(label: 'Aviso', icon: LucideIcons.alertTriangle, onTap: () => onCallout('warning')),
          _PopupItem(label: 'Informação', icon: LucideIcons.info, onTap: () => onCallout('info')),
          _PopupItem(label: 'Sucesso', icon: LucideIcons.checkCircle, onTap: () => onCallout('success')),
          _PopupItem(label: 'Erro', icon: LucideIcons.xCircle, onTap: () => onCallout('error')),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMAT POPUP
// FIX 4: superscript/subscript — nomes correctos na v11.
// FIX 5: ClearStyleAttribute removido — substituído por limpar atributo a atributo.
// ─────────────────────────────────────────────────────────────────────────────
class _FormatPopup extends StatelessWidget {
  final quill.QuillController qc;
  final VoidCallback onDone;
  const _FormatPopup({required this.qc, required this.onDone});

  String _getSelectedText() {
    final sel = qc.selection;
    if (sel.isCollapsed) return '';
    return qc.document.toPlainText().substring(
          sel.start.clamp(0, qc.document.length - 1),
          sel.end.clamp(0, qc.document.length - 1),
        );
  }

  void _replaceSelected(String newText) {
    final sel = qc.selection;
    if (sel.isCollapsed) return;
    qc.document.replace(sel.start, sel.end - sel.start, newText);
  }

  // FIX 5: limpa todos os atributos inline conhecidos em vez de ClearStyleAttribute.
  void _clearFormatting() {
    final attrs = qc.getSelectionStyle().attributes;
    for (final attr in attrs.values) {
      // Para limpar, passa o mesmo atributo com valor null
      final cleared = quill.Attribute.clone(attr, null);
      if (cleared != null) qc.formatSelection(cleared);
    }
  }

  @override
  Widget build(BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopupHeader('Formatar'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
            child: Text('MAIÚSCULAS',
                style: dmSans(size: 10, fw: FontWeight.w700, color: const Color(0xFFCCCCCC))),
          ),
          _PopupItem(label: 'MAIÚSCULAS', icon: LucideIcons.caseUpper, onTap: () {
            _replaceSelected(_getSelectedText().toUpperCase()); onDone();
          }),
          _PopupItem(label: 'minúsculas', icon: LucideIcons.caseLower, onTap: () {
            _replaceSelected(_getSelectedText().toLowerCase()); onDone();
          }),
          _PopupItem(label: 'Primeira Maiúscula', icon: LucideIcons.caseSensitive, onTap: () {
            final t = _getSelectedText().replaceAllMapped(
                RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
            _replaceSelected(t); onDone();
          }),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
            child: Text('INLINE',
                style: dmSans(size: 10, fw: FontWeight.w700, color: const Color(0xFFCCCCCC))),
          ),
          // FIX 4: Attribute.superscript / Attribute.subscript (minúsculas na v11)
          _PopupItem(label: 'Sobrescrito', icon: LucideIcons.superscript, onTap: () {
            qc.formatSelection(quill.Attribute.superscript); onDone();
          }),
          _PopupItem(label: 'Subscrito', icon: LucideIcons.subscript, onTap: () {
            qc.formatSelection(quill.Attribute.subscript); onDone();
          }),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
            child: Text('ESPAÇAMENTO',
                style: dmSans(size: 10, fw: FontWeight.w700, color: const Color(0xFFCCCCCC))),
          ),
          _PopupItem(label: '1.0 — Compacto', icon: LucideIcons.alignVerticalJustifyStart, onTap: () {
            qc.formatSelection(quill.Attribute.fromKeyValue('line-height', '1.0'));
            onDone();
          }),
          _PopupItem(label: '1.5 — Normal', icon: LucideIcons.alignVerticalJustifyStart, onTap: () {
            qc.formatSelection(quill.Attribute.fromKeyValue('line-height', '1.5'));
            onDone();
          }),
          _PopupItem(label: '2.0 — Espaçado', icon: LucideIcons.alignVerticalJustifyStart, onTap: () {
            qc.formatSelection(quill.Attribute.fromKeyValue('line-height', '2.0'));
            onDone();
          }),
          const Divider(height: 1, color: kBorder),
          // FIX 5: sem ClearStyleAttribute — usa _clearFormatting()
          _PopupItem(
            label: 'Limpar formatação',
            icon: LucideIcons.trash2,
            danger: true,
            onTap: () { _clearFormatting(); onDone(); },
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED POPUP WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _PopupHeader extends StatelessWidget {
  final String title;
  const _PopupHeader(this.title);

  @override
  Widget build(BuildContext ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Text(title.toUpperCase(),
            style: dmSans(size: 10.5, fw: FontWeight.w700, color: kMuted)),
      );
}

class _PopupItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _PopupItem({required this.label, required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(children: [
            Icon(icon, size: 15, color: danger ? Colors.red.shade400 : kMuted),
            const SizedBox(width: 10),
            Text(label,
                style: dmSans(
                  size: 13,
                  fw: FontWeight.w500,
                  color: danger ? Colors.red.shade600 : kInk,
                )),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FONT FULLSCREEN BROWSER
// ─────────────────────────────────────────────────────────────────────────────
class _FontFullscreen extends StatefulWidget {
  final String curFont;
  final void Function(String) onSelect;
  const _FontFullscreen({required this.curFont, required this.onSelect});

  @override
  State<_FontFullscreen> createState() => _FontFullscreenState();
}

class _FontFullscreenState extends State<_FontFullscreen> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  String _cat = 'Todas';
  FontEntry? _selected;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<FontEntry> get _fonts => kFonts.where((f) {
        final matchQ = f.label.toLowerCase().contains(_q.toLowerCase());
        final matchC = _cat == 'Todas' || f.group == _cat;
        return matchQ && matchC;
      }).toList();

  @override
  Widget build(BuildContext ctx) {
    return Container(
      height: MediaQuery.of(ctx).size.height * 0.92,
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // Header
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(children: [
            Text('Fontes', style: dmSans(size: 14, fw: FontWeight.w700)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: dmSans(size: 13),
                decoration: InputDecoration(
                  hintText: 'Pesquisar fonte…',
                  hintStyle: dmSans(size: 13, color: kMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: kBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: kAccent, width: 1.5),
                  ),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
                child: const Icon(LucideIcons.x, size: 17, color: kSub),
              ),
            ),
          ]),
        ),
        // Categories
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            children: kFontGroups.map((g) {
              final active = g == _cat;
              return GestureDetector(
                onTap: () => setState(() => _cat = g),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? kAccentBg : Colors.transparent,
                    border: Border.all(
                      color: active ? kAccent : kBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(g,
                      style: dmSans(
                        size: 12,
                        fw: FontWeight.w600,
                        color: active ? kAccent : kSub,
                      )),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: kBorder),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: _fonts.length,
            itemBuilder: (_, i) {
              final f = _fonts[i];
              final active = _selected?.family == f.family;
              return GestureDetector(
                onTap: () => setState(() => _selected = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active ? kAccent : kBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: active ? kAccentBg : kSurface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.group,
                          style: dmSans(size: 10, fw: FontWeight.w700, color: kMuted),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text('Aa Bb',
                            style: GoogleFonts.getFont(f.family, fontSize: 20, color: kInk, height: 1.2),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(f.label,
                          style: dmSans(size: 10, color: kSub),
                          overflow: TextOverflow.ellipsis),
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
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: _selected != null
                  ? () {
                      widget.onSelect(_selected!.family);
                      Navigator.pop(ctx);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selected != null ? kAccent : const Color(0x14000000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _selected != null ? 'Aplicar "${_selected!.label}"' : 'Aplicar fonte',
                    style: dmSans(
                      size: 13.5,
                      fw: FontWeight.w600,
                      color: _selected != null ? Colors.white : kMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}