// custom_keyboard_screen.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'theme/app_widgets.dart';

class CustomKeyboardScreen extends StatefulWidget {
  final String title;
  final double initialValue;
  final String? prefix;
  final bool isInteger;
  final Function(double) onConfirm;

  const CustomKeyboardScreen({
    Key? key,
    required this.title,
    required this.initialValue,
    this.prefix,
    this.isInteger = false,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CustomKeyboardScreen> createState() => _CustomKeyboardScreenState();
}

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen>
    with SingleTickerProviderStateMixin {
  late String _display;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _display = widget.isInteger
        ? widget.initialValue.toInt().toString()
        : widget.initialValue.toStringAsFixed(2);

    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.short,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: AppMotion.standardEasing),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    AppHaptics.light();
    _animController.forward().then((_) => _animController.reverse());

    setState(() {
      _errorMessage = null;
      
      if (key == 'C') {
        _display = '0';
      } else if (key == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (key == '.') {
        if (!widget.isInteger && !_display.contains('.')) {
          _display += '.';
        }
      } else {
        if (_display == '0' && key != '.') {
          _display = key;
        } else {
          // Limitar a 12 dígitos
          if (_display.replaceAll('.', '').length < 12) {
            _display += key;
          }
        }
      }
    });
  }

  void _confirm() {
    final value = double.tryParse(_display);
    if (value != null && value > 0) {
      AppHaptics.success();
      Navigator.pop(context);
      widget.onConfirm(value);
    } else {
      AppHaptics.error();
      setState(() {
        _errorMessage = 'Valor inválido';
      });
      AppSnackbar.error(context, 'Insira um valor válido maior que zero');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: SecondaryAppBar(
        title: widget.title,
        onBack: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Prefix
                    if (widget.prefix != null)
                      FadeInWidget(
                        child: Text(
                          widget.prefix!,
                          style: context.textStyles.headlineMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: AppSpacing.md),

                    // Display Value
                    FadeInWidget(
                      delay: Duration(milliseconds: 100),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Text(
                            _display,
                            style: context.textStyles.displayLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: 64,
                              color: _errorMessage != null 
                                  ? AppColors.error 
                                  : context.colors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      FadeInWidget(
                        child: Container(
                          margin: EdgeInsets.only(top: AppSpacing.md),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 16,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                _errorMessage!,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Hint Text
                    FadeInWidget(
                      delay: Duration(milliseconds: 200),
                      child: Container(
                        margin: EdgeInsets.only(top: AppSpacing.lg),
                        child: Text(
                          widget.isInteger 
                              ? 'Digite um valor inteiro' 
                              : 'Digite um valor decimal',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Keyboard Container
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1
                  FadeInWidget(
                    delay: Duration(milliseconds: 100),
                    child: _buildKeyboardRow(['1', '2', '3']),
                  ),
                  SizedBox(height: AppSpacing.md),
                  
                  // Row 2
                  FadeInWidget(
                    delay: Duration(milliseconds: 150),
                    child: _buildKeyboardRow(['4', '5', '6']),
                  ),
                  SizedBox(height: AppSpacing.md),
                  
                  // Row 3
                  FadeInWidget(
                    delay: Duration(milliseconds: 200),
                    child: _buildKeyboardRow(['7', '8', '9']),
                  ),
                  SizedBox(height: AppSpacing.md),
                  
                  // Row 4
                  FadeInWidget(
                    delay: Duration(milliseconds: 250),
                    child: _buildKeyboardRow([
                      widget.isInteger ? 'C' : '.',
                      '0',
                      '⌫'
                    ]),
                  ),
                  
                  SizedBox(height: AppSpacing.xl),
                  
                  // Confirm Button
                  FadeInWidget(
                    delay: Duration(milliseconds: 300),
                    child: _buildConfirmButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == 'C' || key == '⌫' || key == '.';
    final isDelete = key == '⌫';
    final isClear = key == 'C';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: isSpecial
                ? context.colors.surfaceContainerHighest
                : context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSpecial
                  ? context.colors.outline.withOpacity(0.3)
                  : context.colors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: isSpecial
                ? Icon(
                    isClear 
                        ? Icons.clear_rounded 
                        : isDelete 
                            ? Icons.backspace_outlined 
                            : Icons.circle,
                    color: isClear || isDelete 
                        ? context.colors.error 
                        : context.colors.primary,
                    size: 24,
                  )
                : Text(
                    key,
                    style: context.textStyles.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PrimaryButton(
        text: 'CONFIRMAR',
        icon: Icons.check_rounded,
        onPressed: _confirm,
        expanded: true,
      ),
    );
  }
}