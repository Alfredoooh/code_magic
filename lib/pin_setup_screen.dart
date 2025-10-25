// pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({Key? key}) : super(key: key);

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  
  bool _isConfirmStep = false;
  String _firstPin = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
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
        return;
      }
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
        Navigator.pop(context, _firstPin);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isConfirmStep ? 'Confirmar PIN' : 'Criar PIN',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 32),
              Text(
                _isConfirmStep 
                    ? 'Digite o PIN novamente'
                    : 'Crie um PIN de segurança',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isConfirmStep
                    ? 'Confirme seu PIN para continuar'
                    : 'Mínimo de 6 caracteres',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _isConfirmStep ? _confirmController : _pinController,
                  focusNode: _isConfirmStep ? _confirmFocusNode : _pinFocusNode,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onPinSubmit(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onPinSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isConfirmStep ? 'Confirmar' : 'Continuar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}