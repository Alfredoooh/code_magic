import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill_lib;
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

// ── Largura útil da página (sem margens) ─────────────────
const double _kUsableWidth = kPageWidth - kPagePadH * 2;
// Altura útil por página A4 (sem margens verticais)
const double _kUsableHeight = kPageHeight - kPagePadV * 2;

/// Caracteres por linha para um dado tamanho de fonte (Lora, lineHeight 1.85).
/// Usa largura média empírica por família: serif ~0.52×fontSize.
int _charsPerLine(double fontSize) =>
    (_kUsableWidth / (fontSize * 0.52)).floor().clamp(1, 9999);

/// Linhas por página A4 para um dado tamanho de fonte.
int _linesPerPage(double fontSize) {
  final lineH = fontSize * 1.85;
  return (_kUsableHeight / lineH).floor().clamp(1, 9999);
}

/// Estima o número de páginas A4 necessárias com base no conteúdo do documento.
int _estimatePageCount(quill_lib.QuillController ctrl, double fontSize) {
  final text = ctrl.document.toPlainText();
  if (text.trim().isEmpty) return 1;

  final cpl = _charsPerLine(fontSize);
  final lpp = _linesPerPage(fontSize);

  final rawLines = text.split('\n');
  int totalLines = 0;
  for (final line in rawLines) {
    final wrapped = (line.length / cpl).ceil();
    totalLines += wrapped < 1 ? 1 : wrapped;
  }

  final pages = (totalLines / lpp).ceil();
  return pages < 1 ? 1 : pages;
}

// ── Configuração partilhada do QuillEditor ────────────────
quill_lib.QuillEditorConfigurations _editorConfig(double fontSize) =>
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
            fontSize: fontSize,
            height: 1.85,
            color: kInk,
          ),
          const quill_lib.HorizontalSpacing(0, 0),
          const quill_lib.VerticalSpacing(0, 0),
          const quill_lib.VerticalSpacing(0, 0),
          null,
        ),
      ),
    );

