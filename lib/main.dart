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

class _AnimatedSheetScreenState extends State<AnimatedSheetScreen> {
  bool isOpen = false;

  void toggle() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  void close() {
    setState(() {
      isOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;

    const duration = Duration(milliseconds: 320);
    const curve = Curves.easeOutCubic;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isOpen
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
            AnimatedPositioned(
              duration: duration,
              curve: curve,
              left: 0,
              right: 0,
              top: isOpen ? topInset + 12 : 0,
              bottom: isOpen ? 12 : 0,
              child: AnimatedContainer(
                duration: duration,
                curve: curve,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isOpen ? 16 : 0),
                  boxShadow: isOpen
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
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
                      child: Text(isOpen ? 'Expandir tela' : 'Reduzir tela'),
                    ),
                  ),
                ),
              ),
            ),

            AnimatedOpacity(
              duration: duration,
              curve: curve,
              opacity: isOpen ? 1 : 0,
              child: IgnorePointer(
                ignoring: !isOpen,
                child: GestureDetector(
                  onTap: close,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.32),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSlide(
                duration: duration,
                curve: curve,
                offset: isOpen ? Offset.zero : const Offset(0, 1.1),
                child: AnimatedOpacity(
                  duration: duration,
                  curve: curve,
                  opacity: isOpen ? 1 : 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 540,
                      minWidth: media.size.width,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7).withOpacity(0.98),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isOpen ? 14 : 16),
                          topRight: Radius.circular(isOpen ? 14 : 16),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isOpen ? 0.10 : 0.0),
                            blurRadius: 16,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3C3C43).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 14),
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
                              const Text(
                                'O modal sobe ao mesmo tempo que a tela encolhe.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Color(0xB8000000),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: close,
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFFE9E9EE),
                                      foregroundColor: const Color(0xFF111111),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Fechar'),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A84FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}