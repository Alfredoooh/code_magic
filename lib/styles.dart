// styles.dart - MATERIAL DESIGN 3 EXPRESSIVE COMPLETE SYSTEM
// Based on official Material Design 3 guidelines and research
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================
// THEME MODE CONTROLLER
// ============================================
class AppTheme {
  static bool _isDark = true;

  static bool get isDark => _isDark;

  static void toggleTheme() {
    _isDark = !_isDark;
  }

  static ThemeData get theme => _isDark ? darkTheme : lightTheme;
}

// ============================================
// COLOR SYSTEM - M3 EXPRESSIVE
// ============================================
class AppColors {
  // DARK THEME COLORS
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkSurfaceContainer = Color(0xFF1C1C1E);
  static const darkSurfaceContainerHigh = Color(0xFF2C2C2E);

  // LIGHT THEME COLORS
  static const lightBackground = Color(0xFFFFFBFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightSurfaceContainer = Color(0xFFF8F8F8);
  static const lightSurfaceContainerHigh = Color(0xFFEEEEEE);

  // PRIMARY COLORS (consistent across themes)
  static const primary = Color(0xFF0066FF);
  static const primaryContainer = Color(0xFF1A3D7A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFD4E3FF);

  // SECONDARY COLORS
  static const secondary = Color(0xFF006494);
  static const secondaryContainer = Color(0xFFCAE6FF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF001D31);

  // TERTIARY COLORS
  static const tertiary = Color(0xFF7D5260);
  static const tertiaryContainer = Color(0xFFFFD8E4);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF31111D);

  // STATUS COLORS
  static const success = Color(0xFF00C896);
  static const successContainer = Color(0xFF003826);
  static const error = Color(0xFFFF4444);
  static const errorContainer = Color(0xFF93000A);
  static const warning = Color(0xFFFF9500);
  static const warningContainer = Color(0xFF4E2F00);
  static const info = Color(0xFF2196F3);
  static const infoContainer = Color(0xFF003258);

  // TEXT COLORS - DARK
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB3B3B3);
  static const darkTextTertiary = Color(0xFF666666);
  static const darkTextDisabled = Color(0xFF444444);

  // TEXT COLORS - LIGHT
  static const lightTextPrimary = Color(0xFF1C1B1F);
  static const lightTextSecondary = Color(0xFF49454F);
  static const lightTextTertiary = Color(0xFF79747E);
  static const lightTextDisabled = Color(0xFFB3B3B3);

  // OUTLINE COLORS
  static final Color darkOutline = Colors.white.withOpacity(0.12);
  static final Color darkOutlineVariant = Colors.white.withOpacity(0.08);
  static final Color lightOutline = Colors.black.withOpacity(0.12);
  static final Color lightOutlineVariant = Colors.black.withOpacity(0.08);

  // SCRIM & OVERLAY
  static Color scrim = Colors.black.withOpacity(0.32);
  static Color darkOverlay = Colors.white.withOpacity(0.05);
  static Color lightOverlay = Colors.black.withOpacity(0.05);
}

// ============================================
// TYPOGRAPHY - M3 EXPRESSIVE TYPE SCALE
// Based on Roboto with adaptive scaling
// ============================================
class AppTypography {
  // Font Family
  static const fontFamily = 'Roboto';

  // DISPLAY - Large, prominent text
  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // HEADLINE - High-emphasis text
  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  static const headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  // TITLE - Medium-emphasis text
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.27,
  );

  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // BODY - Standard reading text
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // LABEL - Small, functional text
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}

// ============================================
// SPACING SYSTEM - 4dp grid
// ============================================
class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const massive = 48.0;
}

// ============================================
// SHAPE SYSTEM - M3 rounded corners
// ============================================
class AppShapes {
  static const none = 0.0;
  static const extraSmall = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 28.0;
  static const full = 9999.0;

  // Shape styles
  static RoundedRectangleBorder shapeNone = const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  );

  static RoundedRectangleBorder shapeExtraSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(extraSmall),
  );

  static RoundedRectangleBorder shapeSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(small),
  );

  static RoundedRectangleBorder shapeMedium = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(medium),
  );

  static RoundedRectangleBorder shapeLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(large),
  );

  static RoundedRectangleBorder shapeExtraLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(extraLarge),
  );

  static RoundedRectangleBorder shapeFull = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(full),
  );
}

// ============================================
// ELEVATION SYSTEM
// ============================================
class AppElevation {
  static const level0 = 0.0;
  static const level1 = 1.0;
  static const level2 = 3.0;
  static const level3 = 6.0;
  static const level4 = 8.0;
  static const level5 = 12.0;
}

