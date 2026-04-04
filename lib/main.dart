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
      home: const HomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawerController;
  bool _drawerOpen = false;

  static const double _drawerWidth = 280;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  Future<void> _toggleDrawer() async {
    if (_drawerOpen) {
      await _drawerController.reverse();
      if (mounted) {
        setState(() => _drawerOpen = false);
      }
    } else {
      if (mounted) {
        setState(() => _drawerOpen = true);
      }
      await _drawerController.forward();
    }
  }

  Future<void> _closeDrawer() async {
    if (!_drawerOpen) return;
    await _drawerController.reverse();
    if (mounted) {
      setState(() => _drawerOpen = false);
    }
  }

  Future<void> _openDrawer() async {
    if (_drawerOpen) return;
    if (mounted) {
      setState(() => _drawerOpen = true);
    }
    await _drawerController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return AnimatedBuilder(
      animation: _drawerController,
      builder: (context, child) {
        final t = _drawerController.value;

        final overlayStyle = t > 0.01
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Scaffold(
            backgroundColor: const Color(0xFF111111),
            body: Stack(
              children: [
                // Drawer por baixo
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(-_drawerWidth * (1 - t), 0),
                      child: Container(
                        width: _drawerWidth,
                        height: media.size.height,
                        color: const Color(0xFFF4F4F4),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Menu',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _DrawerItem(
                                  label: 'Início',
                                  icon: Icons.home_rounded,
                                  onTap: () => _closeDrawer(),
                                ),
                                _DrawerItem(
                                  label: 'Perfil',
                                  icon: Icons.person_rounded,
                                  onTap: () => _closeDrawer(),
                                ),
                                _DrawerItem(
                                  label: 'Configurações',
                                  icon: Icons.settings_rounded,
                                  onTap: () => _closeDrawer(),
                                ),
                                _DrawerItem(
                                  label: 'Sair',
                                  icon: Icons.logout_rounded,
                                  onTap: () => _closeDrawer(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Overlay escuro
                if (t > 0)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeDrawer,
                      child: Container(
                        color: Colors.black.withOpacity(0.18 * t),
                      ),
                    ),
                  ),

                // Tela principal
                Transform.translate(
                  offset: Offset(110 * t, 0),
                  child: Transform.scale(
                    scale: 1 - (0.055 * t),
                    alignment: Alignment.center,
                    child: Container(
                      width: media.size.width,
                      height: media.size.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18 * t),
                        boxShadow: t > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18 * t),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 60,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _drawerOpen
                                          ? _closeDrawer
                                          : _openDrawer,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.menu_rounded,
                                          size: 28,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Tela principal',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 20, 16, 16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Texto qualquer 1',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Texto qualquer 2: este conteúdo pode ser substituído depois pelo teu layout real.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          color: Color(0xB8000000),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F7),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          'Texto qualquer 3 dentro de um cartão simples.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF111111),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F7),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          'Texto qualquer 4. Aqui podes colocar botões, listas, imagens ou outras secções.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF111111),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F7),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          'Texto qualquer 5. O drawer abre por cima e a tela faz o deslocamento com animação suave.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF111111),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: _drawerOpen
                                            ? _closeDrawer
                                            : _openDrawer,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF111111),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          _drawerOpen
                                              ? 'Fechar menu'
                                              : 'Abrir menu',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF222222), size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}