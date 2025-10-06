import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../screens/user_info_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/hub_screen.dart';
import 'tabs/stories_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/productivity_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  User? _currentUser;
  bool _isLoading = true;
  bool _isDisposed = false;

  final List<Widget> _pages = [];
  late List<AnimationController> _iconControllers;
  late AnimationController _rippleController;

  final List<TabInfo> _tabs = [
    TabInfo('Início', Icons.home_rounded),
    TabInfo('Hub', Icons.stacks_rounded),
    TabInfo('Stories', Icons.photo_library_rounded),
    TabInfo('Produtividade', Icons.check_circle_rounded),
    TabInfo('Dashboard', Icons.analytics_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _iconControllers = List.generate(
      _tabs.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _iconControllers[0].value = 1.0;
    
    _initializeApp();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    _rippleController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _validateUserSession();
    }
  }

  Future<void> _initializeApp() async {
    try {
      await _loadUserData();
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
      await _redirectToLogin();
    }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed) return;

    try {
      final user = await StorageService.getCurrentUser();
      
      if (user == null) {
        await _redirectToLogin();
        return;
      }

      final isValid = await AuthService.validateSession(user);
      
      if (!isValid) {
        await AuthService.logout();
        await _redirectToLogin();
        return;
      }

      if (user.isBlocked) {
        await _showBlockedAccountDialog();
        await _redirectToLogin();
        return;
      }

      if (user.isExpired) {
        await _showExpiredAccountDialog();
        await _redirectToLogin();
        return;
      }

      try {
        final updatedUser = await AuthService.refreshUserData(user.id);
        
        if (!_isDisposed) {
          setState(() {
            _currentUser = updatedUser ?? user;
            _initializePages();
            _isLoading = false;
          });
        }
      } catch (refreshError) {
        debugPrint('Erro ao atualizar dados: $refreshError');
        if (!_isDisposed) {
          setState(() {
            _currentUser = user;
            _initializePages();
            _isLoading = false;
          });
        }
      }

    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
      await _redirectToLogin();
    }
  }

  void _initializePages() {
    _pages.clear();
    _pages.addAll([
      HomeTab(user: _currentUser!),
      const HubScreen(),
      const StoriesTab(),
      const ProductivityTab(),
      DashboardTab(user: _currentUser!),
    ]);
  }

  Future<void> _validateUserSession() async {
    if (_currentUser == null || _isDisposed) return;

    try {
      final isValid = await AuthService.validateSession(_currentUser!);
      if (!isValid && !_isDisposed) {
        await _redirectToLogin();
      }
    } catch (e) {
      debugPrint('Erro na validação da sessão: $e');
    }
  }

  Future<void> _showBlockedAccountDialog() async {
    if (_isDisposed) return;
    
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Conta Bloqueada'),
        content: const Text('Sua conta foi bloqueada. Entre em contato com o administrador.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpiredAccountDialog() async {
    if (_isDisposed) return;
    
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Conta Expirada'),
        content: const Text('Sua conta expirou. Renove sua assinatura para continuar.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _redirectToLogin() async {
    if (_isDisposed) return;
    
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> _refreshUserData() async {
    if (_currentUser == null || _isDisposed) return;

    try {
      final updatedUser = await AuthService.refreshUserData(_currentUser!.id);
      
      if (updatedUser != null && !_isDisposed) {
        setState(() {
          _currentUser = updatedUser;
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar dados do usuário: $e');
    }
  }

  void _onTabTapped(int index) {
    if (_isDisposed || index == _currentIndex) return;
    
    _iconControllers[_currentIndex].reverse();
    _iconControllers[index].forward();
    _rippleController.forward(from: 0.0);
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_currentUser == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              color: Color(0xFF007AFF),
              radius: 20,
            ),
            SizedBox(height: 20),
            Text(
              'Carregando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 80,
              color: Color(0xFFFF3B30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Erro ao carregar dados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Verifique sua conexão e tente novamente',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CupertinoButton.filled(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _initializeApp();
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1C1C1E).withOpacity(0.7),
            const Color(0xFF1C1C1E).withOpacity(0.95),
            const Color(0xFF1C1C1E),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withOpacity(0.05),
            BlendMode.srcOver,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  return _buildTabItem(index, _tabs[index]);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, TabInfo tabInfo) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF).withOpacity(
                        0.08 * (1 - _rippleController.value))
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    height: 3,
                    width: isSelected ? 32 : 0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: AnimatedBuilder(
                      animation: _iconControllers[index],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + (_iconControllers[index].value * 0.2),
                          child: Icon(
                            tabInfo.icon,
                            color: isSelected 
                                ? const Color(0xFF007AFF)
                                : const Color(0xFF8E8E93),
                            size: 26,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF8E8E93),
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: isSelected ? 0.2 : 0,
                    ),
                    child: Text(
                      tabInfo.title,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TabInfo {
  final String title;
  final IconData icon;

  TabInfo(this.title, this.icon);
}