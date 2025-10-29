// routes.dart - Material Design 3
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class AppRoutes {
  // Route names
  static const String login = '/';
  static const String home = '/home';
  static const String trade = '/trade';
  static const String bots = '/bots';
  static const String portfolio = '/portfolio';
  static const String settings = '/settings';

  // Get initial routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const DerivLoginScreen(),
    };
  }

  // Generate routes dynamically
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final token = settings.arguments as String;
        return _buildRoute(
          builder: (context) => HomeScreen(token: token),
          settings: settings,
        );

      case trade:
        final args = settings.arguments;
        if (args is String) {
          return _buildRoute(
            builder: (context) => TradeScreen(token: args),
            settings: settings,
          );
        } else if (args is Map<String, dynamic>) {
          return _buildRoute(
            builder: (context) => TradeScreen(
              token: args['token'] as String,
              initialMarket: args['market'] as String?,
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case bots:
        final token = settings.arguments as String;
        return _buildRoute(
          builder: (context) => BotsScreen(token: token),
          settings: settings,
        );

      case portfolio:
        final token = settings.arguments as String;
        return _buildRoute(
          builder: (context) => PortfolioScreen(token: token),
          settings: settings,
        );

      default:
        return _errorRoute(settings);
    }
  }

  // Build route with Material Design 3 transitions
  static Route<T> _buildRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      fullscreenDialog: fullscreenDialog,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Material 3 Shared Axis Transition (horizontal)
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: AppMotion.emphasizedDecelerate),
        );
        final offsetAnimation = animation.drive(tween);

        // Fade transition for the exiting screen
        final fadeOutTween = Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: AppMotion.emphasizedAccelerate),
        );
        final fadeOutAnimation = secondaryAnimation.drive(fadeOutTween);

        // Fade transition for the entering screen
        final fadeInTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: AppMotion.emphasizedDecelerate),
        );
        final fadeInAnimation = animation.drive(fadeInTween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeInAnimation,
            child: FadeTransition(
              opacity: fadeOutAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  // Fade transition for modals and overlays
  static Route<T> _buildFadeRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool fullscreenDialog = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      fullscreenDialog: fullscreenDialog,
      transitionDuration: AppMotion.short,
      reverseTransitionDuration: AppMotion.short,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        );
        final fadeAnimation = animation.drive(fadeTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }

  // Scale transition for dialogs
  static Route<T> _buildScaleRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    bool fullscreenDialog = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      fullscreenDialog: fullscreenDialog,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.short,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: AppMotion.emphasizedDecelerate),
        );
        final scaleAnimation = animation.drive(scaleTween);

        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        );
        final fadeAnimation = animation.drive(fadeTween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // Bottom sheet transition
  static Route<T> _buildBottomSheetRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      fullscreenDialog: true,
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: AppMotion.emphasizedDecelerate),
        );
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  // Error route with Material Design 3 styling
  static Route<T> _errorRoute<T>(RouteSettings settings) {
    return _buildFadeRoute<T>(
      settings: settings,
      builder: (context) => Scaffold(
        backgroundColor: context.surface,
        appBar: SecondaryAppBar(
          title: 'Error',
          onBack: () => Navigator.of(context).pop(),
        ),
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Page Not Found',
          subtitle: 'The page you are looking for does not exist or has been moved.',
          actionText: 'Go Back',
          onAction: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // Helper method to navigate with arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.of(context).pushReplacementNamed<T, void>(
        routeName,
        arguments: arguments,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  // Navigate and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Navigate to home
  static Future<void> navigateToHome(BuildContext context, String token) {
    return navigateAndRemoveUntil(
      context,
      home,
      arguments: token,
    );
  }

  // Navigate to trade
  static Future<void> navigateToTrade(
    BuildContext context,
    String token, {
    String? market,
  }) {
    return navigateTo(
      context,
      trade,
      arguments: market != null
          ? {'token': token, 'market': market}
          : token,
    );
  }

  // Navigate to bots
  static Future<void> navigateToBots(BuildContext context, String token) {
    return navigateTo(
      context,
      bots,
      arguments: token,
    );
  }

  // Navigate to portfolio
  static Future<void> navigateToPortfolio(BuildContext context, String token) {
    return navigateTo(
      context,
      portfolio,
      arguments: token,
    );
  }

  // Show modal bottom sheet with route
  static Future<T?> showBottomSheetRoute<T>(
    BuildContext context,
    Widget child,
  ) {
    return Navigator.of(context).push<T>(
      _buildBottomSheetRoute<T>(
        builder: (context) => child,
        settings: const RouteSettings(name: 'bottom_sheet'),
      ),
    );
  }

  // Show dialog with route
  static Future<T?> showDialogRoute<T>(
    BuildContext context,
    Widget child,
  ) {
    return Navigator.of(context).push<T>(
      _buildScaleRoute<T>(
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: child,
        ),
        settings: const RouteSettings(name: 'dialog'),
      ),
    );
  }

  // Show full screen modal
  static Future<T?> showFullScreenModal<T>(
    BuildContext context,
    Widget child,
  ) {
    return Navigator.of(context).push<T>(
      _buildRoute<T>(
        builder: (context) => child,
        settings: const RouteSettings(name: 'modal'),
        fullscreenDialog: true,
      ),
    );
  }

  // Pop with result
  static void popWithResult<T>(BuildContext context, T result) {
    Navigator.of(context).pop<T>(result);
  }

  // Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  // Pop until route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(
      ModalRoute.withName(routeName),
    );
  }

  // Pop until home
  static void popUntilHome(BuildContext context) {
    popUntil(context, home);
  }
}

// Route observer for analytics and debugging
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('📍 Navigated to: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('📍 Popped from: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('📍 Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}

// Route transition types enum
enum TransitionType {
  slide,
  fade,
  scale,
  bottomSheet,
}

// Custom route builder with configurable transition
class CustomRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType type;
  final Duration duration;

  CustomRoute({
    required this.child,
    this.type = TransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case TransitionType.slide:
                return _slideTransition(animation, secondaryAnimation, child);
              case TransitionType.fade:
                return _fadeTransition(animation, child);
              case TransitionType.scale:
                return _scaleTransition(animation, child);
              case TransitionType.bottomSheet:
                return _bottomSheetTransition(animation, child);
            }
          },
        );

  static Widget _slideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: Curves.easeInOut),
    );
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  static Widget _fadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget _scaleTransition(Animation<double> animation, Widget child) {
    final scaleTween = Tween<double>(begin: 0.8, end: 1.0);
    final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }

  static Widget _bottomSheetTransition(
    Animation<double> animation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: Curves.easeOut),
    );
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}