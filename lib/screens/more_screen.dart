import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class TradingWarningScreen extends StatefulWidget {
  const TradingWarningScreen({Key? key}) : super(key: key);

  @override
  _TradingWarningScreenState createState() => _TradingWarningScreenState();
}

class _TradingWarningScreenState extends State<TradingWarningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTradingWarning', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  // Warning Icon
                  AppIconCircle(
                    icon: Icons.warning_rounded,
                    size: 64,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  const AppSectionTitle(
                    text: 'Aviso Importante',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),

                  const SizedBox(height: 20),

                  // Main warning text
                  Text(
                    'Operações em qualquer corretora podem resultar em ganhos ou perdas. Portanto, use as ferramentas do app para controlar os riscos e evite operar por emoção ao ponto de perder todos os seus fundos.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Information sections
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.shield_outlined,
                            title: 'Gestão de Risco',
                            description:
                                'Nunca invista mais do que pode perder. Defina stop-loss e take-profit para proteger seu capital e minimizar perdas potenciais.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoCard(
                            icon: Icons.psychology_outlined,
                            title: 'Controle Emocional',
                            description:
                                'Decisões emocionais levam a perdas significativas. Mantenha-se disciplinado, siga sua estratégia e não deixe o medo ou a ganância controlar suas operações.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoCard(
                            icon: Icons.school_outlined,
                            title: 'Educação Contínua',
                            description:
                                'Aprenda constantemente sobre análise técnica, gestão de risco e psicologia do trading. O conhecimento é sua melhor ferramenta.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoCard(
                            icon: Icons.account_balance_outlined,
                            title: 'Diversificação',
                            description:
                                'Não coloque todos os seus fundos em uma única operação. Diversifique seu portfólio para reduzir riscos e aumentar oportunidades.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoCard(
                            icon: Icons.access_time_outlined,
                            title: 'Paciência e Disciplina',
                            description:
                                'O trading bem-sucedido requer tempo e paciência. Não force operações e espere as melhores oportunidades conforme sua estratégia.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoCard(
                            icon: Icons.trending_up_outlined,
                            title: 'Expectativas Realistas',
                            description:
                                'Lucros consistentes levam tempo. Evite promessas de ganhos rápidos e foque em crescimento sustentável a longo prazo.',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 16),
                    child: AppPrimaryButton(
                      text: 'Entendi',
                      onPressed: _handleDismiss,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionTitle(
                    text: title,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}