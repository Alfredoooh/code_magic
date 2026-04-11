import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants.dart';
import '../editor_state.dart';
import 'popups/all_popups.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({super.key});

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  final _aiController = TextEditingController();

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  void _showPopup(BuildContext ctx, GlobalKey key, Widget popup, double width) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final screenW = MediaQuery.of(ctx).size.width;
    final screenH = MediaQuery.of(ctx).size.height;

    double left = offset.dx + box.size.width / 2 - width / 2;
    left = left.clamp(8.0, screenW - width - 8);
    final bottom = screenH - offset.dy + 12;
    final arrowLeft =
        (offset.dx + box.size.width / 2 - left - 7).clamp(12.0, width - 24.0);
    final origX =
        (offset.dx + box.size.width / 2 - left).clamp(20.0, width - 20.0);

    showDialog(
      context: ctx,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => Stack(
        children: [
          Positioned(
            left: left,
            bottom: bottom,
            width: width,
            child: _PopupCard(
              arrowLeft: arrowLeft,
              originX: origX,
              child: popup,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    final screenW = MediaQuery.of(context).size.width;
    final pillW = (screenW * 0.96).clamp(0.0, 460.0);
    final safeBot = MediaQuery.of(context).padding.bottom;
    final bottomPad = safeBot > 0 ? safeBot : 14.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Center(
        child: SizedBox(
          width: pillW,
          child: _Pill(
            aiMode: st.aiMode,
            aiController: _aiController,
            aiLoading: st.aiLoading,
            onShowPopup: (key, popup, width) =>
                _showPopup(context, key, popup, width),
          ),
        ),
      ),
    );
  }
}

// ── PILL ──────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final bool aiMode;
  final bool aiLoading;
  final TextEditingController aiController;
  final Function(GlobalKey, Widget, double) onShowPopup;

  const _Pill({
    required this.aiMode,
    required this.aiLoading,
    required this.aiController,
    required this.onShowPopup,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (!aiMode)
                Expanded(child: _ToolbarTrack(onShowPopup: onShowPopup))
              else
                Expanded(
                  child: _AITrack(
                    controller: aiController,
                    loading: aiLoading,
                  ),
                ),
              _ConfirmBtn(
                aiMode: aiMode,
                aiLoading: aiLoading,
                aiController: aiController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── TOOLBAR TRACK ─────────────────────────────────────────
class _ToolbarTrack extends StatelessWidget {
  final Function(GlobalKey, Widget, double) onShowPopup;
  const _ToolbarTrack({required this.onShowPopup});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();

    final colorKey = GlobalKey();
    final fontKey = GlobalKey();
    final sizeKey = GlobalKey();
    final stylesKey = GlobalKey();
    final insertKey = GlobalKey();
    final formatKey = GlobalKey();

    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              _ColorBtn(
                key: colorKey,
                color: st.textColor,
                onTap: () => onShowPopup(
                  colorKey,
                  PopupColor(
                    onColor: (c) {
                      context.read<AppEditorState>().applyColor(c);
                      Navigator.pop(context);
                    },
                  ),
                  254,
                ),
              ),
              _Sep(),
              _FmtBtn(
                label: 'B',
                weight: FontWeight.w900,
                active: st.bold,
                onTap: () => context.read<AppEditorState>().applyBold(),
              ),
              _FmtBtn(
                label: 'I',
                weight: FontWeight.w600,
                italic: true,
                active: st.italic,
                onTap: () => context.read<AppEditorState>().applyItalic(),
              ),
              _FmtBtn(
                label: 'U',
                weight: FontWeight.w600,
                underline: true,
                active: st.underline,
                onTap: () => context.read<AppEditorState>().applyUnderline(),
              ),
              _FmtBtn(
                label: 'S',
                weight: FontWeight.w600,
                strike: true,
                active: st.strike,
                onTap: () => context.read<AppEditorState>().applyStrike(),
              ),
              _Sep(),
              _Chip(
                key: fontKey,
                label: st.fontLabel,
                onTap: () => onShowPopup(
                  fontKey,
                  PopupFont(
                    onFont: (f) {
                      context.read<AppEditorState>().applyFont(f);
                      Navigator.pop(context);
                    },
                    onExpand: () {
                      Navigator.pop(context);
                    },
                  ),
                  240,
                ),
              ),
              const SizedBox(width: 3),
              _Chip(
                key: sizeKey,
                label: '${st.fontSize}',
                onTap: () => onShowPopup(
                  sizeKey,
                  PopupSize(
                    current: st.fontSize,
                    onSize: (s) {
                      context.read<AppEditorState>().applyFontSize(s);
                      Navigator.pop(context);
                    },
                  ),
                  220,
                ),
              ),
              _Sep(),
              _Chip(
                key: stylesKey,
                label: 'Estilos',
                onTap: () => onShowPopup(
                  stylesKey,
                  PopupStyles(
                    onStyle: (b) {
                      context.read<AppEditorState>().applyBlockStyle(b);
                      Navigator.pop(context);
                    },
                  ),
                  200,
                ),
              ),
              _Sep(),
              _AlignBtn(
                icon: LucideIcons.alignLeft,
                align: 'left',
                current: st.align,
              ),
              _AlignBtn(
                icon: LucideIcons.alignCenter,
                align: 'center',
                current: st.align,
              ),
              _AlignBtn(
                icon: LucideIcons.alignRight,
                align: 'right',
                current: st.align,
              ),
              _AlignBtn(
                icon: LucideIcons.alignJustify,
                align: 'justify',
                current: st.align,
              ),
              _Sep(),
              _TbBtn(
                icon: LucideIcons.list,
                onTap: () => context.read<AppEditorState>().insertUnorderedList(),
              ),
              _TbBtn(
                icon: LucideIcons.listOrdered,
                onTap: () => context.read<AppEditorState>().insertOrderedList(),
              ),
              _TbBtn(
                icon: LucideIcons.indentIncrease,
                onTap: () => context.read<AppEditorState>().indent(),
              ),
              _TbBtn(
                icon: LucideIcons.indentDecrease,
                onTap: () => context.read<AppEditorState>().outdent(),
              ),
              _Sep(),
              _Chip(
                key: insertKey,
                label: 'Inserir',
                useplus: true,
                onTap: () => onShowPopup(
                  insertKey,
                  PopupInsert(
                    onAction: (a) => _handleInsert(context, a),
                  ),
                  240,
                ),
              ),
              _Sep(),
              _Chip(
                key: formatKey,
                label: 'Formatar',
                usesettings: true,
                onTap: () => onShowPopup(
                  formatKey,
                  PopupFormat(
                    onAction: (a) => _handleFormat(context, a),
                  ),
                  240,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleInsert(BuildContext ctx, String action) {
    Navigator.pop(ctx);
    final st = ctx.read<AppEditorState>();
    switch (action) {
      case 'hr':
        st.insertText('---');
        break;
      case 'date':
        st.insertText(DateTime.now().toLocal().toString());
        break;
    }
  }

  void _handleFormat(BuildContext ctx, String action) {
    Navigator.pop(ctx);
    final st = ctx.read<AppEditorState>();
    switch (action) {
      case 'upper':
        st.transformCase('upper');
        break;
      case 'lower':
        st.transformCase('lower');
        break;
      case 'title':
        st.transformCase('title');
        break;
      case 'superscript':
        st.applySuperscript();
        break;
      case 'subscript':
        st.applySubscript();
        break;
      case 'lh1':
        st.applyLineHeight(1.0);
        break;
      case 'lh15':
        st.applyLineHeight(1.5);
        break;
      case 'lh2':
        st.applyLineHeight(2.0);
        break;
      case 'clear':
        st.clearFormat();
        break;
    }
  }
}

// ── AI TRACK ──────────────────────────────────────────────
class _AITrack extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;

  const _AITrack({required this.controller, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        enabled: !loading,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          color: kInk,
        ),
        decoration: const InputDecoration(
          hintText: 'Pergunta à IA…',
          hintStyle: TextStyle(color: kMuted),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _doAI(context),
        autocorrect: false,
      ),
    );
  }

  Future<void> _doAI(BuildContext ctx) async {
    final prompt = controller.text.trim();
    if (prompt.isEmpty) return;
    controller.clear();

    final st = ctx.read<AppEditorState>();
    st.setAILoading(true);

    try {
      final res = await _callClaude(prompt);
      st.insertText(res);
    } catch (_) {
      st.insertText('[Erro IA]');
    }

    st.setAILoading(false);
  }

  Future<String> _callClaude(String prompt) async {
    throw UnimplementedError('Implement Claude API call here');
  }
}

// ── CONFIRM BUTTON ────────────────────────────────────────
class _ConfirmBtn extends StatefulWidget {
  final bool aiMode, aiLoading;
  final TextEditingController aiController;

  const _ConfirmBtn({
    required this.aiMode,
    required this.aiLoading,
    required this.aiController,
  });

  @override
  State<_ConfirmBtn> createState() => _ConfirmBtnState();
}

class _ConfirmBtnState extends State<_ConfirmBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();

    return Padding(
      padding: const EdgeInsets.only(right: 6, left: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (st.aiMode) {
            // trigger AI
          } else {
            st.focusNode.requestFocus();
          }
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.aiLoading
                  ? Colors.white.withOpacity(0.92)
                  : st.aiMode
                      ? kAccent
                      : Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              border: Border.all(
                color: st.aiMode && !widget.aiLoading
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.aiLoading
                ? const _AIDots()
                : Icon(
                    st.aiMode ? LucideIcons.send : LucideIcons.check,
                    size: 16,
                    color: st.aiMode ? kWhite : kSub,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── AI DOTS ───────────────────────────────────────────────
class _AIDots extends StatefulWidget {
  const _AIDots();

  @override
  State<_AIDots> createState() => _AIDotsState();
}

class _AIDotsState extends State<_AIDots> with TickerProviderStateMixin {
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
      )..repeat(),
    );

    _anims = _ctrls.asMap().entries.map((e) {
      final ctrl = e.value;
      final delay = e.key * 0.2;
      return TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 60),
      ]).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: Interval(delay, 1.0, curve: Curves.easeInOut),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: kAccent.withOpacity(_anims[i].value == 0.6 ? 0.4 : 1.0),
              shape: BoxShape.circle,
            ),
            transform: Matrix4.diagonal3Values(
              _anims[i].value,
              _anims[i].value,
              1,
            ),
            transformAlignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────
class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withOpacity(0.45),
      );
}

class _TbBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _TbBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  State<_TbBtn> createState() => _TbBtnState();
}

class _TbBtnState extends State<_TbBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 38,
          width: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: widget.active
                ? kAccentBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            widget.icon,
            size: 17,
            color: widget.active ? kAccent : kSub,
          ),
        ),
      ),
    );
  }
}

