// main.dart

// ========================================
// 🌐 VERSÃO WEB (ATIVA)
// ========================================
// Descomente as linhas abaixo para compilar para WEB
import 'package:flutter/material.dart';
import 'web/example.dart';

void main() {
  runApp(const WebTestApp());
}

// ========================================
// 📱 VERSÃO MOBILE (COMENTADA)
// ========================================
// Comente a versão WEB acima e descomente abaixo para compilar MOBILE
/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DerivTradingApp());
}

class DerivTradingApp extends StatelessWidget {
  const DerivTradingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deriv Trading',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
*/