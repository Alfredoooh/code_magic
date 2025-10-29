// lib/custom_keyboard_screen.dart - Material Design 3
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class CustomKeyboardScreen extends StatefulWidget {
  final String title;
  final double initialValue;
  final double minValue;
  final String? prefix;
  final bool isInteger;
  final Function(double) onConfirm;

  const CustomKeyboardScreen({
    Key? key,
    required this.title,
    required this.initialValue,
    this.minValue = 0.0,
    this.prefix,
    this.isInteger = false,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CustomKeyboardScreen> createState() => _CustomKeyboardScreenState();
}

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen> {
  String _displayValue = '';

  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue.toString();
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
        if (!widget.isInteger && !_displayValue.contains('.')) {
          if (_displayValue.isEmpty) {
            _displayValue = '0.';
          } else {
            _displayValue += key;
          }
        }
      } else {
        // Number
        _displayValue += key;
      }
    });

    AppHaptics.light();
  }

  void _confirm() {
    final value = double.tryParse(_displayValue);
    if (value != null && value >= widget.minValue) {
      AppHaptics.success();
      widget.onConfirm(value);
    } else {
      AppHaptics.error();
      AppSnackbar.error(
        context,
        'Valor mínimo é ${widget.minValue.toStringAsFixed(2)}'
      );
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
      body: Column(
        children: [
          // Display Area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.md),
                  if (_displayValue.isEmpty)
                    Text(
                      'Digite um valor',
                      style: context.textStyles.headlineLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    FadeInWidget(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (widget.prefix != null)
                            Text(
                              widget.prefix!,
                              style: context.textStyles.headlineMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          Flexible(
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
                        ],
                      ),
                    ),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusXl),
                  topRight: Radius.circular(AppSpacing.radiusXl),
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
                  const SizedBox(height: AppSpacing.lg),

                  // Number pad
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        children: [
                          _buildKeyRow(['1', '2', '3']),
                          const SizedBox(height: AppSpacing.md),
                          _buildKeyRow(['4', '5', '6']),
                          const SizedBox(height: AppSpacing.md),
                          _buildKeyRow(['7', '8', '9']),
                          const SizedBox(height: AppSpacing.md),
                          _buildKeyRow([
                            widget.isInteger ? 'C' : '.',
                            '0',
                            '⌫'
                          ]),
                        ],
                      ),
                    ),
                  ),

                  // Submit button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: PrimaryButton(
                      text: 'Confirmar',
                      icon: Icons.check_rounded,
                      onPressed: _confirm,
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.minValue > 0) ...[
          Text(
            'Mínimo: ${widget.prefix ?? ''}${widget.minValue.toStringAsFixed(widget.isInteger ? 0 : 2)}',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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