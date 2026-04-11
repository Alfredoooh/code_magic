import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill_lib;
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

// ── Métricas de paginação ─────────────────────────────────
const double _kUsableW = kPageWidth  - kPagePadH * 2;
const double _kUsableH = kPageHeight - kPagePadV * 2;

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

// ── Menu de selecção ──────────────────────────────────────
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

// ── Decoração do papel ────────────────────────────────────
BoxDecoration _paperDecoration({bool focused = false}) => BoxDecoration(
      color: kWhite,
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

// ── CanvasArea ────────────────────────────────────────────
class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key});
  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  bool _focused = false;

  void _onBgTap() {
    context.read<AppEditorState>().focusNode.unfocus();
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();

    return GestureDetector(
      onTap: _onBgTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: const Color(0xFFF0F0EE),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
              child: st.a4Mode
                  ? _A4Pages(
                      onFocusChange: (f) => setState(() => _focused = f))
                  : _ScrollPage(
                      onFocusChange: (f) => setState(() => _focused = f)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scroll Mode ───────────────────────────────────────────
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
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: kPageWidth,
        constraints: const BoxConstraints(minHeight: kPageHeight),
        decoration: _paperDecoration(focused: _focused),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadH, kPagePadV, kPagePadH, 120),
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

// ── A4 Mode ───────────────────────────────────────────────
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
      charOffset += line.length + 1;
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
    final st = context.watch<AppEditorState>();
    final isFirst = widget.pageIndex == 0;
    final ctrl = _buildPageCtrl(st);

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: kPageWidth,
        height: kPageHeight,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: _paperDecoration(focused: _focused && isFirst),
        child: Stack(children: [
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
                      configurations: _editorConfig(widget.fontSize, ctrl: ctrl),
                    ),
                  )
                : quill_lib.QuillEditor.basic(
                    controller: ctrl,
                    focusNode: FocusNode(canRequestFocus: false),
                    scrollController: ScrollController(),
                    configurations: _editorConfig(widget.fontSize),
                  ),
          ),
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
        ]),
      ),
    );
  }
}