import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../editor_state.dart';

class DrawerWidget extends StatelessWidget {
  final VoidCallback onClose;
  const DrawerWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<EditorState>();
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: const Text(
              'FUNCIONALIDADES',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kMuted,
                letterSpacing: 0.06 * 13,
              ),
            ),
          ),
          // Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: kBorder)),
                    ),
                    child: Column(
                      children: [
                        _DrawerBtn(
                          icon: st.aiMode ? Icons.smart_toy : Icons.keyboard,
                          label: st.aiMode ? 'IA activa' : 'Toolbar / IA',
                          active: st.aiMode,
                          onTap: () {
                            st.toggleAI();
                            onClose();
                          },
                        ),
                        _DrawerBtn(
                          icon: st.a4Mode ? Icons.grid_view : Icons.article,
                          label: st.a4Mode ? 'Formato: A4' : 'Formato: Scroll',
                          active: st.a4Mode,
                          onTap: () {
                            st.toggleA4();
                            onClose();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DrawerBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override State<_DrawerBtn> createState() => _DrawerBtnState();
}

class _DrawerBtnState extends State<_DrawerBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.active
                ? kAccentBg
                : _hovered
                    ? Colors.black.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18,
                  color: widget.active ? kAccent : kSub),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.active ? kAccent : kInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}