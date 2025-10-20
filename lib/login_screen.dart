import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      AppStyles.showSnackBar(context, 'Por favor, insira seu token', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Simular validação do token (substituir por validação real com Deriv API)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Navegar para tela principal
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Logo e título
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppStyles.iosBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.iosBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Deriv Trading',
                  style: TextStyle(
                    color: AppStyles.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Conecte-se com sua conta Deriv',
                  style: TextStyle(
                    color: AppStyles.textSecondary,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Campo de token
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token de API',
                    hintText: 'Cole seu token aqui',
                    prefixIcon: Icon(Icons.vpn_key, color: AppStyles.textSecondary),
                  ),
                  style: const TextStyle(color: AppStyles.textPrimary),
                  enabled: !_isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botão de login
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.iosBlue,
                      disabledBackgroundColor: AppStyles.iosBlue.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Conectar',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Link para obter token
                TextButton(
                  onPressed: () {
                    AppStyles.showSnackBar(
                      context,
                      'Obtenha seu token em: app.deriv.com',
                    );
                  },
                  child: const Text(
                    'Como obter meu token?',
                    style: TextStyle(
                      color: AppStyles.iosBlue,
                      fontSize: 15,
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Informação do App ID
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppStyles.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppStyles.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppStyles.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'App ID: 71954',
                              style: TextStyle(
                                color: AppStyles.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Conexão segura com Deriv',
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