// ============================================
// MOTION SYSTEM - Physics-based animations
// Based on M3 Expressive motion guidelines
// ============================================
class AppMotion {
  // DURATION - Adaptive timing
  static const instant = Duration(milliseconds: 0);
  static const veryShort = Duration(milliseconds: 50);
  static const short = Duration(milliseconds: 100);
  static const medium = Duration(milliseconds: 200);
  static const long = Duration(milliseconds: 300);
  static const veryLong = Duration(milliseconds: 400);
  static const extraLong = Duration(milliseconds: 500);

  // EASING CURVES - M3 emphasized curves
  static const standardEasing = Curves.easeInOutCubicEmphasized;
  static const emphasizedDecelerate = Curves.easeOutCubic;
  static const emphasizedAccelerate = Curves.easeInCubic;
  static const linear = Curves.linear;

  // SPRING CONFIGURATIONS
  static const fastSpring = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 20.0,
  );

  static const mediumSpring = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 15.0,
  );

  static const slowSpring = SpringDescription(
    mass: 1.0,
    stiffness: 50.0,
    damping: 10.0,
  );
}

// ============================================
// STATE LAYER OPACITIES
// ============================================
class AppStateOpacity {
  static const hover = 0.08;
  static const focus = 0.12;
  static const press = 0.12;
  static const drag = 0.16;
  static const disabled = 0.38;
}

// ============================================
// COMPLETE DARK THEME
// ============================================
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onPrimaryContainer,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightTextPrimary,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  ),

  scaffoldBackgroundColor: AppColors.darkBackground,

  textTheme: TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkTextTertiary),
  ),

  // Component themes with M3 styling
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
    iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),

  cardTheme: CardTheme(
    color: AppColors.darkSurfaceContainer,
    elevation: AppElevation.level1,
    shape: AppShapes.shapeMedium,
    margin: const EdgeInsets.all(AppSpacing.xs),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: AppElevation.level1,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurfaceVariant,
    selectedColor: AppColors.primary,
    labelStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    shape: AppShapes.shapeSmall,
  ),

  dialogTheme: DialogTheme(
    backgroundColor: AppColors.lightSurfaceContainerHigh,
    shape: AppShapes.shapeExtraLarge,
    elevation: AppElevation.level3,
    titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.lightSurfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
    ),
    elevation: AppElevation.level1,
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.lightSurfaceContainerHigh,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    shape: AppShapes.shapeMedium,
    elevation: AppElevation.level3,
    behavior: SnackBarBehavior.floating,
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.lightOutlineVariant,
    thickness: 1,
    space: 1,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.onPrimary;
      }
      return AppColors.lightTextTertiary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.lightSurfaceVariant;
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.onPrimary),
    shape: AppShapes.shapeExtraSmall,
  ),

  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.lightTextSecondary;
    }),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.lightSurfaceVariant,
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withOpacity(0.12),
    valueIndicatorColor: AppColors.primary,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.lightSurfaceVariant,
    circularTrackColor: AppColors.lightSurfaceVariant,
  ),

  tabBarTheme: TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.lightTextSecondary,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: AppTypography.titleSmall,
    unselectedLabelStyle: AppTypography.titleSmall,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.lightTextSecondary,
    elevation: AppElevation.level2,
    type: BottomNavigationBarType.fixed,
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedIconTheme: IconThemeData(color: AppColors.primary),
    unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
    selectedLabelTextStyle: AppTypography.labelMedium,
    unselectedLabelTextStyle: AppTypography.labelMedium,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: AppElevation.level3,
    highlightElevation: AppElevation.level4,
  ),

  iconTheme: const IconThemeData(
    color: AppColors.lightTextPrimary,
    size: 24,
  ),
);

// ============================================
// ANIMATED COMPONENTS WITH M3 MOTION
// ============================================

// Animated Card with spring physics
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.short,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.standardEasing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Animated Button with ripple effect
class AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const AnimatedPrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.loading = false,
  }) : super(key: key);

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.veryShort,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.loading && widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FilledButton(
          onPressed: widget.loading ? null : widget.onPressed,
          child: widget.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(widget.text),
                  ],
                ),
        ),
      ),
    );
  }
}

// Fade-in component
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInWidget({
    Key? key,
    required this.child,
    this.duration = AppMotion.medium,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedDecelerate),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedDecelerate),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// List item with staggered animation
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const StaggeredListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      delay: delay * index,
      duration: AppMotion.medium,
      child: child,
    );
  }
}

// Skeleton loader
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final highlightColor = isDark 
        ? AppColors.darkSurfaceContainerHigh 
        : AppColors.lightSurfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(AppShapes.small),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// Badge component
class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool outlined;

  const AppBadge({
    Key? key,
    required this.text,
    this.color,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : badgeColor.withOpacity(0.15),
        border: outlined ? Border.all(color: badgeColor, width: 1) : null,
        borderRadius: BorderRadius.circular(AppShapes.full),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Divider with label
class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerTheme.color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: theme.textTheme.labelSmall,
          ),
        ),
        Expanded(child: Divider(color: theme.dividerTheme.color)),
      ],
    );
  }
}

