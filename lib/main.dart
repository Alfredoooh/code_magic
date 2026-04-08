// ============================================================
// ESTRUTURA DO PROJETO
// lib/
//   main.dart
//   theme/app_theme.dart
//   widgets/
//     topbar.dart
//     floating_toolbar.dart
//     toolbar_chip.dart
//     toolbar_btn.dart
//     page_canvas.dart
//     drawer_menu.dart
//     popups/
//       popup_base.dart
//       color_popup.dart
//       font_popup.dart
//       size_popup.dart
//       styles_popup.dart
//       insert_popup.dart
//       format_popup.dart
//       fullscreen_fonts.dart
//     selection_menu.dart
//   models/
//     editor_state.dart
//     font_data.dart
//
// pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_quill: 10.8.2
//   google_fonts: ^6.2.1
//   provider: ^6.1.2
//   flutter_svg: ^2.0.10
//   image_picker: ^1.1.2
//   file_picker: ^8.1.2
// ============================================================

// ════════════════════════════════════════════════════════════
// main.dart
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

// ── COLOURS ─────────────────────────────────────────────────
const kAccent     = Color(0xFF2563EB);
const kAccentBg   = Color(0xFFEFF6FF);
const kInk        = Color(0xFF34322D);
const kSub        = Color(0xFF5E5E5B);
const kMuted      = Color(0xFF858481);
const kSurface    = Color(0xFFFFFFFF);
const kBg         = Color(0xFFF8F8F7);
const kBorder     = Color(0x14000000); // 8%
const kBorderMed  = Color(0x1F000000); // 12%

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => EditorState(),
      child: const EditorApp(),
    ),
  );
}

// ════════════════════════════════════════════════════════════
// EDITOR STATE
// ════════════════════════════════════════════════════════════
class EditorState extends ChangeNotifier {
  final QuillController controller = QuillController.basic();
  final FocusNode editorFocus = FocusNode();
  final ScrollController scrollCtrl = ScrollController();
  final TextEditingController titleCtrl = TextEditingController();

  bool drawerOpen = false;
  bool a4Mode = false;
  bool aiMode = false;
  bool readOnly = false;
  String currentFont = 'Lora';
  double currentSize = 16;
  TextAlign currentAlign = TextAlign.left;
  Color currentColor = kInk;
  String activePopup = '';
  int wordCount = 0;
  int charCount = 0;

  EditorState() {
    controller.addListener(_updateCounts);
  }

  void _updateCounts() {
    final text = controller.document.toPlainText().trim();
    wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    charCount = text.isEmpty ? 0 : text.length;
    notifyListeners();
  }

  void setDrawer(bool v) { drawerOpen = v; notifyListeners(); }
  void setA4(bool v) { a4Mode = v; notifyListeners(); }
  void setAI(bool v) { aiMode = v; notifyListeners(); }
  void setReadOnly(bool v) { readOnly = v; controller.readOnly = v; notifyListeners(); }
  void setFont(String f) { currentFont = f; notifyListeners(); }
  void setSize(double s) { currentSize = s; notifyListeners(); }
  void setAlign(TextAlign a) { currentAlign = a; notifyListeners(); }
  void setColor(Color c) { currentColor = c; notifyListeners(); }
  void setActivePopup(String p) { activePopup = p; notifyListeners(); }
  void clearPopup() { activePopup = ''; notifyListeners(); }

