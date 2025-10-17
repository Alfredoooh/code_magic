// lib/widgets/login_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/deriv_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginSheet extends StatefulWidget {
  final DerivService derivService;

  LoginSheet({required this.derivService});

  @override
  _LoginSheetState createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connectWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showError('Por favor, insira um token válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.derivService.connectWithToken(token);
      if (mounted) {
        Navigator.pop(context);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erro ao conectar: ${e.toString()}');
      }
    }
  }

  Future<void> _startOAuth() async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final token = await widget.derivService.startOAuthFlow();
      if (token != null && mounted) {
        _showSuccess();
      } else if (mounted) {
        _showError('Autenticação cancelada');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('✅ Conectado'),
        content: Text('Conta Deriv conectada com sucesso!'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('❌ Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showApiGuide() {
    Navigator.pop(context);
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Como Obter Token API',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                physics: BouncingScrollPhysics(),
                children: [
                  _buildGuideStep(
                    isDark,
                    '1',
                    'Acesse app.deriv.com',
                    CupertinoIcons.arrow_right_circle_fill,
                  ),
                  SizedBox(height: 20),
                  _buildGuideStep(
                    isDark,
                    '2',
                    'Vá para Settings → API Token',
                    CupertinoIcons.settings_solid,
                  ),
                  SizedBox(height: 20),
                  _buildGuideStep(
                    isDark,
                    '3',
                    'Crie um token com permissões Read e Trade',
                    CupertinoIcons.add_circled_solid,
                  ),
                  SizedBox(height: 20),
                  _buildGuideStep(
                    isDark,
                    '4',
                    'Copie o token gerado',
                    CupertinoIcons.doc_on_clipboard_fill,
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFFFF444F).withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_shield_fill,
                          color: Color(0xFFFF444F),
                          size: 24,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Mantenha seu token seguro e nunca o compartilhe',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  CupertinoButton(
                    color: Color(0xFFFF444F),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () async {
                      final uri = Uri.parse('https://app.deriv.com');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      'Abrir Deriv',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(bool isDark, String number, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFFF444F),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 20, color: Color(0xFFFF444F)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Conectar Deriv',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Insira seu token API da Deriv',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
              ),
            ),
            SizedBox(height: 24),
            CupertinoTextField(
              controller: _tokenController,
              placeholder: 'Token API',
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: Color(0xFFFF444F),
                borderRadius: BorderRadius.circular(16),
                padding: EdgeInsets.symmetric(vertical: 16),
                onPressed: _isLoading ? null : _connectWithToken,
                child: _isLoading
                    ? CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        'Conectar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: CupertinoButton(
                onPressed: _startOAuth,
                child: Text(
                  'Autorizar via navegador (OAuth)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF444F),
                  ),
                ),
              ),
            ),
            Center(
              child: CupertinoButton(
                onPressed: _showApiGuide,
                child: Text(
                  'Como obter meu token?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF444F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}