import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart';
import 'login_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'drawer_menu.dart';
import 'settings_screen.dart';

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
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  final String? accountId; // Parâmetro opcional
  
  const MainScreen({
    Key? key, 
    required this.token,
    this.accountId, // Opcional
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TradeScreen(token: widget.token),
      BotsScreen(token: widget.token),
    ];
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppStyles.bgPrimary,
      drawer: DrawerMenu(token: widget.token),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppStyles.bgSecondary,
          border: Border(
            top: BorderSide(color: AppStyles.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            selectedItemColor: AppStyles.iosBlue,
            unselectedItemColor: AppStyles.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.candlestick_chart),
                label: 'Trade',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy_outlined),
                label: 'Bots',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
