import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../localization/app_localizations.dart';
import '../main/main_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _codeSent = false;
  String _verificationId = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.sendPhoneVerification(
      _phoneController.text,
      (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
      },
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bool success = await authProvider.verifyPhoneOTP(
      _otpController.text,
      _nameController.text.isNotEmpty ? _nameController.text : 'User',
      _nicknameController.text.isNotEmpty ? _nicknameController.text : '@user',
    );
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String t(String key) => AppLocalizations.translate(key, appProvider.currentLanguage);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDB52A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phone,
                    size: 50,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  _codeSent ? t('verify_otp') : t('enter_phone'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (!_codeSent) ...[
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Name (optional)',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nickname Field
                  TextFormField(
                    controller: _nicknameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Nickname (optional)',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Phone Number (+55...)',
                      prefixIcon: Icon(Icons.phone, color: Colors.grey[600]),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDB52A),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Input
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      inactiveFillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      selectedFillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      activeColor: const Color(0xFFFDB52A),
                      inactiveColor: Colors.grey,
                      selectedColor: const Color(0xFFFDB52A),
                    ),
                    enableActiveFill: true,
                    textStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                    ),
                    onChanged: (value) {},
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDB52A),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              t('verify'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Resend Code
                  TextButton(
                    onPressed: _sendOTP,
                    child: Text(
                      t('resend_code'),
                      style: const TextStyle(color: Color(0xFFFDB52A)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}