import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoPageScaffold(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? const Color(0xFF000000) : CupertinoColors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          middle: const Text('Configurações'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.xmark),
            onPressed: () => Navigator.pop(context),
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
                subtitle: Theme.of(context).brightness == Brightness.dark ? 'Escuro' : 'Claro',
                onTap: () => _showThemeDialog(context, onThemeChanged),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context: context,
                icon: CupertinoIcons.globe,
                title: 'Idioma',
                subtitle: _getLanguageName(currentLocale),
                onTap: () => _showLanguageDialog(context, onLanguageChanged),
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFFF444F), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemGrey, size: 20),
          ],
        ),
      ),
    );
  }

  static void _showThemeDialog(BuildContext context, Function(String) onThemeChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Escolha o tema'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Claro'),
            onPressed: () {
              onThemeChanged('light');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Escuro'),
            onPressed: () {
              onThemeChanged('dark');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancelar'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  static void _showLanguageDialog(BuildContext context, Function(String) onLanguageChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Escolha o idioma'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Português'),
            onPressed: () {
              onLanguageChanged('pt');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('English'),
            onPressed: () {
              onLanguageChanged('en');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Español'),
            onPressed: () {
              onLanguageChanged('es');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancelar'),
          isDestructiveAction: true,
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
      builder: (context) => Container(
        height: 420,
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
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
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
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF444F).withOpacity(0.1)
              : (isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFF444F) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: selected ? const Color(0xFFFF444F) : CupertinoColors.systemGrey,
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