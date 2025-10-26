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
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'Português';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(
        title: 'Configurações',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              AppHaptics.light();
              AppSnackbar.info(context, 'Ajuda em breve');
            },
          ),
        ],
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

          // Seção de Notificações
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificações', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(
                  icon: Icons.notifications_rounded,
                  title: 'Notificações Push',
                  subtitle: 'Receba alertas sobre seus bots',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      AppHaptics.light();
                      setState(() => _notificationsEnabled = value);
                      AppSnackbar.info(
                        context,
                        value ? 'Notificações ativadas' : 'Notificações desativadas',
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.volume_up_rounded,
                  title: 'Sons',
                  subtitle: 'Sons de notificações e alertas',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) {
                      AppHaptics.light();
                      setState(() => _soundEnabled = value);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.vibration_rounded,
                  title: 'Vibração',
                  subtitle: 'Feedback tátil nas interações',
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      AppHaptics.light();
                      setState(() => _vibrationEnabled = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Seção de Preferências
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferências', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(
                  icon: Icons.language_rounded,
                  title: 'Idioma',
                  subtitle: _selectedLanguage,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    _showLanguageBottomSheet();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Moeda',
                  subtitle: 'USD (\$)',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    AppSnackbar.info(context, 'Seleção de moeda em breve');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Seção de Segurança
          FadeInWidget(
            delay: const Duration(milliseconds: 300),
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
                    AppSnackbar.info(context, 'Configuração de biometria em breve');
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
                    AppSnackbar.info(context, 'Alteração de PIN em breve');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Seção Sobre
          FadeInWidget(
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sobre', style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsCard(
                  icon: Icons.info_rounded,
                  title: 'Versão do App',
                  subtitle: '1.0.0 (Build 1)',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    _showAboutDialog();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.description_rounded,
                  title: 'Termos de Uso',
                  subtitle: 'Leia nossos termos e condições',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    AppSnackbar.info(context, 'Termos de uso em breve');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSettingsCard(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Política de Privacidade',
                  subtitle: 'Como protegemos seus dados',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    AppSnackbar.info(context, 'Política de privacidade em breve');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Botão de Logout
          FadeInWidget(
            delay: const Duration(milliseconds: 500),
            child: SecondaryButton(
              text: 'Sair da Conta',
              icon: Icons.logout_rounded,
              expanded: true,
              onPressed: () {
                AppHaptics.heavy();
                _showLogoutDialog();
              },
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
          Divider(height: 1, color: context.colors.outlineVariant),
          _buildThemeOption(
            title: 'Automático',
            subtitle: 'Seguir configuração do sistema',
            icon: Icons.brightness_auto_rounded,
            isSelected: false, // Implement system theme detection if needed
            onTap: () {
              AppHaptics.medium();
              AppSnackbar.info(context, 'Tema automático em breve');
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

  void _showLanguageBottomSheet() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Selecione o Idioma',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption('Português', 'pt'),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageOption('English', 'en'),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageOption('Español', 'es'),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageOption('Français', 'fr'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, String code) {
    final isSelected = _selectedLanguage == language;
    return AppListTile(
      title: language,
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        AppHaptics.selection();
        setState(() => _selectedLanguage = language);
        Navigator.pop(context);
        AppSnackbar.success(context, 'Idioma alterado para $language');
      },
    );
  }

  void _showAboutDialog() {
    AppDialog.show(
      context: context,
      title: 'Sobre o App',
      icon: Icons.info_rounded,
      iconColor: AppColors.primary,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZoomTrade Trading Bot',
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Versão 1.0.0 (Build 1)',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aplicativo de trading automatizado com bots inteligentes e análise de mercado em tempo real.',
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LabeledDivider(label: 'Desenvolvido com'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Flutter & Material Design 3',
                style: context.textStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        PrimaryButton(
          text: 'Fechar',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    AppDialog.show(
      context: context,
      title: 'Sair da Conta',
      content: 'Tem certeza que deseja sair? Você precisará fazer login novamente.',
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
      actions: [
        TertiaryButton(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          text: 'Sair',
          onPressed: () {
            AppHaptics.heavy();
            Navigator.pop(context);
            Navigator.pop(context); // Go back to previous screen
            AppSnackbar.success(context, 'Logout realizado com sucesso');
          },
        ),
      ],
    );
  }
}