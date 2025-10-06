import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação 
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar barra de status e segurança
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Segurança: Ocultar conteúdo na tela de apps recentes
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const AuthSystemApp());
}

class AuthSystemApp extends StatefulWidget {
  const AuthSystemApp({Key? key}) : super(key: key);

  @override
  State<AuthSystemApp> createState() => _AuthSystemAppState();
}

class _AuthSystemAppState extends State<AuthSystemApp> with WidgetsBindingObserver {
  bool _isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInBackground = state != AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aguarde! Por favor.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'SF Pro',
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFF34C759),
          surface: Color(0xFF1C1C1E),
          background: Color(0xFF000000),
          error: Color(0xFFFF3B30),
        ),
      ),
      builder: (context, child) {
        // Overlay de segurança com blur quando app está em background
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (_isAppInBackground)
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20.0,
                  sigmaY: 20.0,
                  tileMode: TileMode.clamp,
                ),
                child: Container(
                  // Mantém a cobertura total com um dim, sem nenhum ícone ou conteúdo.
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
          ],
        );
      },
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Pequeno delay para transição suave
      await Future.delayed(const Duration(milliseconds: 800));
      
      final user = await StorageService.getCurrentUser();
      
      if (!mounted) return;
      
      if (user != null) {
        // Verificar se a sessão ainda é válida
        final isValid = await AuthService.validateSession(user);
        
        if (!mounted) return;
        
        if (isValid) {
          Navigator.pushReplacementNamed(context, '/main');
          return;
        }
      }
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro de conexão. Verifique sua internet.';
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: _hasError ? _buildErrorState() : _buildLoadingState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CupertinoActivityIndicator(
          color: Color(0xFF007AFF),
          radius: 20,
        ),
        const SizedBox(height: 24),
        Text(
          'Carregando...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF3B30).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              CupertinoIcons.wifi_slash,
              size: 40,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sem Conexão',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12),
              onPressed: _retry,
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}