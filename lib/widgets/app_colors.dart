// lib/widgets/app_colors.dart
import 'package:flutter/material.dart';

/// Sistema de cores dinâmico do aplicativo
class AppColors {
  // Cor primária atual (pode ser alterada dinamicamente)
  static Color _primary = const Color(0xFF0066FF);
  static Color get primary => _primary;
  
  static Color get primaryLight => _lighten(_primary, 0.2);
  static Color get primaryDark => _darken(_primary, 0.2);

  // Backgrounds
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE8E8E8);

  // Separadores
  static const Color separator = Color(0xFFE8E8E8);
  static const Color darkSeparator = Color(0xFF2A2A2A);

  // Accent colors fixos
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  /// Paleta de cores pré-definidas vibrantes
  static final Map<String, ColorScheme> colorPalette = {
    'blue': ColorScheme(
      name: 'Azul Vibrante',
      primary: Color(0xFF0066FF),
      icon: Icons.water_drop_rounded,
      emoji: '💙',
    ),
    'red': ColorScheme(
      name: 'Vermelho Intenso',
      primary: Color(0xFFFF3B30),
      icon: Icons.local_fire_department,
      emoji: '❤️',
    ),
    'orange': ColorScheme(
      name: 'Laranja Forte',
      primary: Color(0xFFFF9500),
      icon: Icons.wb_sunny_rounded,
      emoji: '🧡',
    ),
    'purple': ColorScheme(
      name: 'Roxo Místico',
      primary: Color(0xFF9C27B0),
      icon: Icons.auto_awesome,
      emoji: '💜',
    ),
    'pink': ColorScheme(
      name: 'Rosa Vibrante',
      primary: Color(0xFFE91E63),
      icon: Icons.favorite_rounded,
      emoji: '💕',
    ),
    'green': ColorScheme(
      name: 'Verde Neon',
      primary: Color(0xFF00E676),
      icon: Icons.eco_rounded,
      emoji: '💚',
    ),
    'cyan': ColorScheme(
      name: 'Ciano Elétrico',
      primary: Color(0xFF00BCD4),
      icon: Icons.waves_rounded,
      emoji: '💎',
    ),
    'yellow': ColorScheme(
      name: 'Amarelo Brilhante',
      primary: Color(0xFFFFEB3B),
      icon: Icons.star_rounded,
      emoji: '💛',
    ),
    'indigo': ColorScheme(
      name: 'Índigo Profundo',
      primary: Color(0xFF3F51B5),
      icon: Icons.nights_stay_rounded,
      emoji: '🌌',
    ),
    'teal': ColorScheme(
      name: 'Turquesa Tropical',
      primary: Color(0xFF009688),
      icon: Icons.beach_access_rounded,
      emoji: '🌊',
    ),
    'lime': ColorScheme(
      name: 'Lima Ácido',
      primary: Color(0xFFCDDC39),
      icon: Icons.lightbulb_rounded,
      emoji: '🍋',
    ),
    'deepOrange': ColorScheme(
      name: 'Laranja Queimado',
      primary: Color(0xFFFF5722),
      icon: Icons.whatshot_rounded,
      emoji: '🔥',
    ),
    'neutral': ColorScheme(
      name: 'Neutro P&B',
      primary: Color(0xFF424242),
      icon: Icons.circle_outlined,
      emoji: '⚫',
    ),
  };

  /// Atualiza a cor primária
  static void setPrimaryColor(Color color) {
    _primary = color;
  }

  /// Atualiza cor primária por nome do esquema
  static void setColorScheme(String schemeName) {
    if (colorPalette.containsKey(schemeName)) {
      _primary = colorPalette[schemeName]!.primary;
    }
  }

  /// Obtém cor mais clara
  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Obtém cor mais escura
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Modelo de esquema de cor
class ColorScheme {
  final String name;
  final Color primary;
  final IconData icon;
  final String emoji;

  ColorScheme({
    required this.name,
    required this.primary,
    required this.icon,
    required this.emoji,
  });
}

/// Configurações de design personalizáveis
class AppDesignConfig {
  // Border radius
  static double _borderRadius = 12.0;
  static double get borderRadius => _borderRadius;
  
  static double _cardRadius = 16.0;
  static double get cardRadius => _cardRadius;

  static double _buttonRadius = 12.0;
  static double get buttonRadius => _buttonRadius;

  // Tamanhos
  static double _buttonHeight = 50.0;
  static double get buttonHeight => _buttonHeight;

  static double _inputHeight = 48.0;
  static double get inputHeight => _inputHeight;

  // Espaçamentos
  static double _spacing = 16.0;
  static double get spacing => _spacing;

  // Atualizar configurações
  static void setBorderRadius(double value) {
    _borderRadius = value.clamp(0.0, 30.0);
  }

  static void setCardRadius(double value) {
    _cardRadius = value.clamp(0.0, 30.0);
  }

  static void setButtonRadius(double value) {
    _buttonRadius = value.clamp(0.0, 30.0);
  }

  static void setButtonHeight(double value) {
    _buttonHeight = value.clamp(40.0, 70.0);
  }

  static void setInputHeight(double value) {
    _inputHeight = value.clamp(40.0, 70.0);
  }

  static void setSpacing(double value) {
    _spacing = value.clamp(8.0, 32.0);
  }

  // Reset para padrões
  static void resetToDefaults() {
    _borderRadius = 12.0;
    _cardRadius = 16.0;
    _buttonRadius = 12.0;
    _buttonHeight = 50.0;
    _inputHeight = 48.0;
    _spacing = 16.0;
  }
}