class _FmtBtn extends StatefulWidget {
  final String label;
  final FontWeight weight;
  final bool italic, underline, strike, active;
  final VoidCallback onTap;

  const _FmtBtn({
    required this.label,
    required this.weight,
    required this.onTap,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.active = false,
  });

  @override
  State<_FmtBtn> createState() => _FmtBtnState();
}

class _FmtBtnState extends State<_FmtBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 38,
          constraints: const BoxConstraints(minWidth: 38),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: widget.active
                ? kAccentBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: widget.weight,
                fontStyle:
                    widget.italic ? FontStyle.italic : FontStyle.normal,
                decoration: widget.underline
                    ? TextDecoration.underline
                    : widget.strike
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                color: widget.active ? kAccent : kSub,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlignBtn extends StatelessWidget {
  final IconData icon;
  final String align, current;

  const _AlignBtn({
    required this.icon,
    required this.align,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final active = align == current;
    return _TbBtn(
      icon: icon,
      active: active,
      onTap: () => context.read<AppEditorState>().applyAlign(align),
    );
  }
}

class _Chip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool useplus, usesettings;

  const _Chip({
    super.key,
    required this.label,
    required this.onTap,
    this.useplus = false,
    this.usesettings = false,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                widget.useplus
                    ? LucideIcons.plus
                    : widget.usesettings
                        ? LucideIcons.settings2
                        : LucideIcons.chevronDown,
                size: 11,
                color: kInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorBtn extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorBtn({super.key, required this.color, required this.onTap});

  @override
  State<_ColorBtn> createState() => _ColorBtnState();
}

class _ColorBtnState extends State<_ColorBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 38,
          width: 38,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: kSub,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── POPUP CARD ────────────────────────────────────────────
class _PopupCard extends StatefulWidget {
  final Widget child;
  final double arrowLeft;
  final double originX;

  const _PopupCard({
    required this.child,
    required this.arrowLeft,
    required this.originX,
  });

  @override
  State<_PopupCard> createState() => _PopupCardState();
}

class _PopupCardState extends State<_PopupCard>
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
    _scale = CurvedAnimation(parent: _ctrl, curve: kPopIn)
        .drive(Tween(begin: 0.5, end: 1.0));
    _opacity = CurvedAnimation(parent: _ctrl, curve: kPopIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          alignment: Alignment(
            (widget.originX / 100) * 2 - 1,
            1.2,
          ),
          child: child,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.child,
              ),
            ),
          ),
          Positioned(
            bottom: -9,
            left: widget.arrowLeft,
            child: SizedBox(
              width: 18,
              height: 9,
              child: CustomPaint(painter: _ArrowPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(size.width / 2 - 6.5, 0)
      ..lineTo(size.width / 2 + 6.5, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}