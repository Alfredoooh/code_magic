import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill_lib;
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

// ─────────────────────────────────────────────────────────
// Constantes exactas do HTML
//   width:794px  height:1123px  padding:96px 88px
// Mapeados para kPageWidth / kPageHeight / kPagePadH / kPagePadV
// ─────────────────────────────────────────────────────────

// ── Métricas de paginação (lógica do splitA4 do HTML) ────
const double _kUsableW = kPageWidth  - kPagePadH * 2; // 794 - 176 = 618
const double _kUsableH = kPageHeight - kPagePadV * 2; // 1123 - 192 = 931

int _charsPerLine(double fs) =>
    (_kUsableW / (fs * 0.52)).floor().clamp(1, 9999);

int _linesPerPage(double fs) =>
    (_kUsableH / (fs * 1.85)).floor().clamp(1, 9999);

int _estimatePageCount(quill_lib.QuillController ctrl, double fs) {
  final text = ctrl.document.toPlainText();
  if (text.trim().isEmpty) return 1;
  final cpl = _charsPerLine(fs);
  final lpp = _linesPerPage(fs);
  int total = 0;
  for (final line in text.split('\n')) {
    total += math.max(1, (line.length / cpl).ceil());
  }
  return math.max(1, (total / lpp).ceil());
}

// ── Config do QuillEditor ─────────────────────────────────
quill_lib.QuillEditorConfigurations _editorConfig(
  double fs, {
  quill_lib.QuillController? ctrl,
}) =>
    quill_lib.QuillEditorConfigurations(
      scrollable: false,
      autoFocus: false,
      expands: false,
      padding: EdgeInsets.zero,
      placeholder: 'Começa a escrever…',
      customStyles: quill_lib.DefaultStyles(
        paragraph: quill_lib.DefaultTextBlockStyle(
          TextStyle(
            fontFamily: 'Lora',
            fontSize: fs,
            height: 1.85,
            color: kInk,
          ),
          const quill_lib.HorizontalSpacing(0, 0),
          const quill_lib.VerticalSpacing(0, 0),
          const quill_lib.VerticalSpacing(0, 0),
          null,
        ),
      ),
      contextMenuBuilder: ctrl == null
          ? null
          : (ctx, rawEditor) =>
              _SelectionMenu(controller: ctrl, rawEditor: rawEditor),
    );

// ── Menu de selecção (igual ao selMenu do HTML) ───────────
class _SelectionMenu extends StatelessWidget {
  final quill_lib.QuillController controller;
  final dynamic rawEditor;
  const _SelectionMenu({required this.controller, required this.rawEditor});

