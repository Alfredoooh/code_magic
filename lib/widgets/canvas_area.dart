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
    return LayoutBuilder(builder: (ctx, constraints) {
      _computeScale(constraints);
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
                        onFocusChange: (f) => setState(() => _focused = f))
                    : _ScrollPage(
                        onFocusChange: (f) => setState(() => _focused = f)),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── Configuração partilhada do QuillEditor ────────────────
// Na v10.8.5 o parâmetro é `config: QuillEditorConfig(...)`.
quill_lib.QuillEditorConfig _editorConfig() => quill_lib.QuillEditorConfig(
      scrollable: false,
      autoFocus: false,
      expands: false,
      padding: EdgeInsets.zero,
      placeholder: 'Começa a escrever…',
      customStyles: quill_lib.DefaultStyles(
        paragraph: quill_lib.DefaultTextBlockStyle(
          const TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
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
        borderRadius: BorderRadius.circular(4),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 36,
                    offset: const Offset(0, 8)),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kPagePadH, kPagePadV, kPagePadH, 120),
        child: Focus(
          onFocusChange: (f) {
            setState(() => _focused = f);
            widget.onFocusChange(f);
          },
          child: quill_lib.QuillEditor(
            controller: st.quill,
            focusNode: st.focusNode,
            scrollController: st.scrollController,
            config: _editorConfig(),
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
    return Column(
      children: [
        _A4Page(
          pageNumber: 1,
          isEditable: true,
          onFocusChange: onFocusChange,
        ),
      ],
    );
  }
}

class _A4Page extends StatefulWidget {
  final int pageNumber;
  final bool isEditable;
  final ValueChanged<bool> onFocusChange;
  const _A4Page({
    required this.pageNumber,
    required this.isEditable,
    required this.onFocusChange,
  });
  @override
  State<_A4Page> createState() => _A4PageState();
}

class _A4PageState extends State<_A4Page> {
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    return Container(
      width: kPageWidth,
      height: kPageHeight,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 3,
              offset: const Offset(0, 1)),
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                kPagePadH, kPagePadV, kPagePadH, kPagePadV),
            child: widget.isEditable
                ? quill_lib.QuillEditor(
                    controller: st.quill,
                    focusNode: st.focusNode,
                    scrollController: st.scrollController,
                    config: _editorConfig(),
                  )
                : const SizedBox.shrink(),
          ),
          // Bottom gradient
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
          // Page number
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
    );
  }
}