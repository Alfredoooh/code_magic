import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class UserInfoScreen extends StatefulWidget {
  final User user;

  const UserInfoScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _userKeyController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Timer _countdownTimer;
  
  bool _isVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureUserKey = true;
  String _errorMessage = '';
  String _timeRemaining = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startCountdownTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (mounted) {
      setState(() {
        _timeRemaining = widget.user.timeUntilExpiry;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer.cancel();
    _passwordController.dispose();
    _userKeyController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccess() async {
    final password = _passwordController.text.trim();
    final userKey = _userKeyController.text.trim();

    if (password.isEmpty && userKey.isEmpty) {
      setState(() {
        _errorMessage = 'Forneça a palavra-passe ou User Key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.verifyUserAccess(
        widget.user,
        password.isNotEmpty ? password : null,
        userKey.isNotEmpty ? userKey : null,
      );

      if (result.success) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar acesso';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Informações da Conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isVerified ? _buildUserInfo() : _buildVerificationForm(),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF007AFF).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              size: 80,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Acesso Restrito',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Para visualizar informações sensíveis,\nforneça autenticação adicional',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          if (_errorMessage.isNotEmpty) _buildErrorMessage(),
          _buildPasswordField(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            ],
          ),
          const SizedBox(height: 24),
          _buildUserKeyField(),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Verificar Acesso',
            onPressed: _isLoading ? null : _verifyAccess,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Palavra-passe',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.lock_fill,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Digite sua palavra-passe',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword 
                      ? CupertinoIcons.eye_slash_fill 
                      : CupertinoIcons.eye_fill,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserKeyField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'User Key',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.lock,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _userKeyController,
                    obscureText: _obscureUserKey,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Digite sua User Key',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureUserKey = !_obscureUserKey;
                    });
                  },
                  icon: Icon(
                    _obscureUserKey 
                      ? CupertinoIcons.eye_slash_fill 
                      : CupertinoIcons.eye_fill,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF3B30).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Color(0xFFFF3B30),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildInfoSection('Informações Pessoais', [
            _buildInfoRow('ID do Usuário', widget.user.id),
            _buildInfoRow('Nome de Usuário', widget.user.username),
            _buildInfoRow('Email', widget.user.email),
            _buildInfoRow('Nome Completo', widget.user.fullName),
            _buildInfoRow('Data de Nascimento', widget.user.birthDate),
            _buildInfoRow('Telefone', widget.user.phone),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Segurança e Acesso', [
            _buildInfoRow('Status', widget.user.accountStatus, 
              color: widget.user.statusColor),
            _buildInfoRow('Autenticação 2FA', 
              widget.user.twoFactorAuth ? 'Ativa' : 'Inativa',
              color: widget.user.twoFactorAuth 
                ? const Color(0xFF34C759) 
                : const Color(0xFF8E8E93)),
            _buildInfoRow('User Key', widget.user.userKey),
            _buildInfoRow('Tipo de Conta', widget.user.role.toUpperCase()),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Datas Importantes', [
            _buildInfoRow('Conta Criada', 
              _formatDateTime(widget.user.createdAt)),
            _buildInfoRow('Último Login', 
              widget.user.lastLogin != null 
                ? _formatDateTime(widget.user.lastLogin!)
                : 'Agora'),
            _buildInfoRow('Data de Expiração', 
              _formatDateTime(widget.user.expirationDate)),
          ]),
          const SizedBox(height: 16),
          _buildCountdownCard(),
          const SizedBox(height: 16),
          if (widget.user.notificationMessage.isNotEmpty)
            _buildNotificationSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007AFF),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 3,
              ),
              image: widget.user.profileImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.user.profileImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.user.profileImage.isEmpty
                ? Center(
                    child: Text(
                      widget.user.avatarInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.user.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.user.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.user.statusColor.withOpacity(0.5),
              ),
            ),
            child: Text(
              widget.user.accountStatus,
              style: TextStyle(
                color: widget.user.statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    Color cardColor;
    if (widget.user.daysUntilExpiry < 7) {
      cardColor = const Color(0xFFFF3B30);
    } else if (widget.user.daysUntilExpiry < 30) {
      cardColor = const Color(0xFFFF9500);
    } else {
      cardColor = const Color(0xFF34C759);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.hourglass,
            size: 40,
            color: cardColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tempo Restante da Conta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _timeRemaining,
            style: TextStyle(
              color: cardColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF007AFF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.bell_fill,
                color: Color(0xFF007AFF),
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Notificação',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.user.notificationMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}