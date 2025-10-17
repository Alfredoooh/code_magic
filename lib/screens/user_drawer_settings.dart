import 'package:flutter/cupertino.dart';

class UserDrawerSettings {
  static void showSettingsModal(
    BuildContext context, {
    required bool isDark,
    required String currentLocale,
    required String cardStyle,
    required Function(String) onThemeChanged,
    required Function(String) onLanguageChanged,
    required Function(String) onCardStyleChanged,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => _SettingsScreen(
          isDark: isDark,
          currentLocale: currentLocale,
          cardStyle: cardStyle,
          onThemeChanged: onThemeChanged,
          onLanguageChanged: onLanguageChanged,
          onCardStyleChanged: onCardStyleChanged,
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  final bool isDark;
  final String currentLocale;
  final String cardStyle;
  final Function(String) onThemeChanged;
  final Function(String) onLanguageChanged;
  final Function(String) onCardStyleChanged;

  const _SettingsScreen({
    required this.isDark,
    required this.currentLocale,
    required this.cardStyle,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onCardStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? const Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: const Color(0xFFFF444F),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Configurações',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingCard(
              context: context,
              icon: CupertinoIcons.moon_fill,
              title: 'Tema',
              subtitle: isDark ? 'Escuro' : 'Claro',
              onTap: () => _showThemeDialog(context, onThemeChanged, isDark),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              context: context,
              icon: CupertinoIcons.globe,
              title: 'Idioma',
              subtitle: _getLanguageName(currentLocale),
              onTap: () => _showLanguageDialog(context, onLanguageChanged, isDark),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildSettingCard(
              context: context,
              icon: CupertinoIcons.paintbrush_fill,
              title: 'Estilo do Cartão',
              subtitle: _getCardStyleName(cardStyle),
              onTap: () => _showCardStylePicker(context, cardStyle, onCardStyleChanged, isDark),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF444F),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static void _showThemeDialog(
    BuildContext context,
    Function(String) onThemeChanged,
    bool isDark,
  ) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: CupertinoColors.black.withOpacity(0.3),
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Escolha o tema',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.sun_max_fill,
                  color: const Color(0xFFFF444F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Claro',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onPressed: () {
              onThemeChanged('light');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.moon_fill,
                  color: const Color(0xFFFF444F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Escuro',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onPressed: () {
              onThemeChanged('dark');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  static void _showLanguageDialog(
    BuildContext context,
    Function(String) onLanguageChanged,
    bool isDark,
  ) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: CupertinoColors.black.withOpacity(0.3),
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Escolha o idioma',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🇵🇹', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Português',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onPressed: () {
              onLanguageChanged('pt');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🇺🇸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onPressed: () {
              onLanguageChanged('en');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🇪🇸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Español',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onPressed: () {
              onLanguageChanged('es');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  static void _showCardStylePicker(
    BuildContext context,
    String currentCardStyle,
    Function(String) onCardStyleChanged,
    bool isDark,
  ) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: CupertinoColors.black.withOpacity(0.3),
      builder: (context) => Container(
        height: 440,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estilo do Cartão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildStyleOption(
                    context: context,
                    style: 'modern',
                    name: 'Moderno',
                    icon: CupertinoIcons.creditcard_fill,
                    currentCardStyle: currentCardStyle,
                    onCardStyleChanged: onCardStyleChanged,
                    isDark: isDark,
                  ),
                  _buildStyleOption(
                    context: context,
                    style: 'gradient',
                    name: 'Gradiente',
                    icon: CupertinoIcons.color_filter,
                    currentCardStyle: currentCardStyle,
                    onCardStyleChanged: onCardStyleChanged,
                    isDark: isDark,
                  ),
                  _buildStyleOption(
                    context: context,
                    style: 'minimal',
                    name: 'Minimalista',
                    icon: CupertinoIcons.rectangle,
                    currentCardStyle: currentCardStyle,
                    onCardStyleChanged: onCardStyleChanged,
                    isDark: isDark,
                  ),
                  _buildStyleOption(
                    context: context,
                    style: 'glass',
                    name: 'Vidro',
                    icon: CupertinoIcons.sparkles,
                    currentCardStyle: currentCardStyle,
                    onCardStyleChanged: onCardStyleChanged,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                color: const Color(0xFFFF444F),
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Concluído',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStyleOption({
    required BuildContext context,
    required String style,
    required String name,
    required IconData icon,
    required String currentCardStyle,
    required Function(String) onCardStyleChanged,
    required bool isDark,
  }) {
    final selected = currentCardStyle == style;
    return GestureDetector(
      onTap: () {
        onCardStyleChanged(style);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF444F).withOpacity(0.1)
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFFF444F) : (isDark ? const Color(0xFF3C3C3E) : const Color(0xFFE5E5EA)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF444F).withOpacity(0.15)
                    : (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 36,
                color: selected ? const Color(0xFFFF444F) : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected
                    ? const Color(0xFFFF444F)
                    : (isDark ? CupertinoColors.white : CupertinoColors.black),
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 16,
                color: const Color(0xFFFF444F),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _getLanguageName(String code) {
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

  static String _getCardStyleName(String style) {
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