  @override
  void dispose() {
    controller.dispose();
    editorFocus.dispose();
    scrollCtrl.dispose();
    titleCtrl.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════
// APP
// ════════════════════════════════════════════════════════════
class EditorApp extends StatelessWidget {
  const EditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kAccent,
        scaffoldBackgroundColor: kBg,
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      home: const EditorScaffold(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MAIN SCAFFOLD
// ════════════════════════════════════════════════════════════
class EditorScaffold extends StatelessWidget {
  const EditorScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorState>(builder: (ctx, state, _) {
      return Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            // ── Main app column ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(state.drawerOpen ? 110 : 0, 0, 0),
              child: Column(
                children: [
                  const EditorTopbar(),
                  Expanded(child: EditorCanvas()),
                ],
              ),
            ),
            // ── Overlay ──
            AnimatedOpacity(
              opacity: state.drawerOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: !state.drawerOpen,
                child: GestureDetector(
                  onTap: () => state.setDrawer(false),
                  child: Container(color: const Color(0x2E000000)),
                ),
              ),
            ),
            // ── Drawer ──
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: state.drawerOpen ? 0 : -260,
              top: 0, bottom: 0,
              width: 260,
              child: const EditorDrawer(),
            ),
            // ── Floating toolbar ──
            const Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(child: FloatingToolbar()),
            ),
            // ── Popup mask ──
            if (state.activePopup.isNotEmpty)
              Positioned.fill(
                child: GestureDetector(
                  onTap: state.clearPopup,
                  child: Container(color: Colors.transparent),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════
// TOPBAR
// ════════════════════════════════════════════════════════════
class EditorTopbar extends StatelessWidget {
  const EditorTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left
          Positioned(
            left: 6,
            child: _TopbarIcon(
              icon: Icons.menu_rounded,
              onTap: () => state.setDrawer(true),
            ),
          ),
          // Title
          Positioned(
            left: 56, right: 100,
            child: Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: state.titleCtrl,
                  style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w600, color: kInk,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Sem título',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600, color: kMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: kAccent, width: 1.5),
                    ),
                    fillColor: Colors.transparent,
                    focusColor: kAccentBg,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
              ),
            ),
          ),
          // Right
          Positioned(
            right: 6,
            child: Row(
              children: [
                _TopbarIcon(
                  icon: Icons.undo_rounded,
                  onTap: () {
                    state.controller.undo();
                  },
                ),
                _TopbarIcon(
                  icon: Icons.redo_rounded,
                  onTap: () {
                    state.controller.redo();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 44, height: 44,
          child: Icon(icon, size: 20, color: kSub),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DRAWER
// ════════════════════════════════════════════════════════════
class EditorDrawer extends StatelessWidget {
  const EditorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: kSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(2,0))],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
              child: Text(
                'FUNCIONALIDADES',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.06 * 13),
              ),
            ),
            const Divider(color: kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: state.aiMode ? Icons.smart_toy_outlined : Icons.keyboard_outlined,
                    label: state.aiMode ? 'IA activa' : 'Toolbar / IA',
                    active: state.aiMode,
                    onTap: () { state.setAI(!state.aiMode); state.setDrawer(false); },
                  ),
                  _DrawerItem(
                    icon: state.a4Mode ? Icons.grid_view_rounded : Icons.article_outlined,
                    label: state.a4Mode ? 'Formato: A4' : 'Formato: Scroll',
                    active: state.a4Mode,
                    onTap: () { state.setA4(!state.a4Mode); state.setDrawer(false); },
                  ),
                  _DrawerItem(
                    icon: state.readOnly ? Icons.edit_outlined : Icons.visibility_outlined,
                    label: state.readOnly ? 'Modo Leitura' : 'Modo Edição',
                    active: false,
                    onTap: () { state.setReadOnly(!state.readOnly); state.setDrawer(false); },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
  Widget build(BuildContext context) {
    return Material(
      color: active ? kAccentBg : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? kAccent : kSub),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: active ? kAccent : kInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PAGE CANVAS
// ════════════════════════════════════════════════════════════
class EditorCanvas extends StatelessWidget {
  const EditorCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Container(
      color: kBg,
      child: LayoutBuilder(builder: (ctx, constraints) {
        const pageW = 794.0;
        final scale = (constraints.maxWidth - 32) < pageW
            ? (constraints.maxWidth - 32) / pageW
            : 1.0;
        return SingleChildScrollView(
          controller: state.scrollCtrl,
          padding: EdgeInsets.fromLTRB(16, 28, 16, state.a4Mode ? 100 : 200),
          child: Center(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: state.a4Mode ? _A4Pages(pageW: pageW) : _ScrollPage(pageW: pageW),
            ),
          ),
        );
      }),
    );
  }
}

class _ScrollPage extends StatelessWidget {
  final double pageW;
  const _ScrollPage({required this.pageW});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: pageW,
      constraints: const BoxConstraints(minHeight: 1123),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0,1)),
          BoxShadow(color: Colors.black.withOpacity(state.editorFocus.hasFocus ? 0.12 : 0.06), blurRadius: state.editorFocus.hasFocus ? 36 : 20, offset: const Offset(0,4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(88, 96, 88, 120),
      child: _EditorContent(pageW: pageW),
    );
  }
}

class _A4Pages extends StatelessWidget {
  final double pageW;
  const _A4Pages({required this.pageW});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _A4Page(pageW: pageW, pageNum: 1, isEditable: true),
      ],
    );
  }
}

