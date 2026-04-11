import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants.dart';
import '../editor_state.dart';

class TopBar extends StatefulWidget {
  final VoidCallback onMenuTap;
  const TopBar({super.key, required this.onMenuTap});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  bool _titleFocused = false;
  bool _menuPressed = false;
  bool _undoPressed = false;
  bool _redoPressed = false;
  bool _titlePressed = false;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(() {
      if (mounted) {
        setState(() => _titleFocused = _titleFocus.hasFocus);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final st = context.read<AppEditorState>();
    if (!_titleFocus.hasFocus && _titleController.text != st.title) {
      _titleController.text = st.title;
    }
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

    if (!_titleFocus.hasFocus && _titleController.text != st.title) {
      _titleController.text = st.title;
    }

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            child: _PulseIconBtn(
              icon: LucideIcons.menu,
              pressed: _menuPressed,
              onPressedChanged: (v) => setState(() => _menuPressed = v),
              onTap: widget.onMenuTap,
            ),
          ),
          Positioned(
            left: 60,
            right: 60,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 160,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => setState(() => _titlePressed = true),
                  onTapUp: (_) {
                    setState(() => _titlePressed = false);
                    _titleFocus.requestFocus();
                  },
                  onTapCancel: () => setState(() => _titlePressed = false),
                  child: AnimatedScale(
                    scale: _titlePressed ? 0.985 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
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
                        onChanged: (v) {
                          st.title = v;
                        },
                        onSubmitted: (_) => _titleFocus.unfocus(),
                        maxLines: _titleFocused ? null : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            child: Row(
              children: [
                _PulseIconBtn(
                  icon: LucideIcons.undo2,
                  pressed: _undoPressed,
                  onPressedChanged: (v) => setState(() => _undoPressed = v),
                  onTap: () => context.read<AppEditorState>().undo(),
                ),
                _PulseIconBtn(
                  icon: LucideIcons.redo2,
                  pressed: _redoPressed,
                  onPressedChanged: (v) => setState(() => _redoPressed = v),
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

class _PulseIconBtn extends StatelessWidget {
  final IconData icon;
  final bool pressed;
  final ValueChanged<bool> onPressedChanged;
  final VoidCallback onTap;

  const _PulseIconBtn({
    required this.icon,
    required this.pressed,
    required this.onPressedChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) {
        onPressedChanged(false);
        onTap();
      },
      onTapCancel: () => onPressedChanged(false),
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: kSub,
            ),
          ),
        ),
      ),
    );
  }
}