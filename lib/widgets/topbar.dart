import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

class TopBar extends StatefulWidget {
  final VoidCallback onMenuTap;
  const TopBar({super.key, required this.onMenuTap});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final _titleController = TextEditingController();
  final _titleFocus = FocusNode();
  bool _titleFocused = false;
  bool _titleHovered = false;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(() {
      setState(() => _titleFocused = _titleFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppEditorState>();
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Left: Menu button ─────────────────────────
          Positioned(
            left: 6,
            child: _TbIconBtn(
              icon: Icons.menu,
              onTap: widget.onMenuTap,
            ),
          ),

          // ── Center: Title ─────────────────────────────
          Positioned(
            left: 60,
            right: 60,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 160,
                ),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _titleHovered = true),
                  onExit: (_) => setState(() => _titleHovered = false),
                  child: GestureDetector(
                    onTap: () => _titleFocus.requestFocus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _titleFocused
                            ? kAccentBg
                            : _titleHovered
                                ? Colors.black.withOpacity(0.04)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _titleFocused ? kAccent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: EditableText(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kInk,
                        ),
                        cursorColor: kAccent,
                        backgroundCursorColor: Colors.transparent,
                        textAlign: TextAlign.center,
                        onChanged: (v) => st.title = v,
                        onSubmitted: (_) => _titleFocus.unfocus(),
                        maxLines: _titleFocused ? null : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Right: Undo / Redo ────────────────────────
          Positioned(
            right: 6,
            child: Row(
              children: [
                _TbIconBtn(
                  icon: Icons.undo,
                  onTap: () => context.read<AppEditorState>().undo(),
                ),
                _TbIconBtn(
                  icon: Icons.redo,
                  onTap: () => context.read<AppEditorState>().redo(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TbIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TbIconBtn({required this.icon, required this.onTap});

  @override
  State<_TbIconBtn> createState() => _TbIconBtnState();
}

class _TbIconBtnState extends State<_TbIconBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _pressed ? Colors.black.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(widget.icon, size: 20, color: kSub),
      ),
    );
  }
}