import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';

const Color primaryBg = Color(0xFF0A0B0D);
const Color secondaryBg = Color(0xFF16171B);
const Color tertiaryBg = Color(0xFF1E1F25);
const Color accentPrimary = Color(0xFFAB9FF2);
const Color accentSecondary = Color(0xFF4F46E5);
const Color success = Color(0xFF10B981);
const Color danger = Color(0xFFEF4444);
const Color warning = Color(0xFFF59E0B);
const Color info = Color(0xFF3B82F6);
const Color textPrimary = Color(0xFFF9FAFB);
const Color textSecondary = Color(0xFF9CA3AF);
const Color textMuted = Color(0xFF6B7280);

final LinearGradient accentGradient = LinearGradient(
  colors: [accentSecondary, accentPrimary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: accentPrimary,
  scaffoldBackgroundColor: primaryBg,
  cardColor: secondaryBg,
  canvasColor: tertiaryBg,
  colorScheme: ColorScheme.dark(
    primary: accentPrimary,
    secondary: accentSecondary,
    error: danger,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
    labelSmall: TextStyle(fontSize: 12, color: textMuted),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentPrimary,
      foregroundColor: textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  cardTheme: CardThemeData(
    color: secondaryBg,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryBg,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: secondaryBg,
    selectedItemColor: accentPrimary,
    unselectedItemColor: textMuted,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: secondaryBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: accentPrimary,
  ),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: accentPrimary,
  scaffoldBackgroundColor: Colors.white,
  cardColor: Color(0xFFF3F4F6),
  canvasColor: Color(0xFFE5E7EB),
  colorScheme: ColorScheme.light(
    primary: accentPrimary,
    secondary: accentSecondary,
    error: danger,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
    labelSmall: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
  ),
);

final oledTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.black,
  cardColor: Color(0xFF0A0A0A),
);

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.isLoading = false,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BounceInDown(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? accentPrimary,
            foregroundColor: textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shadowColor: accentPrimary.withOpacity(0.5),
            elevation: 4,
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final int? maxLines;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: textSecondary),
          prefixIcon: Icon(icon, color: accentPrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: tertiaryBg),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: tertiaryBg),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentPrimary, width: 2),
          ),
          filled: true,
          fillColor: secondaryBg,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: danger, width: 2),
          ),
        ),
        style: const TextStyle(color: textPrimary),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines,
      ),
    );
  }
}

class SparklineChart extends StatelessWidget {
  final List<double> data;

  const SparklineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: success,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: success.withOpacity(0.1),
              ),
            ),
          ],
          minY: data.reduce((a, b) => a < b ? a : b) * 0.95,
          maxY: data.reduce((a, b) => a > b ? a : b) * 1.05,
        ),
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tertiaryBg),
            ),
            child: Icon(icon, color: accentPrimary, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 12)),
      ],
    );
  }
}

class CustomModal extends StatelessWidget {
  final Widget child;

  const CustomModal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      child: AlertDialog(
        backgroundColor: secondaryBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: child,
      ),
    );
  }
}

class CustomProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(color: accentPrimary);
  }
}

class CustomListTile extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;

  const CustomListTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInLeft(
      child: ListTile(
        leading: Icon(leadingIcon, color: accentPrimary),
        title: Text(title, style: const TextStyle(color: textPrimary)),
        onTap: onTap,
      ),
    );
  }
}

class CustomDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: textMuted, thickness: 1);
  }
}