// lib/screens/user_drawer_settings.dart
import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class UserDrawerSettings {
  static void showSettingsModal(
    BuildContext context, {
    required String currentLocale,
    required String cardStyle,
    required Function(String) onThemeChanged,
    required Function(String) onLanguageChanged,
    required Function(String) onCardStyleChanged,
    required VoidCallback onColorsChanged,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentLocale: currentLocale,
          cardStyle: cardStyle,
          onThemeChanged: onThemeChanged,
          onLanguageChanged: onLanguageChanged,
          onCardStyleChanged: onCardStyleChanged,
          onColorsChanged: onColorsChanged,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final String currentLocale;
  final String cardStyle;
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final Function(String) onCardStyleChanged;
  final VoidCallback onColorsChanged;

  const SettingsScreen({
    required this.currentLocale,
    required this.cardStyle,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onCardStyleChanged,
    required this.onColorsChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currentTheme;
  late String _currentLocale;
  late String _currentCardStyle;

  @override
  void initState() {
    super.initState();
    _currentTheme = 'light';
    _currentLocale = widget.currentLocale;
    _currentCardStyle = widget.cardStyle;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(title: 'Configurações'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionTitle(text: '🎨 Aparência', fontSize: 20),
              SizedBox(height: 16),
              _buildSettingCard(
                context: context,
                icon: Icons.palette_rounded,
                title: 'Cor Principal',
                subtitle: 'Personalize as cores do app',
                onTap: () => _showColorPicker(context),
                isDark: isDark,
              ),
              SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.dark_mode_rounded,
                title: 'Tema',
                subtitle: _currentTheme == 'dark' ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context),
                isDark: isDark,
              ),
              SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.rounded_corner,
                title: 'Design Personalizado',
                subtitle: 'Bordas, tamanhos e espaços',
                onTap: () => _showDesignCustomizer(context),
                isDark: isDark,
              ),
              SizedBox(height: 32),
              AppSectionTitle(text: '⚙️ Preferências', fontSize: 20),
              SizedBox(height: 16),
              _buildSettingCard(
                context: context,
                icon: Icons.language_rounded,
                title: 'Idioma',
                subtitle: _getLanguageName(_currentLocale),
                onTap: () => _showLanguageDialog(context),
                isDark: isDark,
              ),
              SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: Icons.style_rounded,
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
      borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(
          onColorSelected: (String colorKey) {
            setState(() {
              AppColors.setColorScheme(colorKey);
            });
            widget.onColorsChanged();
          },
        ),
      ),
    );
  }

  void _showDesignCustomizer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DesignCustomizerScreen(
          onDesignChanged: () {
            setState(() {});
            widget.onColorsChanged();
          },
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignConfig.borderRadius + 4),
        ),
        title: Text('Escolha o tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.light_mode_rounded, color: AppColors.primary),
              title: Text('☀️ Claro'),
              onTap: () {
                setState(() => _currentTheme = 'light');
                widget.onThemeChanged('light');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode_rounded, color: AppColors.primary),
              title: Text('🌙 Escuro'),
              onTap: () {
                setState(() => _currentTheme = 'dark');
                widget.onThemeChanged('dark');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    AppBottomSheet.show(
      context,
      height: 300,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(text: 'Escolha o idioma', fontSize: 18),
            SizedBox(height: 24),
            _buildLanguageOption('🇵🇹', 'Português', 'pt'),
            SizedBox(height: 12),
            _buildLanguageOption('🇺🇸', 'English', 'en'),
            SizedBox(height: 12),
            _buildLanguageOption('🇪🇸', 'Español', 'es'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String name, String code) {
    final isSelected = _currentLocale == code;
    return InkWell(
      onTap: () {
        setState(() => _currentLocale = code);
        widget.onLanguageChanged(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDesignConfig.borderRadius),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
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
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(text: 'Estilo do Cartão', fontSize: 18),
            SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                physics: BouncingScrollPhysics(),
                children: [
                  _buildStyleOption('modern', 'Moderno', Icons.credit_card),
                  _buildStyleOption('gradient', 'Gradiente', Icons.gradient),
                  _buildStyleOption('minimal', 'Minimalista', Icons.rectangle_outlined),
                  _buildStyleOption('glass', 'Vidro', Icons.auto_awesome),
                ],
              ),
            ),
            SizedBox(height: 16),
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
        setState(() => _currentCardStyle = style);
        widget.onCardStyleChanged(style);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
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
              padding: EdgeInsets.all(16),
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
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 4),
              Icon(Icons.check_circle, size: 16, color: AppColors.primary),
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

/// Tela de seleção de cores
class ColorPickerScreen extends StatelessWidget {
  final Function(String) onColorSelected;

  const ColorPickerScreen({
    required this.onColorSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(title: 'Escolher Cor'),
      body: GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: AppColors.colorPalette.length,
        itemBuilder: (context, index) {
          final entry = AppColors.colorPalette.entries.elementAt(index);
          final colorKey = entry.key;
          final colorScheme = entry.value;

          return _buildColorOption(
            context,
            colorKey,
            colorScheme,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    String colorKey,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        onColorSelected(colorKey);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              colorScheme.emoji,
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 12),
            Text(
              colorScheme.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de personalização de design
class DesignCustomizerScreen extends StatefulWidget {
  final VoidCallback onDesignChanged;

  const DesignCustomizerScreen({
    required this.onDesignChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<DesignCustomizerScreen> createState() => _DesignCustomizerScreenState();
}

class _DesignCustomizerScreenState extends State<DesignCustomizerScreen> {
  double _borderRadius = AppDesignConfig.borderRadius;
  double _cardRadius = AppDesignConfig.cardRadius;
  double _buttonRadius = AppDesignConfig.buttonRadius;
  double _buttonHeight = AppDesignConfig.buttonHeight;
  double _spacing = AppDesignConfig.spacing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(title: 'Personalizar Design'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(text: 'Bordas Arredondadas', fontSize: 18),
            SizedBox(height: 16),
            _buildSlider(
              label: 'Campos de texto',
              value: _borderRadius,
              min: 0,
              max: 30,
              onChanged: (v) {
                setState(() => _borderRadius = v);
                AppDesignConfig.setBorderRadius(v);
                widget.onDesignChanged();
              },
            ),
            _buildSlider(
              label: 'Cards',
              value: _cardRadius,
              min: 0,
              max: 30,
              onChanged: (v) {
                setState(() => _cardRadius = v);
                AppDesignConfig.setCardRadius(v);
                widget.onDesignChanged();
              },
            ),
            _buildSlider(
              label: 'Botões',
              value: _buttonRadius,
              min: 0,
              max: 30,
              onChanged: (v) {
                setState(() => _buttonRadius = v);
                AppDesignConfig.setButtonRadius(v);
                widget.onDesignChanged();
              },
            ),
            SizedBox(height: 24),
            AppSectionTitle(text: 'Tamanhos', fontSize: 18),
            SizedBox(height: 16),
            _buildSlider(
              label: 'Altura dos botões',
              value: _buttonHeight,
              min: 40,
              max: 70,
              onChanged: (v) {
                setState(() => _buttonHeight = v);
                AppDesignConfig.setButtonHeight(v);
                widget.onDesignChanged();
              },
            ),
            _buildSlider(
              label: 'Espaçamento',
              value: _spacing,
              min: 8,
              max: 32,
              onChanged: (v) {
                setState(() => _spacing = v);
                AppDesignConfig.setSpacing(v);
                widget.onDesignChanged();
              },
            ),
            SizedBox(height: 32),
            AppSectionTitle(text: 'Pré-visualização', fontSize: 18),
            SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card de exemplo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  AppTextField(hintText: 'Campo de texto'),
                  SizedBox(height: 12),
                  AppPrimaryButton(text: 'Botão de exemplo', onPressed: () {}),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    text: 'Restaurar Padrões',
                    onPressed: () {
                      setState(() {
                        AppDesignConfig.resetToDefaults();
                        _borderRadius = AppDesignConfig.borderRadius;
                        _cardRadius = AppDesignConfig.cardRadius;
                        _buttonRadius = AppDesignConfig.buttonRadius;
                        _buttonHeight = AppDesignConfig.buttonHeight;
                        _spacing = AppDesignConfig.spacing;
                      });
                      widget.onDesignChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${value.toInt()}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}