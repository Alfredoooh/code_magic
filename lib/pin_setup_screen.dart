// lib/pin_setup_screen.dart - Material Design 3
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChange;
  final String? currentPin;

  const PinSetupScreen({
    Key? key,
    this.isChange = false,
    this.currentPin,
  }) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  late AnimationController _shakeController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _successScale;

  bool _isConfirmStep = false;
  String _firstPin = '';
  bool _obscureText = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _successController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: AppMotion.emphasizedDecelerate,
      ),
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
    _successController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onPinSubmit() {
    final pin = _isConfirmStep ? _confirmController.text : _pinController.text;

    if (!_isConfirmStep) {
      // Validate PIN length
      if (pin.length < 6) {
        _showError('PIN must be at least 6 characters');
        _shakeError();
        return;
      }

      // Validate PIN strength
      if (!_isStrongPin(pin)) {
        _showError('Use a mix of numbers and letters for security');
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
      // Confirm PIN
      if (pin != _firstPin) {
        _showError('PINs do not match');
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
        _savePin();
      }
    }
  }

  bool _isStrongPin(String pin) {
    final hasNumbers = pin.contains(RegExp(r'[0-9]'));
    final hasLetters = pin.contains(RegExp(r'[a-zA-Z]'));
    return hasNumbers && hasLetters;
  }

  Future<void> _savePin() async {
    setState(() => _isLoading = true);

    // Simulate save delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    AppHaptics.heavy();
    _successController.forward();

    await Future.delayed(AppMotion.medium);

    if (!mounted) return;

    AppSnackbar.success(
      context,
      widget.isChange ? 'PIN updated successfully! 🔒' : 'PIN created successfully! 🎉',
    );

    Navigator.pop(context, _firstPin);
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

  int _getPinStrength(String pin) {
    if (pin.length < 6) return 0;
    if (pin.length < 8) return 1;
    
    final hasNumbers = pin.contains(RegExp(r'[0-9]'));
    final hasLetters = pin.contains(RegExp(r'[a-zA-Z]'));
    final hasUpperCase = pin.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = pin.contains(RegExp(r'[a-z]'));
    
    int strength = 1;
    if (hasNumbers && hasLetters) strength++;
    if (hasUpperCase && hasLowerCase) strength++;
    if (pin.length >= 10) strength++;
    
    return strength;
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
        return AppColors.error;
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.info;
      case 3:
      case 4:
        return AppColors.success;
      default:
        return AppColors.error;
    }
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return 'Too short';
      case 1:
        return 'Weak';
      case 2:
        return 'Good';
      case 3:
        return 'Strong';
      case 4:
        return 'Very Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: widget.isChange
            ? (_isConfirmStep ? 'Confirm New PIN' : 'Change PIN')
            : (_isConfirmStep ? 'Confirm PIN' : 'Create PIN'),
        onBack: _isLoading
            ? null
            : () {
                AppHaptics.light();
                Navigator.pop(context);
              },
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Securing your account...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.massive),
                _buildHeroIcon(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildTitle(),
                const SizedBox(height: AppSpacing.sm),
                _buildSubtitle(),
                const SizedBox(height: AppSpacing.massive),
                _buildPinInput(),
                const SizedBox(height: AppSpacing.lg),
                if (!_isConfirmStep) _buildStrengthIndicator(),
                if (!_isConfirmStep) const SizedBox(height: AppSpacing.lg),
                _buildHelperText(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildSecurityFeatures(),
                const SizedBox(height: AppSpacing.massive),
                _buildContinueButton(),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    return FadeInWidget(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isConfirmStep
                  ? Icons.verified_user_rounded
                  : Icons.lock_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
          if (_isConfirmStep)
            ScaleTransition(
              scale: _successScale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: Text(
        _isConfirmStep
            ? 'Confirm Your PIN'
            : (widget.isChange ? 'Create New PIN' : 'Create Security PIN'),
        style: context.textStyles.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Text(
        _isConfirmStep
            ? 'Enter your PIN again to confirm'
            : 'Minimum 6 characters for your security',
        style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPinInput() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: AppTextField(
          controller: _isConfirmStep ? _confirmController : _pinController,
          focusNode: _isConfirmStep ? _confirmFocusNode : _pinFocusNode,
          label: _isConfirmStep ? 'Confirm PIN' : 'Enter PIN',
          hint: '••••••',
          obscureText: _isConfirmStep ? _obscureConfirm : _obscureText,
          textAlign: TextAlign.center,
          textStyle: context.textStyles.headlineMedium?.copyWith(
            letterSpacing: 16,
            fontWeight: FontWeight.w700,
          ),
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
            LengthLimitingTextInputFormatter(12),
          ],
          suffix: IconButton(
            icon: Icon(
              (_isConfirmStep ? _obscureConfirm : _obscureText)
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            onPressed: () {
              AppHaptics.light();
              setState(() {
                if (_isConfirmStep) {
                  _obscureConfirm = !_obscureConfirm;
                } else {
                  _obscureText = !_obscureText;
                }
              });
            },
          ),
          onChanged: (value) {
            if (value.length >= 6) {
              AppHaptics.light();
            }
            setState(() {});
          },
          onSubmitted: (_) => _onPinSubmit(),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final pin = _pinController.text;
    final strength = _getPinStrength(pin);
    final color = _getStrengthColor(strength);
    final text = _getStrengthText(strength);

    if (pin.isEmpty) return const SizedBox.shrink();

    return FadeInWidget(
      child: OutlinedCard(
        borderColor: color.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Strength: $text',
                  style: context.textStyles.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: strength / 4,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperText() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.info.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.info,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Use numbers and letters for better security',
                style: context.textStyles.bodySmall?.copyWith(
                  color: AppColors.info,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeatures() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Security',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            Icons.lock_clock_rounded,
            'Auto-lock',
            'App locks after 5 minutes of inactivity',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.phonelink_lock_rounded,
            'Biometric',
            'Use fingerprint or face ID for quick access',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.shield_rounded,
            'Encrypted',
            'Your PIN is stored securely and encrypted',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final canContinue = _isConfirmStep
        ? _confirmController.text.length >= 6
        : _pinController.text.length >= 6;

    return FadeInWidget(
      delay: const Duration(milliseconds: 600),
      child: PrimaryButton(
        text: _isConfirmStep ? 'Confirm PIN' : 'Continue',
        icon: _isConfirmStep
            ? Icons.check_rounded
            : Icons.arrow_forward_rounded,
        onPressed: canContinue ? _onPinSubmit : null,
        expanded: true,
      ),
    );
  }
}