class _A4Page extends StatelessWidget {
  final double pageW;
  final int pageNum;
  final bool isEditable;
  const _A4Page({required this.pageW, required this.pageNum, required this.isEditable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: pageW,
      height: 1123,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0,1)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0,4)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(88, 96, 88, 96),
            child: _EditorContent(pageW: pageW),
          ),
          Positioned(
            bottom: 14, right: 20,
            child: Text(
              '$pageNum',
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted),
            ),
          ),
          // Bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x0F000000)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorContent extends StatelessWidget {
  final double pageW;
  const _EditorContent({required this.pageW});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final editorStyle = DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        GoogleFonts.lora(fontSize: state.currentSize, height: 1.85, color: kInk),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
    );
    return QuillEditor(
      controller: state.controller,
      focusNode: state.editorFocus,
      scrollController: ScrollController(),
      configurations: QuillEditorConfigurations(
        placeholder: 'Começa a escrever…',
        autoFocus: false,
        expands: false,
        scrollable: false,
        padding: EdgeInsets.zero,
        customStyles: editorStyle,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FLOATING TOOLBAR
// ════════════════════════════════════════════════════════════
class FloatingToolbar extends StatelessWidget {
  const FloatingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFAFFFFFF),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
              BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: state.aiMode
                    ? const _AIInputRow()
                    : const _ToolbarTrack(),
              ),
              _ConfirmButton(aiMode: state.aiMode),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarTrack extends StatelessWidget {
  const _ToolbarTrack();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFAFAFA), Colors.transparent, Colors.transparent, Color(0xFFFAFAFA)],
        stops: [0.0, 0.04, 0.88, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstOut,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            // Color
            _TbBtn(
              onTap: () => _showPopup(context, 'color-text'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('A', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w900, color: kSub)),
                  Container(
                    width: 16, height: 3,
                    decoration: BoxDecoration(color: state.currentColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
            ),
            const _TbDivider(),
            // Bold
            _TbBtn(onTap: () => _execFormat(context, Attribute.bold), child: Text('B', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w900, color: kSub))),
            // Italic
            _TbBtn(onTap: () => _execFormat(context, Attribute.italic), child: Text('I', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: kSub))),
            // Underline
            _TbBtn(
              onTap: () => _execFormat(context, Attribute.underline),
              child: Text('U', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: kSub, decoration: TextDecoration.underline)),
            ),
            // Strikethrough
            _TbBtn(
              onTap: () => _execFormat(context, Attribute.strikeThrough),
              child: Text('S', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: kSub, decoration: TextDecoration.lineThrough)),
            ),
            const _TbDivider(),
            // Font chip
            _TbChip(label: state.currentFont, onTap: () => _showPopup(context, 'font')),
            const SizedBox(width: 3),
            // Size chip
            _TbChip(label: state.currentSize.toInt().toString(), onTap: () => _showPopup(context, 'size')),
            const _TbDivider(),
            _TbChip(label: 'Estilos', onTap: () => _showPopup(context, 'styles')),
            const _TbDivider(),
            // Align left
            _TbBtn(
              active: state.currentAlign == TextAlign.left,
              onTap: () => _setAlign(context, TextAlign.left),
              child: const Icon(Icons.format_align_left_rounded, size: 17, color: kSub),
            ),
            _TbBtn(
              active: state.currentAlign == TextAlign.center,
              onTap: () => _setAlign(context, TextAlign.center),
              child: const Icon(Icons.format_align_center_rounded, size: 17, color: kSub),
            ),
            _TbBtn(
              active: state.currentAlign == TextAlign.right,
              onTap: () => _setAlign(context, TextAlign.right),
              child: const Icon(Icons.format_align_right_rounded, size: 17, color: kSub),
            ),
            _TbBtn(
              active: state.currentAlign == TextAlign.justify,
              onTap: () => _setAlign(context, TextAlign.justify),
              child: const Icon(Icons.format_align_justify_rounded, size: 17, color: kSub),
            ),
            const _TbDivider(),
            _TbBtn(onTap: () => _execAttr(context, Attribute.ul), child: const Icon(Icons.format_list_bulleted_rounded, size: 17, color: kSub)),
            _TbBtn(onTap: () => _execAttr(context, Attribute.ol), child: const Icon(Icons.format_list_numbered_rounded, size: 17, color: kSub)),
            _TbBtn(onTap: () => _execAttr(context, Attribute.indentL1), child: const Icon(Icons.format_indent_increase_rounded, size: 17, color: kSub)),
            _TbBtn(onTap: () => _execAttr(context, Attribute.indentL1), child: const Icon(Icons.format_indent_decrease_rounded, size: 17, color: kSub)),
            const _TbDivider(),
            _TbChip(label: 'Inserir', trailingIcon: Icons.add_rounded, onTap: () => _showPopup(context, 'insert')),
            const _TbDivider(),
            _TbChip(label: 'Formatar', trailingIcon: Icons.tune_rounded, onTap: () => _showPopup(context, 'format')),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }

  void _execFormat(BuildContext ctx, Attribute attr) {
    final s = ctx.read<EditorState>();
    s.controller.formatSelection(attr);
  }

  void _execAttr(BuildContext ctx, Attribute attr) {
    final s = ctx.read<EditorState>();
    s.controller.formatSelection(attr);
  }

  void _setAlign(BuildContext ctx, TextAlign align) {
    final s = ctx.read<EditorState>();
    s.setAlign(align);
    Attribute? attr;
    switch (align) {
      case TextAlign.left: attr = Attribute.leftAlignment; break;
      case TextAlign.center: attr = Attribute.centerAlignment; break;
      case TextAlign.right: attr = Attribute.rightAlignment; break;
      case TextAlign.justify: attr = Attribute.justifyAlignment; break;
      default: attr = Attribute.leftAlignment;
    }
    s.controller.formatSelection(attr);
  }

  void _showPopup(BuildContext ctx, String id) {
    final state = ctx.read<EditorState>();
    if (state.activePopup == id) { state.clearPopup(); return; }
    state.setActivePopup(id);
    // Show as bottom sheet popup
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _popupWidget(id),
      ),
    ).then((_) => state.clearPopup());
  }

  Widget _popupWidget(String id) {
    switch (id) {
      case 'color-text': return const ColorPopupSheet();
      case 'font': return const FontPopupSheet();
      case 'size': return const SizePopupSheet();
      case 'styles': return const StylesPopupSheet();
      case 'insert': return const InsertPopupSheet();
      case 'format': return const FormatPopupSheet();
      default: return const SizedBox();
    }
  }
}