// ─────────────────────────────────────────────────────────
class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key});

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  double _scale = 1.0;
  bool _focused = false;

  void _computeScale(BoxConstraints constraints) {
    final avail = constraints.maxWidth - 32;
    final base = avail < kPageWidth ? avail / kPageWidth : 1.0;
    final s = _focused ? (base * 1.15).clamp(0.0, 1.0) : base;
    if ((s - _scale).abs() > 0.001) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _scale = s);
      });
    }
  }

  /// Desactiva o foco ao tocar fora da página.
  void _handleBackgroundTap() {
    final ed = context.read<AppEditorState>();
    ed.focusNode.unfocus();
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        _computeScale(constraints);

        return GestureDetector(
          // Toque fora da página desactiva edição
          onTap: _handleBackgroundTap,
          behavior: HitTestBehavior.translucent,
          child: Container(
            // Fundo neutro acinzentado — contrasta suavemente com o papel branco
            color: const Color(0xFFE4E4E4),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                // Garante largura mínima = área disponível → Center funciona
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
                  child: Center(
                    child: AnimatedScale(
                      scale: _scale,
                      duration: const Duration(milliseconds: 300),
                      curve: kCurve,
                      alignment: Alignment.topCenter,
                      child: st.a4Mode
                          ? _A4Pages(
                              onFocusChange: (f) =>
                                  setState(() => _focused = f),
                            )
                          : _ScrollPage(
                              onFocusChange: (f) =>
                                  setState(() => _focused = f),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Borda sólida partilhada ───────────────────────────────
BoxDecoration _pageDecoration({bool focused = false}) => BoxDecoration(
      color: kWhite,
      // Cantos totalmente retos — sem borderRadius
      border: Border.all(
        color: Colors.black.withOpacity(focused ? 0.22 : 0.16),
        width: 1.2,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
    );

// ── Menu de selecção (Cortar / Copiar / Colar / Negrito / Itálico) ───
class _SelectionToolbar extends StatelessWidget {
  final quill_lib.QuillController controller;
  final FocusNode focusNode;

  const _SelectionToolbar({
    required this.controller,
    required this.focusNode,
  });

  void _cmd(void Function() fn) {
    fn();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(10),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelBtn(
              label: 'Negrito',
              onTap: () => _cmd(
                () => controller.formatSelection(
                  quill_lib.Attribute.bold,
                ),
              ),
            ),
            _SelBtn(
              label: 'Itálico',
              onTap: () => _cmd(
                () => controller.formatSelection(
                  quill_lib.Attribute.italic,
                ),
              ),
            ),
            _SelBtn(
              label: 'Sublinhado',
              onTap: () => _cmd(
                () => controller.formatSelection(
                  quill_lib.Attribute.underline,
                ),
              ),
            ),
            _SelBtn(
              label: 'Apagar',
              onTap: () => _cmd(() {
                final sel = controller.selection;
                if (!sel.isCollapsed) {
                  controller.replaceText(
                    sel.start,
                    sel.end - sel.start,
                    '',
                    null,
                  );
                }
              }),
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _SelBtn({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: danger ? const Color(0xFFFF453A) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── SCROLL MODE ───────────────────────────────────────────
class _ScrollPage extends StatefulWidget {
  final ValueChanged<bool> onFocusChange;
  const _ScrollPage({required this.onFocusChange});

  @override
  State<_ScrollPage> createState() => _ScrollPageState();
}

class _ScrollPageState extends State<_ScrollPage> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    // Tamanho de fonte actual (pode vir do estado; fallback 16)
    final fontSize = st.fontSize ?? 16.0;

    return GestureDetector(
      // Absorve o toque dentro da página para não propagar ao fundo
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: kPageWidth,
        constraints: const BoxConstraints(minHeight: kPageHeight),
        decoration: _pageDecoration(focused: _focused),
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
              configurations: _editorConfig(fontSize),
            ),
          ),
        ),
      ),
    );
  }
}

// ── A4 MODE ───────────────────────────────────────────────
class _A4Pages extends StatelessWidget {
  final ValueChanged<bool> onFocusChange;
  const _A4Pages({required this.onFocusChange});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    final fontSize = st.fontSize ?? 16.0;
    final count = _estimatePageCount(st.quill, fontSize);

    return Column(
      children: List.generate(count, (i) {
        return _A4Page(
          pageNumber: i + 1,
          pageIndex: i,
          totalPages: count,
          fontSize: fontSize,
          onFocusChange: onFocusChange,
        );
      }),
    );
  }
}

class _A4Page extends StatefulWidget {
  final int pageNumber;
  final int pageIndex;
  final int totalPages;
  final double fontSize;
  final ValueChanged<bool> onFocusChange;

  const _A4Page({
    required this.pageNumber,
    required this.pageIndex,
    required this.totalPages,
    required this.fontSize,
    required this.onFocusChange,
  });

  @override
  State<_A4Page> createState() => _A4PageState();
}

class _A4PageState extends State<_A4Page> {
  bool _focused = false;

  /// Cria um controller que só expõe o trecho desta página.
  /// O primeiro page usa o controller original; as páginas seguintes
  /// mostram um snapshot read-only do trecho correspondente.
  quill_lib.QuillController _pageController(AppEditorState st) {
    if (widget.pageIndex == 0) return st.quill;

    final lpp = _linesPerPage(widget.fontSize);
    final cpl = _charsPerLine(widget.fontSize);
    final text = st.quill.document.toPlainText();
    final rawLines = text.split('\n');

    // Calcula offset de carácter de início desta página
    int charOffset = 0;
    int linesAccum = 0;
    final targetStartLine = widget.pageIndex * lpp;

    for (final line in rawLines) {
      final wrapped = math.max(1, (line.length / cpl).ceil());
      if (linesAccum + wrapped > targetStartLine) break;
      linesAccum += wrapped;
      charOffset += line.length + 1; // +1 para '\n'
    }

    final endOffset = math.min(
      charOffset + lpp * cpl,
      math.max(0, text.length - 1),
    );

    final snippet = charOffset < text.length
        ? text.substring(charOffset, endOffset.clamp(charOffset, text.length))
        : '';

    final doc = quill_lib.Document()..insert(0, snippet.isEmpty ? ' ' : snippet);
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
    final ctrl = _pageController(st);

    return GestureDetector(
      onTap: () {}, // absorve toque — não propaga ao fundo
      child: Container(
        width: kPageWidth,
        height: kPageHeight,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: _pageDecoration(focused: _focused && isFirst),
        child: Stack(
          children: [
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
                        configurations: _editorConfig(widget.fontSize),
                      ),
                    )
                  : quill_lib.QuillEditor.basic(
                      controller: ctrl,
                      focusNode: FocusNode(canRequestFocus: false),
                      scrollController: ScrollController(),
                      configurations: _editorConfig(widget.fontSize),
                    ),
            ),
            // Gradiente de fim de página
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
            // Número de página
            Positioned(
              bottom: 14,
              right: 20,
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