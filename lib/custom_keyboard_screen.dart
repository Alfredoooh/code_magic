// 2. custom_keyboard_screen.dart
// ========================================
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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

class _CustomKeyboardScreenState extends State<CustomKeyboardScreen> {
  late String _display;

  @override
  void initState() {
    super.initState();
    _display = widget.isInteger
        ? widget.initialValue.toInt().toString()
        : widget.initialValue.toStringAsFixed(2);
  }

  void _onKeyPress(String key) {
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
      widget.onConfirm(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '${widget.prefix ?? ''}$_display',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  _buildKeyboardRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildKeyboardRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildKeyboardRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  _buildKeyboardRow([widget.isInteger ? 'C' : '.', '0', '⌫']),
                  const SizedBox(height: 16),
                  _buildConfirmButton(),
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _onKeyPress(key),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _confirm,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0066FF),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(
          child: Text(
            'CONFIRMAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}