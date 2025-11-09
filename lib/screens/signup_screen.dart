// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_icons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _schoolController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedUserType = '';
  DateTime? _selectedDate;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  double _loadingProgress = 0.0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _schoolController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3 && _validateCurrentPage()) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _selectedUserType.isNotEmpty;
      case 1:
        return _nameController.text.trim().isNotEmpty &&
               _nicknameController.text.trim().isNotEmpty &&
               _birthDateController.text.isNotEmpty;
      case 2:
        return _emailController.text.trim().isNotEmpty &&
               _emailController.text.contains('@') &&
               _passwordController.text.isNotEmpty &&
               _passwordController.text.length >= 6 &&
               _confirmPasswordController.text.isNotEmpty &&
               _passwordController.text == _confirmPasswordController.text;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _simulateProgress() async {
    setState(() => _loadingProgress = 0.0);
    
    // Simula progresso de criação de conta
    for (int i = 0; i <= 100; i += 4) {
      if (!_isLoading) break;
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        setState(() => _loadingProgress = i / 100);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_validateCurrentPage()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem'),
          backgroundColor: Color(0xFFFA383E),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    _simulateProgress();

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        userType: _selectedUserType,
        birthDate: _birthDateController.text,
        school: _schoolController.text.isNotEmpty ? _schoolController.text.trim() : null,
        address: _addressController.text.isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.isNotEmpty ? _stateController.text.trim() : null,
        country: _countryController.text.isNotEmpty ? _countryController.text.trim() : null,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text.trim() : null,
      );

      if (mounted) {
        setState(() => _loadingProgress = 1.0);
        await Future.delayed(const Duration(milliseconds: 200));
        Navigator.pushReplacementNamed(context, '/otp-verification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: ${e.toString()}'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
        _loadingProgress = 0.0;
      });
    }
  }

  void _showIOSDatePicker() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: isDark ? const Color(0xFF242526) : Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                height: 44,
                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          color: Color(0xFF1877F2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        if (_selectedDate != null) {
                          _birthDateController.text = 
                            '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
                          setState(() {});
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              // Date Picker
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                        fontSize: 20,
                      ),
                    ),
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate ?? DateTime(2000),
                    minimumYear: 1950,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      _selectedDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return PopScope(
      canPop: _currentPage == 0 && !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0 && !_isLoading) {
          _previousPage();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: SvgIcon(
              svgString: CustomIcons.arrowLeft,
              color: textColor,
              size: 24,
            ),
            onPressed: _isLoading 
              ? null 
              : (_currentPage == 0 
                ? () => Navigator.pop(context)
                : _previousPage),
          ),
          title: Text(
            'Cadastre-se',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
              height: 0.5,
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Progress indicator (Facebook style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: List.generate(4, (index) {
                        final isActive = index <= _currentPage;
                        final isCompleted = index < _currentPage;
                        
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive
                                ? const Color(0xFF1877F2)
                                : isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: isCompleted
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1877F2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              : null,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      children: [
                        _buildUserTypePage(isDark, textColor),
                        _buildPersonalInfoPage(isDark, textColor),
                        _buildCredentialsPage(isDark, textColor),
                        _buildAdditionalInfoPage(isDark, textColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar (estilo Facebook - no topo)
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 100),
                  tween: Tween(begin: 0.0, end: _loadingProgress),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark 
                        ? const Color(0xFF3A3B3C) 
                        : const Color(0xFFE4E6EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1877F2),
                      ),
                      minHeight: 3,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedUserType == value;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedUserType = value;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242526) : Colors.white,
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF1877F2)
              : isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                  ? const Color(0xFF1877F2).withOpacity(0.1)
                  : isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected 
                  ? const Color(0xFF1877F2)
                  : isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1877F2),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypePage(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual é o seu perfil?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione a opção que melhor descreve você',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 32),

          _buildUserTypeCard(
            icon: Icons.school,
            title: 'Estudante',
            subtitle: 'Estou aqui para aprender e compartilhar conhecimento',
            value: 'student',
            isDark: isDark,
          ),
          _buildUserTypeCard(
            icon: Icons.business_center,
            title: 'Empreendedor',
            subtitle: 'Busco oportunidades de negócio e networking',
            value: 'entrepreneur',
            isDark: isDark,
          ),
          _buildUserTypeCard(
            icon: Icons.create,
            title: 'Criador',
            subtitle: 'Crio conteúdo e documentos personalizados',
            value: 'creator',
            isDark: isDark,
          ),
          _buildUserTypeCard(
            icon: Icons.work,
            title: 'Profissional',
            subtitle: 'Ofereço serviços profissionais especializados',
            value: 'professional',
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _validateCurrentPage() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações pessoais',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conte-nos um pouco sobre você',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _nameController,
            label: 'Nome completo',
            hintText: 'Digite seu nome completo',
            isDark: isDark,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _nicknameController,
            label: 'Nome de usuário',
            hintText: 'Digite seu nome de usuário',
            isDark: isDark,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _showIOSDatePicker,
            child: AbsorbPointer(
              child: CustomTextField(
                controller: _birthDateController,
                label: 'Data de nascimento',
                hintText: 'DD/MM/AAAA',
                isDark: isDark,
                suffixIcon: const Icon(
                  CupertinoIcons.calendar,
                  size: 20,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedUserType == 'student')
            CustomTextField(
              controller: _schoolController,
              label: 'Instituição de ensino',
              hintText: 'Nome da sua escola/universidade',
              isDark: isDark,
            ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1877F2),
                    side: const BorderSide(color: Color(0xFF1877F2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateCurrentPage() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsPage(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credenciais de acesso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie suas credenciais de login',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Digite seu email',
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _passwordController,
            label: 'Senha',
            hintText: 'Digite sua senha (mínimo 6 caracteres)',
            obscureText: !_showPassword,
            isDark: isDark,
            onChanged: (value) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar senha',
            hintText: 'Confirme sua senha',
            obscureText: !_showConfirmPassword,
            isDark: isDark,
            onChanged: (value) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
              ),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
          
          // Validação visual de senha
          if (_passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordValidationItem(
                    'Mínimo de 6 caracteres',
                    _passwordController.text.length >= 6,
                    isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildPasswordValidationItem(
                    'As senhas coincidem',
                    _passwordController.text.isNotEmpty && 
                    _passwordController.text == _confirmPasswordController.text,
                    isDark,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1877F2),
                    side: const BorderSide(color: Color(0xFF1877F2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateCurrentPage() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordValidationItem(String text, bool isValid, bool isDark) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isValid 
            ? const Color(0xFF42B72A) 
            : isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isValid 
              ? const Color(0xFF42B72A) 
              : isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoPage(bool isDark, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações adicionais',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Opcional - Pode preencher depois',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
            ),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _phoneController,
            label: 'Telefone',
            hintText: 'Digite seu telefone',
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _addressController,
            label: 'Endereço',
            hintText: 'Digite seu endereço',
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _cityController,
                  label: 'Cidade',
                  hintText: 'Cidade',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  label: 'Estado',
                  hintText: 'Estado',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _countryController,
            label: 'País',
            hintText: 'Digite seu país',
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _bioController,
            label: 'Bio',
            hintText: 'Conte um pouco sobre você',
            maxLines: 3,
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1877F2),
                    side: const BorderSide(color: Color(0xFF1877F2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}