// Info card with icon
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? AppColors.primary;

    return AnimatedCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppShapes.medium),
            ),
            child: Icon(icon, color: cardColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
        ],
      ),
    );
  }
}

// Empty state with action
class EmptyStateWithAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWithAction({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Haptic Feedback Helper
class AppHaptics {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void error() {
    HapticFeedback.vibrate();
  }
}

// Snackbar Helper
class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: AppColors.warning,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.info,
    );
  }
}: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.darkOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.darkOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextTertiary),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.darkSurfaceVariant,
    selectedColor: AppColors.primary,
    labelStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    shape: AppShapes.shapeSmall,
  ),

  dialogTheme: DialogTheme(
    backgroundColor: AppColors.darkSurfaceContainerHigh,
    shape: AppShapes.shapeExtraLarge,
    elevation: AppElevation.level3,
    titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.darkSurfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
    ),
    elevation: AppElevation.level1,
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.darkSurfaceContainerHigh,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
    shape: AppShapes.shapeMedium,
    elevation: AppElevation.level3,
    behavior: SnackBarBehavior.floating,
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.darkOutlineVariant,
    thickness: 1,
    space: 1,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.onPrimary;
      }
      return AppColors.darkTextTertiary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.darkSurfaceVariant;
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.onPrimary),
    shape: AppShapes.shapeExtraSmall,
  ),

  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.darkTextSecondary;
    }),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.darkSurfaceVariant,
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withOpacity(0.12),
    valueIndicatorColor: AppColors.primary,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.darkSurfaceVariant,
    circularTrackColor: AppColors.darkSurfaceVariant,
  ),

  tabBarTheme: TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.darkTextSecondary,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: AppTypography.titleSmall,
    unselectedLabelStyle: AppTypography.titleSmall,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.darkTextSecondary,
    elevation: AppElevation.level2,
    type: BottomNavigationBarType.fixed,
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: AppColors.darkSurface,
    selectedIconTheme: IconThemeData(color: AppColors.primary),
    unselectedIconTheme: IconThemeData(color: AppColors.darkTextSecondary),
    selectedLabelTextStyle: AppTypography.labelMedium,
    unselectedLabelTextStyle: AppTypography.labelMedium,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: AppElevation.level3,
    highlightElevation: AppElevation.level4,
  ),

  iconTheme: const IconThemeData(
    color: AppColors.darkTextPrimary,
    size: 24,
  ),
);

