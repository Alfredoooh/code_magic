import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill_lib;
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _computeScale(constraints);
        return Container(
          // Fundo acinzentado suave — evita o contraste branco-sobre-branco
          color: const Color(0xFFE8E8E8),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                // Garante largura mínima igual à área disponível para centralizar
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                ),
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
                              onFocusChange: (f) => setState(() => _focused = f),
                            )
                          : _ScrollPage(
                              onFocusChange: (f) => setState(() => _focused = f),
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

// ── Configuração partilhada do QuillEditor ────────────────
quill_lib.QuillEditorConfigurations _editorConfig() =>
    const quill_lib.QuillEditorConfigurations(
      scrollable: false,
      autoFocus: false,
      expands: false,
      padding: EdgeInsets.zero,
      placeholder: 'Começa a escrever…',
      customStyles: quill_lib.DefaultStyles(
        paragraph: quill_lib.DefaultTextBlockStyle(
          TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
            height: 1.85,
            color: kInk,
          ),
          quill_lib.HorizontalSpacing(0, 0),
          quill_lib.VerticalSpacing(0, 0),
          quill_lib.VerticalSpacing(0, 0),
          null,
        ),
      ),
    );

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: kPageWidth,
      constraints: const BoxConstraints(minHeight: kPageHeight),
      decoration: BoxDecoration(
        color: kWhite,
        // Bordas retas — borderRadius removido
        border: Border.all(color: Colors.black.withOpacity(0.18), width: 1.2),
        boxShadow: _focused
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
      ),
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
            configurations: _editorConfig(),
          ),
        ),
      ),
    );
  }
}

// ── A4 MODE ───────────────────────────────────────────────

/// Calcula quantas páginas são necessárias com base no conteúdo do documento.
/// Cada página comporta [kPageContentHeight] de altura de texto.
/// O mínimo é sempre 1 página.
int _pageCount(quill_lib.QuillController ctrl) {
  // Estimativa: linhas totais × altura de linha / área útil por página
  final doc = ctrl.document;
  final text = doc.toPlainText();
  if (text.trim().isEmpty) return 1;

  // Largura útil em pixels lógicos
  const usableWidth = kPageWidth - kPagePadH * 2;
  // Altura útil por página (altura A4 menos margens verticais)
  const usableHeight = kPageHeight - kPagePadV * 2;

  // Caracteres por linha aproximados (fonte Lora 16px, largura média ~8.5px/char)
  const charsPerLine = usableWidth ~/ 8.5;
  // Altura por linha (fontSize × lineHeight)
  const lineH = 16.0 * 1.85;
  // Linhas por página
  const linesPerPage = usableHeight ~/ lineH;

  final lines = text.split('\n');
  int totalLines = 0;
  for (final l in lines) {
    final wrapped = (l.length / charsPerLine).ceil();
    totalLines += wrapped < 1 ? 1 : wrapped;
  }

  final pages = (totalLines / linesPerPage).ceil();
  return pages < 1 ? 1 : pages;
}

class _A4Pages extends StatelessWidget {
  final ValueChanged<bool> onFocusChange;
  const _A4Pages({required this.onFocusChange});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    final count = _pageCount(st.quill);

    return Column(
      children: List.generate(count, (i) {
        return _A4Page(
          pageNumber: i + 1,
          totalPages: count,
          isEditable: i == 0, // apenas a primeira página tem o editor
          onFocusChange: onFocusChange,
        );
      }),
    );
  }
}

class _A4Page extends StatefulWidget {
  final int pageNumber;
  final int totalPages;
  final bool isEditable;
  final ValueChanged<bool> onFocusChange;

  const _A4Page({
    required this.pageNumber,
    required this.totalPages,
    required this.isEditable,
    required this.onFocusChange,
  });

  @override
  State<_A4Page> createState() => _A4PageState();
}

class _A4PageState extends State<_A4Page> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    return Container(
      width: kPageWidth,
      height: kPageHeight,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: kWhite,
        // Bordas retas — borderRadius removido; borda sólida mais visível
        border: Border.all(color: Colors.black.withOpacity(0.20), width: 1.2),
        boxShadow: [
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
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kPagePadH,
              kPagePadV,
              kPagePadH,
              kPagePadV,
            ),
            child: widget.isEditable
                ? Focus(
                    onFocusChange: (f) {
                      setState(() => _focused = f);
                      widget.onFocusChange(f);
                    },
                    child: quill_lib.QuillEditor.basic(
                      controller: st.quill,
                      focusNode: st.focusNode,
                      scrollController: st.scrollController,
                      configurations: _editorConfig(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Gradiente de separação na base da página
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
    );
  }
}