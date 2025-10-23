// routes.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';

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
        return MaterialPageRoute(
          builder: (context) => HomeScreen(token: token),
        );

      case trade:
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(
            builder: (context) => TradeScreen(token: args),
          );
        } else if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => TradeScreen(
              token: args['token'] as String,
              initialMarket: args['market'] as String?,
            ),
          );
        }
        return _errorRoute();

      case bots:
        final token = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => BotsScreen(token: token),
        );

      case portfolio:
        final token = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => PortfolioScreen(token: token),
        );

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Erro'),
        ),
        body: const Center(
          child: Text(
            'Página não encontrada',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}