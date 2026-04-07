import 'package:flutter/material.dart';
import 'theme.dart';

// ─── POPUP OVERLAY ───────────────────────────────────────────────────────────
class PopupOverlay extends StatefulWidget {
  final double left;
  final double bottom;
  final double width;
  final double arrowLeft;
  final double originX;
  final Widget child;
  final VoidCallback onDismiss;

  const PopupOverlay({
    super.key,
    required this.left,
    required this.bottom,
    required this.width,
    required this.arrowLeft,
    required this.originX,
    required this.child,
    required this.onDismiss,
  });

  @override
  State<PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<PopupOverlay>
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
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const _SpringCurve()),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss mask
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Popup
        Positioned(
          left: widget.left,
          bottom: widget.bottom,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (ctx, child) => FadeTransition(
              opacity: _opacity,
              child: Transform.scale(
                scale: _scale.value,
                alignment: Alignment(
                  (widget.originX / widget.width) * 2 - 1,
                  1.0 + (14 / 100),
                ),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x21000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.child,
                  ),
                ),
                // Arrow
                Align(
                  alignment: Alignment(
                    ((widget.arrowLeft + 7) / widget.width) * 2 - 1,
                    0,
                  ),
                  child: CustomPaint(
                    size: const Size(18, 9),
                    painter: _ArrowPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    path.moveTo(size.width / 2 - 7, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 7, 0);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SpringCurve extends Curve {
  const _SpringCurve();
  @override
  double transform(double t) {
    return 1.0 + (t - 1.0) * (t - 1.0) * ((1.56 + 1) * (t - 1.0) + 1.56);
  }
}