class _AIInputRow extends StatefulWidget {
  const _AIInputRow();
  @override
  State<_AIInputRow> createState() => _AIInputRowState();
}

class _AIInputRowState extends State<_AIInputRow> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: GoogleFonts.dmSans(fontSize: 14, color: kInk),
            decoration: InputDecoration(
              hintText: 'Pergunta à IA…',
              hintStyle: GoogleFonts.dmSans(fontSize: 14, color: kMuted),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _doAI(context),
          ),
        ),
        if (_loading) const _AIDots(),
      ],
    );
  }

  Future<void> _doAI(BuildContext ctx) async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    // AI call happens via confirm button → handled externally
    setState(() => _loading = false);
  }
}

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = (_ctrl.value + i * 0.2) % 1.0;
            final scale = t < 0.4 ? 0.6 + 0.4 * (t / 0.4) : t < 0.8 ? 1.0 - 0.4 * ((t - 0.4) / 0.4) : 0.6;
            final opacity = scale < 0.8 ? 0.4 : 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: kAccent.withOpacity(opacity),
                shape: BoxShape.circle,
                transform: Matrix4.identity()..scale(scale),
              ),
            );
          },
        )),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool aiMode;
  const _ConfirmButton({required this.aiMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, left: 2),
      child: GestureDetector(
        onTap: () {
          if (aiMode) {
            context.read<EditorState>().setAI(false);
          } else {
            context.read<EditorState>().editorFocus.requestFocus();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: aiMode ? kAccent : kSurface,
            shape: BoxShape.circle,
            border: Border.all(color: aiMode ? Colors.transparent : kBorder, width: 1.5),
          ),
          child: Icon(
            aiMode ? Icons.send_rounded : Icons.check_rounded,
            size: 16,
            color: aiMode ? Colors.white : kSub,
          ),
        ),
      ),
    );
  }
}

