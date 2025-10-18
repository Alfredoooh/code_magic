import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';

class UserDrawerSettings {
  static void showSettingsModal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentTheme = 'light';
  String _currentLocale = 'pt';
  String _currentCardStyle = 'modern';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Configurações',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingCard(
                context: context,
                icon: Icons.dark_mode,
                title: 'Tema',
                subtitle: _currentTheme == 'dark' ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context: context,
                icon: Icons.language,
                title: 'Idioma',
                subtitle: _getLanguageName(_currentLocale),
                onTap: () => _showLanguageDialog(context),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildSettingCard(
                context: context,
                icon: Icons.style,
                title: 'Estilo do Cartão',
                subtitle: _getCardStyleName(_currentCardStyle),
                onTap: () => _showCardStylePicker(context),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionTitle(
                      text: title,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    AppDialogs.showConfirmation(
      context,
      'Escolha o tema',
      'Selecione o tema desejado para o aplicativo',
      onConfirm: () {
        setState(() {
          _currentTheme = 'dark';
        });
      },
      confirmText: '🌙 Escuro',
      cancelText: '☀️ Claro',
      isDestructive: false,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    AppBottomSheet.show(
      context,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Escolha o idioma',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 24),
            _buildLanguageOption('🇵🇹', 'Português', 'pt'),
            const SizedBox(height: 12),
            _buildLanguageOption('🇺🇸', 'English', 'en'),
            const SizedBox(height: 12),
            _buildLanguageOption('🇪🇸', 'Español', 'es'),
            const SizedBox(height: 24),
            AppPrimaryButton(
              text: 'Concluído',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String name, String code) {
    final isSelected = _currentLocale == code;
    return InkWell(
      onTap: () {
        setState(() {
          _currentLocale = code;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showCardStylePicker(BuildContext context) {
    AppBottomSheet.show(
      context,
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Estilo do Cartão',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildStyleOption('modern', 'Moderno', Icons.credit_card),
                  _buildStyleOption('gradient', 'Gradiente', Icons.gradient),
                  _buildStyleOption('minimal', 'Minimalista', Icons.rectangle_outlined),
                  _buildStyleOption('glass', 'Vidro', Icons.auto_awesome),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Concluído',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption(String style, String name, IconData icon) {
    final isSelected = _currentCardStyle == style;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentCardStyle = style;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 36,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Português';
    }
  }

  String _getCardStyleName(String style) {
    switch (style) {
      case 'modern':
        return 'Moderno';
      case 'gradient':
        return 'Gradiente';
      case 'minimal':
        return 'Minimalista';
      case 'glass':
        return 'Vidro';
      default:
        return 'Moderno';
    }
  }
}