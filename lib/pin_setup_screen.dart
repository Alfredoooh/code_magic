// lib/pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart' hide EdgeInsets; // evita conflito com EdgeInsets

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _isConfirmStep = false;
  String _firstPin = '';
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onPinSubmit() {
    final pin = _isConfirmStep ? _confirmController.text : _pinController.text;

    if (!_isConfirmStep) {
      if (pin.length < 6) {
        _showError('PIN deve ter pelo menos 6 caracteres');
        _shakeError();
        return;
      }

      AppHaptics.medium();
      setState(() {
        _firstPin = pin;
        _isConfirmStep = true;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _confirmFocusNode.requestFocus();
      });
    } else {
      if (pin != _firstPin) {
        _showError('PINs não coincidem');
        _shakeError();

        setState(() {
          _isConfirmStep = false;
          _firstPin = '';
          _pinController.clear();
          _confirmController.clear();
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          _pinFocusNode.requestFocus();
        });
      } else {
        AppHaptics.heavy();
        AppSnackbar.success(context, 'PIN criado com sucesso!');
        Navigator.pop(context, _firstPin);
      }
    }
  }

  void _shakeError() {
    AppHaptics.error();
    _shakeController.forward(from: 0).then((_) {
      _shakeController.reverse();
    });
  }

  void _showError(String message) {
    AppSnackbar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isConfirmStep ? 'Confirmar PIN' : 'Criar PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.massive),

              // Icon
              FadeInWidget(
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isConfirmStep ? Icons.verified_user_rounded : Icons.lock_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xxxl),

              // Title
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  _isConfirmStep 
                      ? 'Digite o PIN novamente'
                      : 'Crie um PIN de segurança',
                  style: context.textStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: AppSpacing.sm),

              // Subtitle
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  _isConfirmStep
                      ? 'Confirme seu PIN para continuar'
                      : 'Mínimo de 6 caracteres para sua segurança',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: AppSpacing.massive),

              // PIN Input
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppShapes.medium),
                      border: Border.all(
                        color: context.colors.outline,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _isConfirmStep ? _confirmController : _pinController,
                      focusNode: _isConfirmStep ? _confirmFocusNode : _pinFocusNode,
                      obscureText: _obscureText,
                      textAlign: TextAlign.center,
                      style: context.textStyles.headlineMedium?.copyWith(
                        letterSpacing: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        hintStyle: context.textStyles.headlineMedium?.copyWith(
                          color: context.colors.onSurfaceVariant.withOpacity(0.3),
                          letterSpacing: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                          horizontal: AppSpacing.lg,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText 
                                ? Icons.visibility_rounded 
                                : Icons.visibility_off_rounded,
                          ),
                          onPressed: () {
                            AppHaptics.light();
                            setState(() => _obscureText = !_obscureText);
                          },
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                      ],
                      onChanged: (value) {
                        if (value.length >= 6) {
                          AppHaptics.light();
                        }
                      },
                      onSubmitted: (_) => _onPinSubmit(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Helper Text
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: context.colors.onSurfaceVariant,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Use números e letras para maior segurança',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Button
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedPrimaryButton(
                    text: _isConfirmStep ? 'Confirmar' : 'Continuar',
                    icon: _isConfirmStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    onPressed: _onPinSubmit,
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}