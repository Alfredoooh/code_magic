// lib/widgets/app_ui_components.dart
import 'package:flutter/material.dart';

/// Cores do aplicativo - NOVO DESIGN
class AppColors {
  // Cor principal atualizada - Azul vibrante moderno
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryLight = Color(0xFF3D8BFF);
  static const Color primaryDark = Color(0xFF0052CC);
  
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
  
  // Accent colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);
}

/// AppBar Tipo 1 - Para telas principais
class AppPrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppPrimaryAppBar({
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              splashRadius: 20,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      actions: actions,
    );
  }
}

/// AppBar Tipo 2 - Para outras telas (secundárias)
class AppSecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const AppSecondaryAppBar({
    required this.title,
    this.actions,
    this.onBackPressed,
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        splashRadius: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      actions: actions,
    );
  }
}

/// TextField NOVO - Design minimalista e moderno
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final Function(String)? onChanged;
  final bool enabled;
  final VoidCallback? onTap;

  const AppTextField({
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused 
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.5,
        ),
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          readOnly: widget.onTap != null,
          onTap: widget.onTap,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}

/// TextField de senha com botão de visibilidade
class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;

  const AppPasswordField({
    this.controller,
    this.hintText,
    Key? key,
  }) : super(key: key);

  @override
  _AppPasswordFieldState createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.grey.shade500,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        splashRadius: 20,
      ),
    );
  }
}

/// Botão primário NOVO - Design moderno com gradiente
class AppPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const AppPrimaryButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 50,
    this.borderRadius = 12,
    Key? key,
  }) : super(key: key);

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isLoading 
                ? null
                : LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading ? Colors.grey : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.isLoading ? [] : [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        widget.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão secundário NOVO - Design minimalista
class AppSecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;

  const AppSecondaryButton({
    required this.text,
    this.onPressed,
    this.height = 50,
    this.borderRadius = 12,
    Key? key,
  }) : super(key: key);

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de conteúdo NOVO
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool elevated;

  const AppCard({
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.elevated = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Card de informação com ícone NOVO
class AppInfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final double borderRadius;

  const AppInfoCard({
    required this.icon,
    required this.text,
    this.borderRadius = 12,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção
class AppSectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  const AppSectionTitle({
    required this.text,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: -0.3,
      ),
    );
  }
}

/// Diálogos NOVOS
class AppDialogs {
  static void showError(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message, style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.pop(context);
              onClose?.call();
            },
          ),
        ],
      ),
    );
  }

  static void showConfirmation(
    BuildContext context,
    String title,
    String message, {
    required VoidCallback onConfirm,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message, style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            child: Text(cancelText, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              confirmText,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet NOVO
class AppBottomSheet {
  static void show(
    BuildContext context, {
    required Widget child,
    double height = 400,
    bool isDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Container com ícone circular NOVO
class AppIconCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppIconCircle({
    required this.icon,
    this.size = 56,
    this.backgroundColor,
    this.iconColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (iconColor ?? AppColors.primary).withOpacity(0.15),
            (iconColor ?? AppColors.primary).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

/// Label de campo NOVO
class AppFieldLabel extends StatelessWidget {
  final String text;

  const AppFieldLabel({
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}