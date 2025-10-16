import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _saving = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _usernameController.text = _userData?['username'] ?? '';
          _bioController.text = _userData?['bio'] ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Foto de Perfil'),
        actions: [
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, color: CupertinoColors.black),
                SizedBox(width: 8),
                Text('Câmera'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, color: CupertinoColors.black),
                SizedBox(width: 8),
                Text('Galeria'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _getImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImageUploadDialog();
      }
    } catch (e) {
      _showErrorDialog('Erro ao selecionar imagem: $e');
    }
  }

  void _showImageUploadDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Upload de Foto'),
        content: Text(
          'Para alterar sua foto de perfil, envie a imagem para o suporte. Em breve implementaremos upload direto.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedImage = null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorDialog('Por favor, insira um nome de usuário.');
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Sucesso!'),
            content: Text('Perfil atualizado com sucesso.'),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Erro ao salvar perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
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

  // PROCESSO DE EXCLUSÃO DE CONTA EM ETAPAS
  void _startAccountDeletion() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, 
                 color: CupertinoColors.destructiveRed, size: 28),
            SizedBox(width: 8),
            Text('Excluir Conta?'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Você está prestes a iniciar o processo de exclusão permanente da sua conta.\n\n'
            'Esta ação não pode ser desfeita e resultará na perda de:\n'
            '• Todas as suas publicações\n'
            '• Seus tokens acumulados\n'
            '• Seu histórico completo\n'
            '• Todas as configurações\n\n'
            'Deseja continuar?',
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Continuar'),
            onPressed: () {
              Navigator.pop(context);
              _confirmAccountDeletion();
            },
          ),
        ],
      ),
    );
  }

  void _confirmAccountDeletion() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirmação Necessária'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Para sua segurança, precisamos verificar sua identidade.\n\n'
            'Esta é uma medida de proteção para evitar exclusões acidentais ou não autorizadas.\n\n'
            'Você realmente deseja prosseguir com a exclusão?',
            textAlign: TextAlign.left,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Não, Voltar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sim, Prosseguir'),
            onPressed: () {
              Navigator.pop(context);
              _requestPassword();
            },
          ),
        ],
      ),
    );
  }

  void _requestPassword() {
    _passwordController.clear();
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Digite sua Senha'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                'Por favor, digite sua senha atual para confirmar que é realmente você.\n\n'
                'Esta é a última camada de segurança antes da exclusão.',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Senha',
                obscureText: true,
                prefix: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(CupertinoIcons.lock_fill, size: 20),
                ),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () {
              _passwordController.clear();
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Verificar'),
            onPressed: () {
              if (_passwordController.text.isEmpty) {
                _showErrorDialog('Por favor, digite sua senha.');
                return;
              }
              Navigator.pop(context);
              _verifyPasswordAndShowFinalWarning();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPasswordAndShowFinalWarning() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Mostrar loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CupertinoActivityIndicator()),
    );

    try {
      // Tentar reautenticar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Senha correta, fechar loading
      Navigator.pop(context);
      _passwordController.clear();
      
      // Mostrar aviso final
      _showFinalWarning();
    } catch (e) {
      // Senha incorreta, fechar loading
      Navigator.pop(context);
      _passwordController.clear();
      
      _showErrorDialog(
        'Senha incorreta!\n\nPor favor, verifique sua senha e tente novamente.',
      );
    }
  }

  void _showFinalWarning() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_circle_fill, 
                 color: CupertinoColors.destructiveRed, size: 32),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'ÚLTIMA ETAPA - ATENÇÃO!\n\n'
            'Este é o último passo. Você tem certeza absoluta que deseja eliminar sua conta?\n\n'
            '⚠️ IMPORTANTE:\n'
            '• Esta ação é PERMANENTE e IRREVERSÍVEL\n'
            '• Todos os seus dados serão DELETADOS para sempre\n'
            '• Você NÃO poderá recuperar sua conta\n'
            '• Você NÃO poderá usar o mesmo email novamente\n'
            '• Todas as suas publicações serão REMOVIDAS\n'
            '• Seus tokens serão PERDIDOS\n\n'
            'Se você tem dúvidas ou apenas quer fazer uma pausa, '
            'recomendamos que você apenas saia da conta ao invés de excluí-la.\n\n'
            'Você pode voltar quando quiser se não excluir a conta agora.\n\n'
            'Tem certeza que deseja continuar com a exclusão PERMANENTE?',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Não, Manter Minha Conta'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sim, Excluir Permanentemente'),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Mostrar loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text(
              'Excluindo sua conta...',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Deletar dados do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 2. Deletar conta do Firebase Auth
      await user.delete();

      // Fechar loading
      Navigator.pop(context);

      // Mostrar confirmação final
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Conta Excluída'),
          content: Text(
            'Sua conta foi excluída permanentemente.\n\n'
            'Sentiremos sua falta! Se mudar de ideia, você pode criar uma nova conta a qualquer momento.',
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                // Voltar para tela de login
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);
      
      if (e.toString().contains('requires-recent-login')) {
        _showErrorDialog(
          'Sua sessão expirou!\n\n'
          'Por segurança, você precisa fazer login novamente antes de excluir sua conta.\n\n'
          'Por favor, saia e faça login novamente, depois tente excluir a conta.',
        );
      } else {
        _showErrorDialog('Erro ao excluir conta: $e');
      }
    }
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: CupertinoColors.black, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String placeholder,
    required int maxLength,
    int maxLines = 1,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: CupertinoColors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLength: maxLength,
              maxLines: maxLines,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.black, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? 
                        (isDark ? CupertinoColors.white : CupertinoColors.black),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFFAFAFA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFDBDBDB),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        trailing: _saving
            ? CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Concluído',
                  style: TextStyle(
                    color: Color(0xFF0095F6),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _saveProfile,
              ),
      ),
      child: SafeArea(
        child: _loading
            ? Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 24),
                  // Profile Image
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                                width: 1,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (_userData?['profile_image'] != null &&
                                        (_userData!['profile_image'] as String).isNotEmpty)
                                    ? ClipOval(
                                        child: Image.network(
                                          _userData!['profile_image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Container(
                                            color: Color(0xFFDBDBDB),
                                            child: Icon(
                                              CupertinoIcons.person_fill,
                                              size: 40,
                                              color: CupertinoColors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Color(0xFFDBDBDB),
                                        child: Icon(
                                          CupertinoIcons.person_fill,
                                          size: 40,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                          ),
                        ),
                        SizedBox(height: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Alterar foto do perfil',
                            style: TextStyle(
                              color: Color(0xFF0095F6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Stats
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Publicações',
                            value: '0',
                            icon: CupertinoIcons.square_grid_2x2,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tokens',
                            value: '${_userData?['tokens'] ?? 0}',
                            icon: CupertinoIcons.money_dollar_circle,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Form Fields
                  _buildInputCard(
                    icon: CupertinoIcons.person,
                    title: 'Nome',
                    controller: _usernameController,
                    placeholder: 'Nome',
                    maxLength: 30,
                    isDark: isDark,
                  ),

                  SizedBox(height: 12),

                  _buildInputCard(
                    icon: CupertinoIcons.text_alignleft,
                    title: 'Biografia',
                    controller: _bioController,
                    placeholder: 'Biografia',
                    maxLength: 150,
                    maxLines: 3,
                    isDark: isDark,
                  ),

                  SizedBox(height: 24),

                  _buildSectionHeader('Informações da Conta', isDark),
                  _buildInfoCard(
                    icon: CupertinoIcons.mail,
                    title: 'Email',
                    value: _userData?['email'] ?? 'Não informado',
                    isDark: isDark,
                  ),

                  SizedBox(height: 12),

                  _buildInfoCard(
                    icon: CupertinoIcons.star,
                    title: 'Status',
                    value: (_userData?['pro'] == true) ? 'PRO' : 'FREEMIUM',
                    valueColor: (_userData?['pro'] == true) 
                        ? Color(0xFFFCAF45) 
                        : CupertinoColors.systemGrey,
                    isDark: isDark,
                  ),

                  SizedBox(height: 24),

                  _buildSectionHeader('Segurança', isDark),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ChangePasswordScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield,
                              color: CupertinoColors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Senha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark 
                                        ? CupertinoColors.white 
                                        : CupertinoColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.systemGrey2,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Danger Zone
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _startAccountDeletion,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Excluir conta',
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}