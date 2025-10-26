// routes.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';
import 'styles.dart' hide EdgeInsets;

class AppRoutes {
  static const String login = '/';
  static const String home = '/home';
  static const String trade = '/trade';
  static const String bots = '/bots';
  static const String portfolio = '/portfolio';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const DerivLoginScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final token = settings.arguments as String;
        return _buildIOSRoute(
          builder: (context) => HomeScreen(token: token),
        );

      case trade:
        final args = settings.arguments;
        if (args is String) {
          return _buildIOSRoute(
            builder: (context) => TradeScreen(token: args),
          );
        } else if (args is Map<String, dynamic>) {
          return _buildIOSRoute(
            builder: (context) => TradeScreen(
              token: args['token'] as String,
              initialMarket: args['market'] as String?,
            ),
          );
        }
        return _errorRoute();

      case bots:
        final token = settings.arguments as String;
        return _buildIOSRoute(
          builder: (context) => BotsScreen(token: token),
        );

      case portfolio:
        final token = settings.arguments as String;
        return _buildIOSRoute(
          builder: (context) => PortfolioScreen(token: token),
        );

      default:
        return _errorRoute();
    }
  }

  // Cria uma rota com transição de slide horizontal estilo iOS
  static Route<dynamic> _buildIOSRoute({
    required WidgetBuilder builder,
    bool fullscreenDialog = false,
  }) {
    return CupertinoPageRoute(
      builder: builder,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static Route<dynamic> _errorRoute() {
    return CupertinoPageRoute(
      builder: (context) => CupertinoPageScaffold(
        backgroundColor: context.colors.surface,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: context.colors.surfaceContainer,
          middle: Text(
            'Erro',
            style: context.textStyles.titleLarge,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: context.colors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Página não encontrada',
                style: context.textStyles.titleMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A página que você está procurando não existe',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}