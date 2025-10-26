// custom_keyboard_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart';

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

  @override
  void initState() {
    super.initState();
    _display = widget.isInteger
        ? widget.initialValue.toInt().toString()
        : widget.initialValue.toStringAsFixed(2);

    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
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
          _display += key;
        }
      }
    });
  }

  void _confirm() {
    final value = double.tryParse(_display);
    if (value != null && value > 0) {
      AppHaptics.success();
      widget.onConfirm(value);
    } else {
      AppHaptics.error();
      AppSnackbar.error(context, 'Valor inválido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              child: Center(
                child: FadeInWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.prefix ?? '',
                        style: context.textStyles.headlineMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          _display,
                          style: context.textStyles.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 72,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Teclado
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildKeyboardRow(['1', '2', '3']),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 150),
                    child: _buildKeyboardRow(['4', '5', '6']),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: _buildKeyboardRow(['7', '8', '9']),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: _buildKeyboardRow([
                      widget.isInteger ? 'C' : '.',
                      '0',
                      '⌫'
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == 'C' || key == '⌫' || key == '.';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          height: 68,
          decoration: BoxDecoration(
            color: isSpecial
                ? context.colors.surfaceContainerHighest
                : context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              key,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSpecial
                    ? context.colors.primary
                    : context.colors.onSurface,
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
      height: 64,
      child: AnimatedPrimaryButton(
        text: 'CONFIRMAR',
        icon: Icons.check_rounded,
        onPressed: _confirm,
      ),
    );
  }
}