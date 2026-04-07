import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

// ─── AI DOTS ANIMATION ───────────────────────────────────────────────────────
class AiDots extends StatefulWidget {
  const AiDots({super.key});
  @override
  State<AiDots> createState() => _AiDotsState();
}

class _AiDotsState extends State<AiDots> with TickerProviderStateMixin {
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
      )..repeat(reverse: false),
    );
    _anims = _ctrls.asMap().entries.map((e) {
      final delay = e.key * 0.2;
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 60),
      ]).animate(CurvedAnimation(
        parent: e.value,
        curve: Interval(delay, math.min(delay + 0.7, 1.0)),
      ));
    }).toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: (i * 200)), () {
        if (mounted) _ctrls[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (ctx, _) => Opacity(
            opacity: _anims[i].value,
            child: Transform.scale(
              scale: _anims[i].value,
              child: Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(
                  color: T.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
