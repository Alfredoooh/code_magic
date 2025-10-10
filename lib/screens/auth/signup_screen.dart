import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDate;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: accentPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    // Verifica se as senhas coincidem
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('passwords_dont_match') ?? 
                      'As senhas não coincidem'),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Remove foco do teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // Validação de idade
      final birthDate = DateFormat('yyyy-MM-dd').parse(_birthDateController.text);
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      if (age < 18) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('age_restriction') ?? 
                          'Você precisa ter pelo menos 18 anos'),
              backgroundColor: danger,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // CRÍTICO: Não armazene senha em texto puro!
      // O Firebase Auth já cuida da senha de forma segura
      final userData = {
        'username': _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
        'email': _emailController.text.trim(),
        // REMOVIDO: 'password' - NUNCA armazene senha no Firestore!
        'full_name': _nameController.text.trim(),
        'birth_date': _birthDateController.text,
        'phone': _phoneController.text.trim(),
        'access': true,
        'expiration_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'two_factor_auth': false,
        'user_key': 'USR-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}',
        'notification_message': 'Welcome to K_paga!',
        'created_at': FieldValue.serverTimestamp(),
        'profile_image': null,
        'role': 'USER',
        'blocked': false,
        'failed_attempts': 0,
        'blocked_until': null,
        'theme_black': false,
        'primary_color': 'purple',
        'bio': '',
        'followed_users': [],
        'watchlists': [],
        'preferences': {},
        'points': 0,
        'is_online': false,
      };

      await AuthService().signup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
        context: context,
      );

      // Envia email de boas-vindas (sem a senha!)
      try {
        final emailData = Map<String, dynamic>.from(userData);
        emailData.remove('password'); // Garantir que senha não vá no email
        await EmailService().sendUserData(emailData, 'alfredopjonas@gmail.com');
      } catch (emailError) {
        // Se falhar ao enviar email, apenas loga mas não bloqueia o cadastro
        print('Erro ao enviar email: $emailError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('account_created') ?? 
                        'Conta criada com sucesso!'),
            backgroundColor: success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Volta para tela de login após 1 segundo
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = AppLocalizations.of(context)!.translate('weak_password') ?? 
                        'Senha muito fraca. Use pelo menos 6 caracteres';
          break;
        case 'email-already-in-use':
          errorMessage = AppLocalizations.of(context)!.translate('email_in_use') ?? 
                        'Este email já está em uso';
          break;
        case 'invalid-email':
          errorMessage = AppLocalizations.of(context)!.translate('invalid_email') ?? 
                        'Email inválido';
          break;
        case 'operation-not-allowed':
          errorMessage = AppLocalizations.of(context)!.translate('operation_not_allowed') ?? 
                        'Operação não permitida';
          break;
        case 'network-request-failed':
          errorMessage = AppLocalizations.of(context)!.translate('network_error') ?? 
                        'Erro de conexão. Verifique sua internet';
          break;
        default:
          errorMessage = AppLocalizations.of(context)!.translate('auth_error') ?? 
                        'Erro ao criar conta: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: accentGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_rounded, size: 80, color: accentPrimary),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('create_account')!,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        label: AppLocalizations.of(context)!.translate('name')!,
                        icon: Icons.person_rounded,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_name')!;
                          }
                          if (value.trim().length < 3) {
                            return AppLocalizations.of(context)!.translate('name_too_short') ?? 
                                   'Nome muito curto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: AppLocalizations.of(context)!.translate('email')!,
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_email')!;
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return AppLocalizations.of(context)!.translate('invalid_email')!;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: AppLocalizations.of(context)!.translate('password')!,
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_password')!;
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!.translate('password_too_short')!;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: AppLocalizations.of(context)!.translate('confirm_password') ?? 
                               'Confirmar Senha',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('confirm_password_required') ?? 
                                   'Confirme sua senha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _birthDateController,
                        label: AppLocalizations.of(context)!.translate('birth_date')!,
                        icon: Icons.calendar_today_rounded,
                        readOnly: true,
                        enabled: !_isLoading,
                        onTap: _isLoading ? null : _selectDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_birth_date')!;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: AppLocalizations.of(context)!.translate('phone')!,
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _signup(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_phone')!;
                          }
                          // Validação básica de telefone (apenas números)
                          if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(value)) {
                            return AppLocalizations.of(context)!.translate('invalid_phone') ?? 
                                   'Telefone inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: _isLoading
                            ? ''
                            : AppLocalizations.of(context)!.translate('create_account')!,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _signup,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('already_have_account')!,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: _isLoading ? Colors.grey : accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}