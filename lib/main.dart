import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AnimatedSheetScreen(),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
    );
  }
}

class AnimatedSheetScreen extends StatefulWidget {
  const AnimatedSheetScreen({super.key});

  @override
  State<AnimatedSheetScreen> createState() => _AnimatedSheetScreenState();
}

class _AnimatedSheetScreenState extends State<AnimatedSheetScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _dragStartValue = 0.0;

  static const Duration _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeOutCubic;

  static const double _screenScaleOpen = 0.945;

  static const double _screenTopBottomOpen = 14.0 * 0.8;
  static const double _screenRadiusOpen = 18.0 * 0.7;

  static const double _sheetRadiusOpen = 16.0 * 0.7;
  static const double _sheetRadiusClosed = 18.0 * 0.7;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.animateTo(
      target,
      duration: _duration,
      curve: _curve,
    );
  }

  void toggle() {
    if (_controller.value < 0.5) {
      _animateTo(1.0);
    } else {
      _animateTo(0.0);
    }
  }

  void open() => _animateTo(1.0);
  void close() => _animateTo(0.0);

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = _controller.value;
  }

  void _onDragUpdate(DragUpdateDetails details, double dragDistance) {
    final delta = details.delta.dy / dragDistance;
    final nextValue = (_dragStartValue - delta).clamp(0.0, 1.0);
    _controller.value = nextValue;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    if (velocity > 700) {
      close();
      return;
    }

    if (velocity < -700) {
      open();
      return;
    }

    if (_controller.value < 0.5) {
      close();
    } else {
      open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetTravel = media.size.height * 0.60;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = _controller.value;

        final screenTop = ui.lerpDouble(
          0.0,
          media.padding.top + _screenTopBottomOpen,
          p,
        )!;
        final screenBottom = ui.lerpDouble(0.0, _screenTopBottomOpen, p)!;
        final screenScale = ui.lerpDouble(1.0, _screenScaleOpen, p)!;
        final screenRadius = ui.lerpDouble(0.0, _screenRadiusOpen, p)!;

        final sheetOpacity = p;
        final sheetOffsetY = (1.0 - p) * sheetTravel;
        final sheetShadowOpacity = ui.lerpDouble(0.0, 0.10, p)!;
        final sheetRadius = ui.lerpDouble(_sheetRadiusClosed, _sheetRadiusOpen, p)!;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: p > 0.5
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: screenTop,
                  bottom: screenBottom,
                  child: Transform.scale(
                    scale: screenScale,
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenRadius),
                        boxShadow: p > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : const [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenRadius),
                        child: SafeArea(
                          child: Center(
                            child: ElevatedButton(
                              onPressed: toggle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF111111),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                p > 0.5 ? 'Expandir tela' : 'Reduzir tela',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                IgnorePointer(
                  ignoring: p <= 0.01,
                  child: Opacity(
                    opacity: p * 0.32,
                    child: GestureDetector(
                      onTap: close,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: IgnorePointer(
                    ignoring: p <= 0.01,
                    child: Opacity(
                      opacity: sheetOpacity,
                      child: Transform.translate(
                        offset: Offset(0, sheetOffsetY),
                        child: SafeArea(
                          top: false,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 540,
                              minWidth: media.size.width,
                              maxHeight: media.size.height * 0.52,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F7).withOpacity(0.98),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(sheetRadius),
                                  topRight: Radius.circular(sheetRadius),
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.55),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(sheetShadowOpacity),
                                    blurRadius: 16,
                                    offset: const Offset(0, -6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(sheetRadius),
                                  topRight: Radius.circular(sheetRadius),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragStart: _onDragStart,
                                      onVerticalDragUpdate: (details) =>
                                          _onDragUpdate(
                                        details,
                                        sheetTravel,
                                      ),
                                      onVerticalDragEnd: _onDragEnd,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3C3C43)
                                                  .withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'iOS Paper Sheet',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        'O modal sobe ao mesmo tempo que a tela encolhe.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.45,
                                          color: Color(0xB8000000),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          0,
                                          18,
                                          18,
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TextButton(
                                                  onPressed: close,
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFE9E9EE),
                                                    foregroundColor:
                                                        const Color(0xFF111111),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Text('Fechar'),
                                                ),
                                                const SizedBox(width: 10),
                                                TextButton(
                                                  onPressed: () {},
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF0A84FF),
                                                    foregroundColor: Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        12,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Text('Confirmar'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}