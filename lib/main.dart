// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/config.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ElephantBetApp(),
    ),
  );
}

class ElephantBetApp extends StatelessWidget {
  const ElephantBetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElephantBet AO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF268CD4),
          brightness: Brightness.dark,
          primary: const Color(0xFF268CD4),
          secondary: const Color(0xFFFFCE00),
          surface: const Color(0xFF1A3A6E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B3E),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF112F6C),
          indicatorColor: const Color(0xFF268CD4).withOpacity(0.25),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A3A6E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF112F6C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();
  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = Provider.of<AppState>(context, listen: false);
    final raw = await rootBundle.loadString('assets/config/appconfig.json');
    final cfg = AppConfig.fromJson(jsonDecode(raw));
    await state.init(cfg);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) {
        if (state.loading) return const _SplashScreen();
        if (state.error != null && state.sports.isEmpty) {
          return _ErrorScreen(error: state.error!);
        }
        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF112F6C),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF268CD4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/favicon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text('ElephantBet Angola',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('A conectar à API...',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 32),
            const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFCE00))),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Sem ligação',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final state = Provider.of<AppState>(context, listen: false);
                  final raw = await DefaultAssetBundle.of(context)
                      .loadString('assets/config/appconfig.json');
                  final cfg = AppConfig.fromJson(jsonDecode(raw));
                  await state.init(cfg);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}