  @override
  Widget build(BuildContext context) {
    if (controller.selection.isCollapsed) return const SizedBox.shrink();
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: rawEditor.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(label: 'Negrito',
            onPressed: () => controller.formatSelection(quill_lib.Attribute.bold)),
        ContextMenuButtonItem(label: 'Itálico',
            onPressed: () => controller.formatSelection(quill_lib.Attribute.italic)),
        ContextMenuButtonItem(label: 'Sublinhado',
            onPressed: () => controller.formatSelection(quill_lib.Attribute.underline)),
        ContextMenuButtonItem(label: 'Riscado',
            onPressed: () => controller.formatSelection(quill_lib.Attribute.strikeThrough)),
        ContextMenuButtonItem(label: 'Apagar', onPressed: () {
          final s = controller.selection;
          if (!s.isCollapsed) {
            controller.replaceText(s.start, s.end - s.start, '', null);
          }
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// DECORAÇÃO DO PAPEL
// HTML scroll-mode:
//   border-radius:4px
//   box-shadow: 0 1px 3px rgba(0,0,0,.06), 0 4px 20px rgba(0,0,0,.06)
//   focused: 0 2px 8px rgba(0,0,0,.08), 0 8px 36px rgba(0,0,0,.12)
// HTML a4-mode:
//   border-radius:4px  (sem border explícita — sombra define o contorno)
//   mesmas sombras do scroll-mode
//
// PEDIDO DO UTILIZADOR: bordas retas + borda sólida ligeiramente visível
//   → borderRadius: zero  + Border.all
// ─────────────────────────────────────────────────────────
BoxDecoration _paperDecoration({bool focused = false, bool a4 = false}) =>
    BoxDecoration(
      color: kWhite,
      // Bordas retas (sem borderRadius) + linha sólida subtil
      border: Border.all(
        color: Colors.black.withOpacity(focused ? 0.20 : 0.13),
        width: 1.2,
      ),
      boxShadow: focused
          ? [
              BoxShadow(color: Colors.black.withOpacity(0.08),
                  blurRadius: 8, offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withOpacity(0.12),
                  blurRadius: 36, offset: const Offset(0, 8)),
            ]
          : [
              BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 3, offset: const Offset(0, 1)),
              BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 20, offset: const Offset(0, 4)),
            ],
    );

// ─────────────────────────────────────────────────────────
// CANVAS AREA
// HTML: #canvasScroll  →  flex-col items-center  bg-[#f8f8f7]
//       px-4 pt-7 pb-[200px]
// A centralização vem do  display:flex + align-items:center  do canvasScroll,
// não do page-wrapper. Replicamos com Center() dentro do scroll.
// ─────────────────────────────────────────────────────────
class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key});
  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  double _scale = 1.0;
  bool   _focused = false;

  // HTML: applyZoom — scale = avail < 794 ? avail/794 : 1
  //       focused   → scale *= 1.15  clamped to 1
  void _computeScale(double availW) {
    final base = availW < kPageWidth ? availW / kPageWidth : 1.0;
    final s = (_focused ? base * 1.15 : base).clamp(0.0, 1.0);
    if ((s - _scale).abs() > 0.001) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _scale = s);
      });
    }
  }

  void _onBgTap() {
    // HTML: click fora do .page-content → remove focus
    context.read<AppEditorState>().focusNode.unfocus();
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();

    return LayoutBuilder(builder: (ctx, constraints) {
      // HTML usa padding px-4 (16px) em cada lado
      _computeScale(constraints.maxWidth - 32);

      return GestureDetector(
        onTap: _onBgTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          // HTML: bg-[#f8f8f7]  (fundo do canvasScroll)
          color: const Color(0xFFF0F0EE),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            // HTML: px-4 pt-7 pb-[200px]
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
            // Replica: transform:scale(s); transform-origin:top center;
            // margin-bottom: (s-1)*pageHeight  (compensa o espaço perdido)
            child: Center(
              child: SizedBox(
                width: kPageWidth * _scale,
                child: Transform.scale(
                  scale: _scale,
                  alignment: Alignment.topCenter,
                  child: st.a4Mode
                      ? _A4Pages(
                          onFocusChange: (f) => setState(() => _focused = f))
                      : _ScrollPage(
                          onFocusChange: (f) => setState(() => _focused = f)),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────
// SCROLL MODE
// HTML .page:  width:794px  min-height:1123px
//              padding: 96px 88px 120px  (bottom maior para espaço de escrita)
//              border-radius:4px  → aqui: zero
// ─────────────────────────────────────────────────────────
class _ScrollPage extends StatefulWidget {
  final ValueChanged<bool> onFocusChange;
  const _ScrollPage({required this.onFocusChange});
  @override State<_ScrollPage> createState() => _ScrollPageState();
}

class _ScrollPageState extends State<_ScrollPage> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    final fs = (st.fontSize ?? 16).toDouble();

    return GestureDetector(
      onTap: () {}, // absorve — não dispara _onBgTap
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: kPageWidth,
        constraints: const BoxConstraints(minHeight: kPageHeight),
        decoration: _paperDecoration(focused: _focused),
        // padding: top 96, sides 88, bottom 120  (igual ao HTML)
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              kPagePadH, kPagePadV, kPagePadH, 120),
          child: Focus(
            onFocusChange: (f) {
              setState(() => _focused = f);
              widget.onFocusChange(f);
            },
            child: quill_lib.QuillEditor.basic(
              controller: st.quill,
              focusNode: st.focusNode,
              scrollController: st.scrollController,
              configurations: _editorConfig(fs, ctrl: st.quill),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// A4 MODE
// HTML .a4-page:  width:794px  height:1123px
//                 padding: 96px 88px  (top e bottom iguais)
//                 ::after gradient na base
//                 número de página bottom-right
//
// Paginação: replica splitA4 do HTML —
//   página 1 = editor real (editável)
//   páginas 2..N = snapshot read-only do trecho correspondente
// ─────────────────────────────────────────────────────────
class _A4Pages extends StatelessWidget {
  final ValueChanged<bool> onFocusChange;
  const _A4Pages({required this.onFocusChange});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    final fs = (st.fontSize ?? 16).toDouble();
    final count = _estimatePageCount(st.quill, fs);

    return Column(
      children: List.generate(
        count,
        (i) => _A4Page(
          pageNumber: i + 1,
          pageIndex: i,
          fontSize: fs,
          onFocusChange: onFocusChange,
        ),
      ),
    );
  }
}

class _A4Page extends StatefulWidget {
  final int pageNumber;
  final int pageIndex;
  final double fontSize;
  final ValueChanged<bool> onFocusChange;

  const _A4Page({
    required this.pageNumber,
    required this.pageIndex,
    required this.fontSize,
    required this.onFocusChange,
  });

  @override
  State<_A4Page> createState() => _A4PageState();
}

class _A4PageState extends State<_A4Page> {
  bool _focused = false;

  // Replica a lógica de offset do splitA4 do HTML
  quill_lib.QuillController _buildPageCtrl(AppEditorState st) {
    if (widget.pageIndex == 0) return st.quill;

    final lpp = _linesPerPage(widget.fontSize);
    final cpl = _charsPerLine(widget.fontSize);
    final text = st.quill.document.toPlainText();
    final lines = text.split('\n');

    int charOffset = 0, linesAccum = 0;
    final targetStart = widget.pageIndex * lpp;

    for (final line in lines) {
      final wrapped = math.max(1, (line.length / cpl).ceil());
      if (linesAccum + wrapped > targetStart) break;
      linesAccum += wrapped;
      charOffset += line.length + 1; // +1 para '\n'
    }

    final end = math.min(
      charOffset + lpp * cpl,
      math.max(0, text.length - 1),
    );
    final snippet = charOffset < text.length
        ? text.substring(charOffset, end.clamp(charOffset, text.length))
        : '';

    final doc = quill_lib.Document()
      ..insert(0, snippet.isEmpty ? ' ' : snippet);
    return quill_lib.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final st  = context.watch<AppEditorState>();
    final ctrl = _buildPageCtrl(st);
    final isFirst = widget.pageIndex == 0;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: kPageWidth,
        height: kPageHeight,
        // HTML: gap:24px entre páginas
        margin: const EdgeInsets.only(bottom: 24),
        decoration: _paperDecoration(focused: _focused && isFirst, a4: true),
        child: Stack(
          children: [
            // Conteúdo
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  kPagePadH, kPagePadV, kPagePadH, kPagePadV),
              child: isFirst
                  ? Focus(
                      onFocusChange: (f) {
                        setState(() => _focused = f);
                        widget.onFocusChange(f);
                      },
                      child: quill_lib.QuillEditor.basic(
                        controller: ctrl,
                        focusNode: st.focusNode,
                        scrollController: st.scrollController,
                        configurations:
                            _editorConfig(widget.fontSize, ctrl: ctrl),
                      ),
                    )
                  : quill_lib.QuillEditor.basic(
                      controller: ctrl,
                      focusNode: FocusNode(canRequestFocus: false),
                      scrollController: ScrollController(),
                      configurations: _editorConfig(widget.fontSize),
                    ),
            ),

            // HTML .a4-page::after — gradiente na base
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.06),
                    ],
                  ),
                ),
              ),
            ),

            // HTML .a4-page-num — número de página
            Positioned(
              bottom: 14, right: 20,
              child: Text(
                '${widget.pageNumber}',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}