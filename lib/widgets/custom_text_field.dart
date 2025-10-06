import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixTap;
  final TextAlign? textAlign;
  final int? maxLength;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSuffixTap,
    this.textAlign,
    this.maxLength,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF007AFF)
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
              color: const Color(0xFF000000),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              textAlign: widget.textAlign ?? TextAlign.start,
              maxLength: widget.maxLength,
              inputFormatters: widget.keyboardType == TextInputType.number
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? const Color(0xFF007AFF)
                        : Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                ),
                suffixIcon: widget.suffixIcon != null
                    ? GestureDetector(
                        onTap: widget.onSuffixTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            widget.suffixIcon,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                counterText: '',
                errorStyle: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              cursorColor: const Color(0xFF007AFF),
            ),
          ),
        ),
      ],
    );
  }
}
