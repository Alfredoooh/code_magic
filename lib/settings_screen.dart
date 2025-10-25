// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Seção de Aparência
          FadeInWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aparência',
                  style: context.textStyles.titleLarge,
                ),
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
                Text(
                  'Notificações',
                  style: context.textStyles.titleLarge,
                ),
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
                Text(
                  'Preferências',
                  style: context.textStyles.titleLarge,
                ),
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
                Text(
                  'Segurança',
                  style: context.textStyles.titleLarge,
                ),
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
                Text(
                  'Sobre',
                  style: context.textStyles.titleLarge,
                ),
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
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  AppHaptics.heavy();
                  _showLogoutDialog();
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Sair da Conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
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
              AppHaptics.medium();
              AppTheme.toggleTheme();
              setState(() {});
              AppSnackbar.success(context, 'Tema alterado para claro');
            },
          ),
          Divider(height: 1, color: context.colors.outlineVariant),
          _buildThemeOption(
            title: 'Tema Escuro',
            subtitle: 'Interface com fundo escuro',
            icon: Icons.dark_mode_rounded,
            isSelected: context.isDark,
            onTap: () {
              AppHaptics.medium();
              AppTheme.toggleTheme();
              setState(() {});
              AppSnackbar.success(context, 'Tema alterado para escuro');
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.15)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppShapes.medium),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : context.colors.onSurfaceVariant,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppShapes.full),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Selecione o Idioma', style: context.textStyles.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            _buildLanguageOption('Português', 'pt'),
            const SizedBox(height: AppSpacing.sm),
            _buildLanguageOption('English', 'en'),
            const SizedBox(height: AppSpacing.sm),
            _buildLanguageOption('Español', 'es'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, String code) {
    final isSelected = _selectedLanguage == language;
    return ListTile(
      title: Text(language),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppShapes.medium),
              ),
              child: const Icon(Icons.info_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Sobre o App'),
          ],
        ),
        content: Column(
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
          FilledButton(
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text(
          'Tem certeza que deseja sair? Você precisará fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              AppHaptics.heavy();
              Navigator.pop(context);
              // Aqui você implementaria a lógica de logout
              AppSnackbar.success(context, 'Logout realizado com sucesso');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}