// ============================================
// COMPLETE LIGHT THEME
// ============================================
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.onPrimaryContainer,
    onPrimaryContainer: AppColors.primaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onPrimaryContainer,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: Colors.black,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkTextPrimary,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  ),

  scaffoldBackgroundColor: AppColors.lightBackground,

  textTheme: TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.lightTextPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.lightTextPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.lightTextPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.lightTextPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.lightTextPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.lightTextPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.lightTextPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.lightTextTertiary),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.lightSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
    iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),

  cardTheme: CardTheme(
    color: AppColors.lightSurfaceContainer,
    elevation: AppElevation.level1,
    shape: AppShapes.shapeMedium,
    margin: const EdgeInsets.all(AppSpacing.xs),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: AppElevation.level1,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  // CONTINUAÇÃO DO styles.dart - COLE ISTO APÓS O filledButtonTheme DO LIGHT THEME

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: AppShapes.shapeLarge,
      textStyle: AppTypography.labelLarge,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: BorderSide(color: AppColors.lightOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppShapes.small),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.lightSurfaceVariant,
    selectedColor: AppColors.primary,
    labelStyle: AppTypography.labelLarge,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    shape: AppShapes.shapeSmall,
  ),

  dialogTheme: DialogTheme(
    backgroundColor: AppColors.lightSurfaceContainerHigh,
    shape: AppShapes.shapeExtraLarge,
    elevation: AppElevation.level3,
    titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: AppColors.lightSurfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
    ),
    elevation: AppElevation.level1,
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.lightSurfaceContainerHigh,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    shape: AppShapes.shapeMedium,
    elevation: AppElevation.level3,
    behavior: SnackBarBehavior.floating,
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.lightOutlineVariant,
    thickness: 1,
    space: 1,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.onPrimary;
      }
      return AppColors.lightTextTertiary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.lightSurfaceVariant;
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.onPrimary),
    shape: AppShapes.shapeExtraSmall,
  ),

  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.lightTextSecondary;
    }),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.lightSurfaceVariant,
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withOpacity(0.12),
    valueIndicatorColor: AppColors.primary,
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.lightSurfaceVariant,
    circularTrackColor: AppColors.lightSurfaceVariant,
  ),

  tabBarTheme: TabBarTheme(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.lightTextSecondary,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: AppTypography.titleSmall,
    unselectedLabelStyle: AppTypography.titleSmall,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.lightTextSecondary,
    elevation: AppElevation.level2,
    type: BottomNavigationBarType.fixed,
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: AppColors.lightSurface,
    selectedIconTheme: IconThemeData(color: AppColors.primary),
    unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
    selectedLabelTextStyle: AppTypography.labelMedium,
    unselectedLabelTextStyle: AppTypography.labelMedium,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: AppElevation.level3,
    highlightElevation: AppElevation.level4,
  ),

  iconTheme: const IconThemeData(
    color: AppColors.lightTextPrimary,
    size: 24,
  ),

  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    shape: AppShapes.shapeMedium,
    tileColor: Colors.transparent,
    selectedTileColor: AppColors.primary.withOpacity(0.08),
  ),

  expansionTileTheme: ExpansionTileThemeData(
    backgroundColor: Colors.transparent,
    collapsedBackgroundColor: Colors.transparent,
    textColor: AppColors.lightTextPrimary,
    iconColor: AppColors.lightTextSecondary,
    collapsedTextColor: AppColors.lightTextPrimary,
    collapsedIconColor: AppColors.lightTextSecondary,
    shape: AppShapes.shapeMedium,
  ),

  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.lightTextPrimary.withOpacity(0.9),
      borderRadius: BorderRadius.circular(AppShapes.small),
    ),
    textStyle: AppTypography.bodySmall.copyWith(color: AppColors.lightSurface),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.lightSurfaceContainer,
    elevation: AppElevation.level2,
    shape: AppShapes.shapeMedium,
    textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
  ),

  drawerTheme: DrawerThemeData(
    backgroundColor: AppColors.lightSurface,
    elevation: AppElevation.level1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(AppShapes.large)),
    ),
  ),

  timePickerTheme: TimePickerThemeData(
    backgroundColor: AppColors.lightSurfaceContainer,
    dialBackgroundColor: AppColors.lightSurfaceVariant,
    dialHandColor: AppColors.primary,
    hourMinuteColor: AppColors.lightSurfaceVariant,
    hourMinuteTextColor: AppColors.lightTextPrimary,
    dayPeriodColor: AppColors.primary.withOpacity(0.12),
    dayPeriodTextColor: AppColors.primary,
    shape: AppShapes.shapeExtraLarge,
  ),

  datePickerTheme: DatePickerThemeData(
    backgroundColor: AppColors.lightSurfaceContainer,
    headerBackgroundColor: AppColors.primary,
    headerForegroundColor: AppColors.onPrimary,
    weekdayStyle: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
    dayStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
    shape: AppShapes.shapeExtraLarge,
  ),

  bannerTheme: MaterialBannerThemeData(
    backgroundColor: AppColors.lightSurfaceVariant,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
  ),

  dataTableTheme: DataTableThemeData(
    decoration: BoxDecoration(
      color: AppColors.lightSurfaceContainer,
      borderRadius: BorderRadius.circular(AppShapes.medium),
    ),
    headingTextStyle: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
    dataTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
  ),
);

// ============================================
// UTILITÁRIOS DE TEMA
// ============================================

// Theme Mode Provider - Use com Provider ou Riverpod
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Salvar preferência
  Future<void> saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode.toString());
  }

  // Carregar preferência
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null) {
      _themeMode = saved.contains('dark') ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}

// Helper para acessar cores do tema atual
extension ThemeExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Atalhos úteis
  Color get surface => colors.surface;
  Color get primary => colors.primary;
  Color get error => colors.error;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
}

// ============================================
// COMPONENTES ADICIONAIS M3
// ============================================

// Segmented Button personalizado
class SegmentedButtonGroup<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final Function(T) onChanged;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;

  const SegmentedButtonGroup({
    Key? key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
    this.iconBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((value) {
        final isSelected = value == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onChanged(value);
                },
                borderRadius: BorderRadius.circular(AppShapes.small),
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  curve: AppMotion.standardEasing,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? context.primary.withOpacity(0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? context.primary 
                          : context.colors.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppShapes.small),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconBuilder != null) ...[
                        Icon(
                          iconBuilder!(value),
                          size: 18,
                          color: isSelected 
                              ? context.primary 
                              : context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        labelBuilder(value),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: isSelected 
                              ? context.primary 
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Stats Card component
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? context.primary;

    return AnimatedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppShapes.small),
                ),
                child: Icon(icon, color: cardColor, size: 20),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.colors.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: context.textStyles.headlineSmall?.copyWith(
              color: cardColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Transaction List Item
class TransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final VoidCallback? onTap;

  const TransactionListItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppShapes.medium),
                ),
                child: Icon(icon, color: color, size: 24),
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
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)}',
                style: context.textStyles.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Loading Overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.scrim,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          message!,
                          style: context.textStyles.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}