// ── Toolbar atoms ────────────────────────────────────────────
class _TbBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const _TbBtn({required this.child, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 38,
        constraints: const BoxConstraints(minWidth: 38),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: active ? kAccentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _TbChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData trailingIcon;
  const _TbChip({required this.label, required this.onTap, this.trailingIcon = Icons.keyboard_arrow_down_rounded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(width: 3),
            Icon(trailingIcon, size: 11, color: kInk),
          ],
        ),
      ),
    );
  }
}

class _TbDivider extends StatelessWidget {
  const _TbDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 20,
      color: kBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ════════════════════════════════════════════════════════════
// POPUP SHEETS — base
// ════════════════════════════════════════════════════════════
class _PopupSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  const _PopupSheet({required this.title, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 90),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Color(0x21000000), blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.dmSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.07 * 10.5),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// COLOR POPUP
// ════════════════════════════════════════════════════════════
const _kColors = [
  Color(0xFF000000), Color(0xFF34322D), Color(0xFF5E5E5B), Color(0xFF858481),
  Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFFFFFFF),
  Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFCA8A04),
  Color(0xFF65A30D), Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB),
  Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777),
  Color(0xFFFCA5A5), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFF86EFAC),
  Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFF9A8D4), Color(0xFFFDE68A),
  Color(0xFF6EE7B7), Color(0xFFA5B4FC), Color(0xFFFBCFE8), Color(0xFFE9D5FF),
];

class ColorPopupSheet extends StatefulWidget {
  const ColorPopupSheet({super.key});
  @override
  State<ColorPopupSheet> createState() => _ColorPopupSheetState();
}

class _ColorPopupSheetState extends State<ColorPopupSheet> {
  final _hexCtrl = TextEditingController(text: '#34322D');
  Color _preview = kInk;

