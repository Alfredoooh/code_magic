import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'editor_state.dart';
import 'widgets/topbar.dart';
import 'widgets/drawer_widget.dart';
import 'widgets/canvas_area.dart';
import 'widgets/floating_toolbar.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawerAnim;
  late final Animation<double> _appShift;
  late final Animation<double> _overlayOpacity;

  @override
  void initState() {
    super.initState();
    _drawerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _appShift = Tween<double>(begin: 0, end: 110).animate(
      CurvedAnimation(parent: _drawerAnim, curve: kCurve),
    );

    _overlayOpacity = Tween<double>(begin: 0, end: 0.18).animate(
      CurvedAnimation(parent: _drawerAnim, curve: kCurve),
    );
  }

  @override
  void dispose() {
    _drawerAnim.dispose();
    super.dispose();
  }

  void _handleDrawerToggle(AppEditorState st) {
    if (st.drawerOpen) {
      _drawerAnim.forward();
    } else {
      _drawerAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppEditorState(),
      child: Consumer<AppEditorState>(
        builder: (ctx, st, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            if (st.drawerOpen &&
                _drawerAnim.status != AnimationStatus.forward &&
                _drawerAnim.status != AnimationStatus.completed) {
              _drawerAnim.forward();
            } else if (!st.drawerOpen &&
                _drawerAnim.status != AnimationStatus.reverse &&
                _drawerAnim.status != AnimationStatus.dismissed) {
              _drawerAnim.reverse();
            }
          });

          return Scaffold(
            backgroundColor: kBg,
            body: Stack(
              children: [
                // ── APP ─────────────────────────────────
                AnimatedBuilder(
                  animation: _appShift,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_appShift.value, 0),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      TopBar(onMenuTap: () => st.toggleDrawer()),
                      Expanded(
                        child: Stack(
                          children: [
                            const CanvasArea(),
                            const Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: FloatingToolbar(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── OVERLAY ─────────────────────────────
                AnimatedBuilder(
                  animation: _overlayOpacity,
                  builder: (_, __) => IgnorePointer(
                    ignoring: !st.drawerOpen,
                    child: GestureDetector(
                      onTap: () => st.closeDrawer(),
                      child: Container(
                        color: Colors.black.withOpacity(_overlayOpacity.value),
                      ),
                    ),
                  ),
                ),

                // ── DRAWER ──────────────────────────────
                AnimatedBuilder(
                  animation: _drawerAnim,
                  builder: (_, __) => Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(-260 + 260 * _drawerAnim.value, 0),
                        child: Material(
                          color: Colors.transparent,
                          child: SafeArea(
                            child: DrawerWidget(
                              onClose: () => st.closeDrawer(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}