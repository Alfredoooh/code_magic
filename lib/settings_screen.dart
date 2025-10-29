// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({
    Key? key,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(
        title: 'Configurações',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Seção de Aparência
          FadeInWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aparência', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildThemeSelector(),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Seção de Segurança
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Segurança', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometria',
                  subtitle: 'Proteja seu acesso com biometria',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    _showBiometricSettings();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.lock_rounded,
                  title: 'Alterar PIN',
                  subtitle: 'Altere seu código de segurança',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    _showPinSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Seção Sobre
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sobre', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(
                  icon: Icons.info_rounded,
                  title: 'Sobre o App',
                  subtitle: 'Versão 1.0.0 (Build 1)',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return AnimatedCard(
      child: Column(
        children: [
          _buildThemeOption(
            title: 'Tema Claro',
            subtitle: 'Interface com fundo branco',
            icon: Icons.light_mode_rounded,
            isSelected: !context.isDark,
            onTap: () {
              if (context.isDark) {
                AppHaptics.medium();
                widget.onThemeChanged();
                setState(() {});
                AppSnackbar.success(context, 'Tema alterado para claro');
              }
            },
          ),
          Divider(height: 1, color: context.colors.outlineVariant),
          _buildThemeOption(
            title: 'Tema Escuro',
            subtitle: 'Interface com fundo escuro',
            icon: Icons.dark_mode_rounded,
            isSelected: context.isDark,
            onTap: () {
              if (!context.isDark) {
                AppHaptics.medium();
                widget.onThemeChanged();
                setState(() {});
                AppSnackbar.success(context, 'Tema alterado para escuro');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.15)
                      : context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppShapes.medium),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : context.colors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return AnimatedCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppShapes.medium),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: context.textStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showBiometricSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Configuração de Biometria'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Biometria',
                    style: context.textStyles.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Configure a autenticação biométrica para proteger seu acesso ao app.',
                    style: context.textStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    text: 'Configurar Biometria',
                    icon: Icons.fingerprint_rounded,
                    onPressed: () {
                      AppSnackbar.info(context, 'Funcionalidade em desenvolvimento');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPinSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Alterar PIN'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Alterar PIN',
                    style: context.textStyles.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Defina um novo código PIN para proteger seu acesso.',
                    style: context.textStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    text: 'Definir Novo PIN',
                    icon: Icons.lock_outline_rounded,
                    onPressed: () {
                      AppSnackbar.info(context, 'Funcionalidade em desenvolvimento');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Sobre o App'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppShapes.extraLarge),
                    ),
                    child: Icon(
                      Icons.info_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'ZoomTrade Trading Bot',
                    style: context.textStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Versão 1.0.0 (Build 1)',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AnimatedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            'Aplicativo de trading automatizado com bots inteligentes e análise de mercado em tempo real.',
                            style: context.textStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const LabeledDivider(label: 'Desenvolvido com'),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Flutter & Material Design 3',
                                style: context.textStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    text: 'Fechar',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}