  @override
  Widget build(BuildContext context) {
    return _PopupSheet(
      title: 'Cor do texto',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8, crossAxisSpacing: 5, mainAxisSpacing: 5,
              ),
              itemCount: _kColors.length,
              itemBuilder: (_, i) {
                final c = _kColors[i];
                return GestureDetector(
                  onTap: () { _applyColor(context, c); Navigator.pop(context); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c == const Color(0xFFFFFFFF) ? kBorderMed : Colors.transparent, width: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: _preview, borderRadius: BorderRadius.circular(6), border: Border.all(color: kBorderMed, width: 1.5)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hexCtrl,
                    style: GoogleFonts.ibmPlexMono(fontSize: 12, color: kInk),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                        final hex = int.tryParse('FF${v.substring(1)}', radix: 16);
                        if (hex != null) setState(() => _preview = Color(hex));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () { _applyColor(context, _preview); Navigator.pop(context); },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: _preview, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _applyColor(BuildContext ctx, Color c) {
    final state = ctx.read<EditorState>();
    state.setColor(c);
    final hex = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
    state.controller.formatSelection(ColorAttribute(hex));
  }
}

// ════════════════════════════════════════════════════════════
// FONT DATA
// ════════════════════════════════════════════════════════════
class FontEntry {
  final String label;
  final String group;
  FontEntry({required this.label, required this.group});
}

final kFontGroups = <String, List<FontEntry>>{
  'Serif': [
    FontEntry(label: 'Lora', group: 'Serif'),
    FontEntry(label: 'Playfair Display', group: 'Serif'),
    FontEntry(label: 'Merriweather', group: 'Serif'),
    FontEntry(label: 'Georgia', group: 'Serif'),
    FontEntry(label: 'Source Serif 4', group: 'Serif'),
    FontEntry(label: 'PT Serif', group: 'Serif'),
    FontEntry(label: 'Libre Baskerville', group: 'Serif'),
    FontEntry(label: 'EB Garamond', group: 'Serif'),
    FontEntry(label: 'Crimson Text', group: 'Serif'),
    FontEntry(label: 'Cormorant Garamond', group: 'Serif'),
  ],
  'Sans-serif': [
    FontEntry(label: 'Inter', group: 'Sans-serif'),
    FontEntry(label: 'Open Sans', group: 'Sans-serif'),
    FontEntry(label: 'Montserrat', group: 'Sans-serif'),
    FontEntry(label: 'DM Sans', group: 'Sans-serif'),
    FontEntry(label: 'Roboto', group: 'Sans-serif'),
    FontEntry(label: 'Nunito', group: 'Sans-serif'),
    FontEntry(label: 'Poppins', group: 'Sans-serif'),
    FontEntry(label: 'Raleway', group: 'Sans-serif'),
    FontEntry(label: 'Work Sans', group: 'Sans-serif'),
    FontEntry(label: 'Rubik', group: 'Sans-serif'),
    FontEntry(label: 'IBM Plex Sans', group: 'Sans-serif'),
  ],
  'Monospace': [
    FontEntry(label: 'IBM Plex Mono', group: 'Monospace'),
    FontEntry(label: 'Source Code Pro', group: 'Monospace'),
    FontEntry(label: 'Fira Code', group: 'Monospace'),
    FontEntry(label: 'JetBrains Mono', group: 'Monospace'),
    FontEntry(label: 'Space Mono', group: 'Monospace'),
    FontEntry(label: 'Inconsolata', group: 'Monospace'),
  ],
  'Decorativa': [
    FontEntry(label: 'Cinzel', group: 'Decorativa'),
    FontEntry(label: 'Abril Fatface', group: 'Decorativa'),
    FontEntry(label: 'Pacifico', group: 'Decorativa'),
  ],
  'Manuscrita': [
    FontEntry(label: 'Dancing Script', group: 'Manuscrita'),
    FontEntry(label: 'Great Vibes', group: 'Manuscrita'),
    FontEntry(label: 'Caveat', group: 'Manuscrita'),
    FontEntry(label: 'Patrick Hand', group: 'Manuscrita'),
    FontEntry(label: 'Indie Flower', group: 'Manuscrita'),
    FontEntry(label: 'Permanent Marker', group: 'Manuscrita'),
  ],
};

List<FontEntry> get kAllFonts => kFontGroups.values.expand((e) => e).toList();

// ════════════════════════════════════════════════════════════
// FONT POPUP
// ════════════════════════════════════════════════════════════
class FontPopupSheet extends StatefulWidget {
  const FontPopupSheet({super.key});
  @override
  State<FontPopupSheet> createState() => _FontPopupSheetState();
}

class _FontPopupSheetState extends State<FontPopupSheet> {
  final _search = TextEditingController();
  FontEntry? _preview;
  List<FontEntry> _filtered = kAllFonts;

  void _filter(String q) {
    setState(() => _filtered = q.isEmpty
        ? kAllFonts
        : kAllFonts.where((f) => f.label.toLowerCase().contains(q.toLowerCase())).toList());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return _PopupSheet(
      title: 'Tipo de letra',
      height: 480,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              style: GoogleFonts.dmSans(fontSize: 12.5, color: kInk),
              decoration: InputDecoration(
                hintText: 'Pesquisar…',
                hintStyle: GoogleFonts.dmSans(fontSize: 12.5, color: kMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._buildList(state),
              ],
            ),
          ),
          if (_preview != null) _buildPreview(context, state),
        ],
      ),
    );
  }

  List<Widget> _buildList(EditorState state) {
    final widgets = <Widget>[];
    String? lastGroup;
    for (final f in _filtered) {
      if (_search.text.isEmpty && f.group != lastGroup) {
        if (lastGroup != null) widgets.add(const Divider(color: kBorder, height: 1));
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
          child: Text(f.group.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFCCCCCC), letterSpacing: 0.06 * 10)),
        ));
        lastGroup = f.group;
      }
      widgets.add(_FontItem(
        entry: f,
        active: f.label == state.currentFont,
        onTap: () => setState(() => _preview = f),
      ));
    }
    return widgets;
  }

  Widget _buildPreview(BuildContext context, EditorState state) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kBorder)),
        color: Color(0xFFFAFAFA),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_preview!.label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted, letterSpacing: 0.06 * 10)),
          const SizedBox(height: 4),
          Text('Aa Bb Cc', style: TextStyle(fontFamily: _preview!.label, fontSize: 26, color: kInk, height: 1.2)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.dmSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
              onPressed: () {
                state.setFont(_preview!.label);
                state.controller.formatSelection(Attribute.fromKeyValue('font', _preview!.label));
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontItem extends StatelessWidget {
  final FontEntry entry;
  final bool active;
  final VoidCallback onTap;
  const _FontItem({required this.entry, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          entry.label,
          style: TextStyle(
            fontFamily: entry.label,
            fontSize: 14,
            color: active ? kAccent : kInk,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SIZE POPUP
// ════════════════════════════════════════════════════════════
const _kSizes = [8.0, 10, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72];

class SizePopupSheet extends StatefulWidget {
  const SizePopupSheet({super.key});
  @override
  State<SizePopupSheet> createState() => _SizePopupSheetState();
}

class _SizePopupSheetState extends State<SizePopupSheet> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return _PopupSheet(
      title: 'Tamanho',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                _SteperBtn(icon: Icons.remove_rounded, onTap: () { state.setSize((state.currentSize - 1).clamp(6, 200)); }),
                Expanded(child: Center(child: Text('${state.currentSize.toInt()}', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: kInk)))),
                _SteperBtn(icon: Icons.add_rounded, onTap: () { state.setSize((state.currentSize + 1).clamp(6, 200)); }),
              ],
            ),
          ),
          Container(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 5, runSpacing: 5,
              children: _kSizes.map((s) {
                final sel = s == state.currentSize;
                return GestureDetector(
                  onTap: () { state.setSize(s); Navigator.pop(context); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? kAccentBg : Colors.transparent,
                      border: Border.all(color: sel ? kAccent : kBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${s.toInt()}', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? kAccent : kSub)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SteperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SteperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(border: Border.all(color: kBorder, width: 1.5), borderRadius: BorderRadius.circular(9), color: kSurface),
        child: Icon(icon, size: 18, color: kSub),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// STYLES POPUP
// ════════════════════════════════════════════════════════════
class StylesPopupSheet extends StatelessWidget {
  const StylesPopupSheet({super.key});

  static const _styles = [
    {'label': 'Parágrafo', 'attr': 'normal', 'icon': Icons.notes_rounded},
    {'label': 'Título 1', 'attr': 'h1', 'icon': Icons.looks_one_rounded},
    {'label': 'Título 2', 'attr': 'h2', 'icon': Icons.looks_two_rounded},
    {'label': 'Título 3', 'attr': 'h3', 'icon': Icons.looks_3_rounded},
    {'label': 'Título 4', 'attr': 'h4', 'icon': Icons.looks_4_rounded},
    {'label': 'Citação', 'attr': 'blockquote', 'icon': Icons.format_quote_rounded},
    {'label': 'Código', 'attr': 'code-block', 'icon': Icons.code_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return _PopupSheet(
      title: 'Estilo de parágrafo',
      child: Column(
        children: _styles.map((s) {
          return InkWell(
            onTap: () {
              final state = context.read<EditorState>();
              if (s['attr'] == 'blockquote') {
                state.controller.formatSelection(Attribute.blockQuote);
              } else if (s['attr'] == 'code-block') {
                state.controller.formatSelection(Attribute.codeBlock);
              } else if (s['attr'] != 'normal') {
                state.controller.formatSelection(Attribute.fromKeyValue('header', int.tryParse((s['attr'] as String).replaceAll('h', ''))));
              } else {
                state.controller.formatSelection(Attribute.fromKeyValue('header', null));
              }
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, size: 15, color: kMuted),
                  const SizedBox(width: 10),
                  Text(s['label'] as String, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: kInk)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// INSERT POPUP
// ════════════════════════════════════════════════════════════
class InsertPopupSheet extends StatelessWidget {
  const InsertPopupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _PopupSheet(
      title: 'Inserir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsertItem(icon: Icons.link_rounded, label: 'Link', onTap: () => _insertLink(context)),
          _InsertItem(icon: Icons.image_outlined, label: 'Imagem', onTap: () => _insertImage(context)),
          _InsertItem(icon: Icons.table_chart_outlined, label: 'Tabela 3×3', onTap: () => _insertTable(context)),
          const Divider(color: kBorder, height: 1),
          _InsertItem(icon: Icons.horizontal_rule_rounded, label: 'Linha divisória', onTap: () => _insertHr(context)),
          _InsertItem(icon: Icons.calendar_today_outlined, label: 'Data e hora', onTap: () => _insertDate(context)),
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
            child: Text('CAIXAS DE DESTAQUE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFCCCCCC), letterSpacing: 0.06 * 10)),
          ),
          _InsertItem(icon: Icons.warning_amber_rounded, label: 'Aviso', onTap: () => _insertCallout(context, 'warning')),
          _InsertItem(icon: Icons.info_outline_rounded, label: 'Informação', onTap: () => _insertCallout(context, 'info')),
          _InsertItem(icon: Icons.check_circle_outline_rounded, label: 'Sucesso', onTap: () => _insertCallout(context, 'success')),
          _InsertItem(icon: Icons.cancel_outlined, label: 'Erro', onTap: () => _insertCallout(context, 'error')),
        ],
      ),
    );
  }

  void _insertLink(BuildContext ctx) {
    Navigator.pop(ctx);
    // Show link dialog
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Inserir link'),
      content: TextField(decoration: const InputDecoration(hintText: 'https://…')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }

  void _insertImage(BuildContext ctx) {
    Navigator.pop(ctx);
    // image_picker integration
  }

  void _insertTable(BuildContext ctx) {
    Navigator.pop(ctx);
    ctx.read<EditorState>().controller.document.insert(
      ctx.read<EditorState>().controller.selection.extentOffset,
      '\n',
    );
  }

  void _insertHr(BuildContext ctx) {
    Navigator.pop(ctx);
    final state = ctx.read<EditorState>();
    final idx = state.controller.selection.extentOffset;
    state.controller.document.insert(idx, BlockEmbed.horizontalRule);
  }

  void _insertDate(BuildContext ctx) {
    Navigator.pop(ctx);
    final state = ctx.read<EditorState>();
    final now = DateTime.now();
    final str = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    final idx = state.controller.selection.extentOffset;
    state.controller.document.insert(idx, str);
  }

  void _insertCallout(BuildContext ctx, String type) {
    Navigator.pop(ctx);
    // Insert styled block via quill delta
  }
}

class _InsertItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InsertItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: kMuted),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: kInk)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FORMAT POPUP
// ════════════════════════════════════════════════════════════
class FormatPopupSheet extends StatelessWidget {
  const FormatPopupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _PopupSheet(
      title: 'Formatar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormatSection('MAIÚSCULAS'),
          _FormatItem(icon: Icons.text_fields_rounded, label: 'MAIÚSCULAS', onTap: () => _transform(context, (s) => s.toUpperCase())),
          _FormatItem(icon: Icons.text_fields_rounded, label: 'minúsculas', onTap: () => _transform(context, (s) => s.toLowerCase())),
          _FormatItem(icon: Icons.text_fields_rounded, label: 'Primeira Maiúscula', onTap: () => _transform(context, (s) => s.replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase()))),
          const Divider(color: kBorder, height: 1),
          _FormatSection('INLINE'),
          _FormatItem(icon: Icons.superscript_rounded, label: 'Sobrescrito', onTap: () { context.read<EditorState>().controller.formatSelection(Attribute.superScript); Navigator.pop(context); }),
          _FormatItem(icon: Icons.subscript_rounded, label: 'Subscrito', onTap: () { context.read<EditorState>().controller.formatSelection(Attribute.subScript); Navigator.pop(context); }),
          _FormatItem(icon: Icons.code_rounded, label: 'Código inline', onTap: () { context.read<EditorState>().controller.formatSelection(Attribute.inlineCode); Navigator.pop(context); }),
          const Divider(color: kBorder, height: 1),
          _FormatSection('ESPAÇAMENTO'),
          _FormatItem(icon: Icons.density_large_rounded, label: '1.0 — Compacto', onTap: () => Navigator.pop(context)),
          _FormatItem(icon: Icons.density_medium_rounded, label: '1.5 — Normal', onTap: () => Navigator.pop(context)),
          _FormatItem(icon: Icons.density_small_rounded, label: '2.0 — Espaçado', onTap: () => Navigator.pop(context)),
          const Divider(color: kBorder, height: 1),
          _FormatItem(
            icon: Icons.delete_outline_rounded, label: 'Limpar formatação',
            danger: true,
            onTap: () { context.read<EditorState>().controller.formatSelection(Attribute.clone(Attribute.bold, null)); Navigator.pop(context); },
          ),
        ],
      ),
    );
  }

  void _transform(BuildContext ctx, String Function(String) fn) {
    Navigator.pop(ctx);
    final state = ctx.read<EditorState>();
    final sel = state.controller.selection;
    if (sel.isCollapsed) return;
    final text = state.controller.document.toPlainText().substring(sel.start, sel.end);
    state.controller.replaceText(sel.start, sel.end - sel.start, fn(text), null);
  }
}

class _FormatSection extends StatelessWidget {
  final String label;
  const _FormatSection(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFCCCCCC), letterSpacing: 0.06 * 10)),
    );
  }
}

class _FormatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _FormatItem({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: danger ? Colors.red.shade500 : kMuted),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: danger ? Colors.red.shade600 : kInk)),
          ],
        ),
      ),
    );
  }
}