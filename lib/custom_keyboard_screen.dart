// lib/custom_keyboard_screen.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class CustomKeyboardScreen extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? hint;
  final Function(String) onSubmit;
  final bool isDecimal;
  final double? minValue;
  final double? maxValue;

  const CustomKeyboardScreen({
    Key? key,
    required this.title,
    this.initialValue,
    this.hint,
    required this.onSubmit,
    this.isDecimal = false,
    this.minValue,
    this.maxValue,
  }) : super(key: key);

  @override
  State<CustomKeyboardScreen> createState() => _CustomKeyboardScreenState();
}

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen> {
  String _displayValue = '';
  
  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue ?? '';
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        // Backspace
        if (_displayValue.isNotEmpty) {
          _displayValue = _displayValue.substring(0, _displayValue.length - 1);
        }
      } else if (key == 'C') {
        // Clear
        _displayValue = '';
      } else if (key == '.') {
        // Decimal point
        if (widget.isDecimal && !_displayValue.contains('.')) {
          _displayValue += key;
        }
      } else {
        // Number
        _displayValue += key;
      }
    });
    
    AppHaptics.light();
  }

  void _onSubmit() {
    if (_displayValue.isEmpty) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Digite um valor');
      return;
    }

    final value = double.tryParse(_displayValue);
    
    if (value == null) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Valor inválido');
      return;
    }

    if (widget.minValue != null && value < widget.minValue!) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Valor mínimo: ${widget.minValue}');
      return;
    }

    if (widget.maxValue != null && value > widget.maxValue!) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Valor máximo: ${widget.maxValue}');
      return;
    }

    AppHaptics.success();
    widget.onSubmit(_displayValue);
    Navigator.pop(context);
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
      body: Column(
        children: [
          // Display Area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_displayValue.isEmpty)
                    Text(
                      widget.hint ?? 'Digite um valor',
                      style: context.textStyles.headlineLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    FadeInWidget(
                      child: Text(
                        _displayValue,
                        style: context.textStyles.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  if (widget.minValue != null || widget.maxValue != null) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Min: ${widget.minValue ?? 0} - Max: ${widget.maxValue ?? '∞'}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Keyboard
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.only(
                  top: Radius.circular(AppSpacing.radiusXl),
                  bottom: Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.lg),
                  
                  // Number pad
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          _buildKeyRow(['1', '2', '3']),
                          SizedBox(height: AppSpacing.md),
                          _buildKeyRow(['4', '5', '6']),
                          SizedBox(height: AppSpacing.md),
                          _buildKeyRow(['7', '8', '9']),
                          SizedBox(height: AppSpacing.md),
                          _buildKeyRow([
                            widget.isDecimal ? '.' : 'C',
                            '0',
                            '⌫'
                          ]),
                        ],
                      ),
                    ),
                  ),

                  // Submit button
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: PrimaryButton(
                      text: 'Confirmar',
                      icon: Icons.check_rounded,
                      onPressed: _onSubmit,
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: _buildKey(key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == '⌫' || key == 'C' || key == '.';
    
    return AnimatedCard(
      onTap: () => _onKeyPress(key),
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial 
              ? context.colors.primaryContainer
              : context.colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: context.colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            key,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSpecial 
                  ? context.colors.onPrimaryContainer
                  : context.colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// Exemplo de uso:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CustomKeyboardScreen(
      title: 'Digite o Stake',
      hint: '\$0.00',
      isDecimal: true,
      minValue: 0.35,
      maxValue: 1000.0,
      onSubmit: (value) {
        print('Valor digitado: $value');
        setState(() {
          _stakeValue = double.parse(value);
        });
      },
    ),
  ),
);
*/