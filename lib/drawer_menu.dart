import 'package:flutter/material.dart';
import 'styles.dart';
import 'settings_screen.dart';

class DrawerMenu extends StatelessWidget {
  final String token;
  
  const DrawerMenu({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppStyles.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            // Header do Drawer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppStyles.bgSecondary,
                border: Border(
                  bottom: BorderSide(color: AppStyles.border, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppStyles.iosBlue,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deriv Trading',
                    style: TextStyle(
                      color: AppStyles.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'App ID: 71954',
                    style: const TextStyle(
                      color: AppStyles.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Início',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.candlestick_chart,
                    title: 'Trading',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.smart_toy_outlined,
                    title: 'Bots',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: 'Histórico',
                    onTap: () {
                      Navigator.pop(context);
                      AppStyles.showSnackBar(context, 'Histórico em desenvolvimento');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Carteira',
                    onTap: () {
                      Navigator.pop(context);
                      AppStyles.showSnackBar(context, 'Carteira em desenvolvimento');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calculate_outlined,
                    title: 'Calculadora',
                    onTap: () => _showCalculator(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Análises',
                    onTap: () {
                      Navigator.pop(context);
                      AppStyles.showSnackBar(context, 'Análises em desenvolvimento');
                    },
                  ),
                  const Divider(
                    color: AppStyles.border,
                    thickness: 0.5,
                    height: 24,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(token: token),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ajuda',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelp(context);
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppStyles.bgSecondary,
                border: Border(
                  top: BorderSide(color: AppStyles.border, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: AppStyles.red,
                    ),
                    label: const Text(
                      'Desconectar',
                      style: TextStyle(
                        color: AppStyles.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: AppStyles.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppStyles.textPrimary,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppStyles.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      hoverColor: AppStyles.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showCalculator(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calculadora de Trading',
                    style: TextStyle(
                      color: AppStyles.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppStyles.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor de Entrada',
                  prefixText: '\$ ',
                ),
                style: const TextStyle(color: AppStyles.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Multiplicador',
                  prefixText: 'x',
                ),
                style: const TextStyle(color: AppStyles.textPrimary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  AppStyles.showSnackBar(context, 'Resultado calculado!');
                  Navigator.pop(context);
                },
                child: const Text('Calcular'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.bgSecondary,
        title: const Text(
          'Ajuda',
          style: TextStyle(color: AppStyles.textPrimary),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Como usar o app:',
                style: TextStyle(
                  color: AppStyles.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '1. Conecte-se com seu token Deriv\n'
                '2. Escolha o mercado desejado\n'
                '3. Defina o valor e multiplicador\n'
                '4. Clique em Up ou Down para operar\n'
                '5. Use Bots para automação',
                style: TextStyle(color: AppStyles.textSecondary),
              ),
              SizedBox(height: 16),
              Text(
                'Para mais informações:',
                style: TextStyle(
                  color: AppStyles.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Visite: docs.deriv.com',
                style: TextStyle(color: AppStyles.iosBlue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.bgSecondary,
        title: const Text(
          'Sobre',
          style: TextStyle(color: AppStyles.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppStyles.iosBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.trending_up,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deriv Trading',
              style: TextStyle(
                color: AppStyles.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Versão 1.0.0',
              style: TextStyle(color: AppStyles.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'App de trading conectado à Deriv\n'
              'Package: com.nexa.madeeasy\n'
              'App ID: 71954',
              style: TextStyle(
                color: AppStyles.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.bgSecondary,
        title: const Text(
          'Desconectar',
          style: TextStyle(color: AppStyles.textPrimary),
        ),
        content: const Text(
          'Deseja realmente desconectar sua conta?',
          style: TextStyle(color: AppStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              AppStyles.showSnackBar(context, 'Desconectado com sucesso');
            },
            child: const Text(
              'Desconectar',
              style: TextStyle(color: AppStyles.red),
            ),
          ),
        ],
      ),
    );
  }
}
