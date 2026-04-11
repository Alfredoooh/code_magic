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
          color: const Color(0xFFF2F1EC),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 200),
                  child: Align(
                    alignment: Alignment.topCenter,
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
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: const Color(0xFFCBC7BE),
          width: 1.35,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_focused ? 0.10 : 0.07),
            blurRadius: _focused ? 18 : 14,
            offset: const Offset(0, 6),
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
class _A4Pages extends StatelessWidget {
  final ValueChanged<bool> onFocusChange;
  const _A4Pages({required this.onFocusChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: const Color(0xFFCBC7BE),
          width: 1.35,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_focused ? 0.10 : 0.07),
            blurRadius: _focused ? 18 : 14,
            offset: const Offset(0, 6),
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