// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkLastActivity();
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
        _updateLastActivity();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  // Verifica última atividade e desloga após 2 dias
  Future<void> _checkLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('lastActivity');
    
    if (lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final twoDays = 2 * 24 * 60 * 60 * 1000; // 2 dias em milissegundos
      
      if (now - lastActivity > twoDays) {
        await signOut();
      }
    }
  }

  // Atualiza última atividade
  Future<void> _updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastActivity', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateLastActivity();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String userType,
    required String birthDate,
    String? school,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phoneNumber,
    String? bio,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Gera código OTP inicial
      final otpCode = _generateOTP();

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'nickname': nickname,
        'userType': userType, // estudante, empreendedor, criador, profissional
        'birthDate': birthDate,
        'school': school,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'phoneNumber': phoneNumber,
        'bio': bio,
        'photoURL': null,
        'coverPhotoURL': null,
        'isPro': false,
        'isPremium': false,
        'otpEnabled': true,
        'otpCode': otpCode,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        // Estatísticas
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        // Configurações de privacidade
        'isProfilePublic': true,
        'allowMessages': true,
        'allowOrders': true,
      });

      await credential.user!.updateDisplayName(name);
      
      // Envia email de verificação com OTP
      await _sendOTPEmail(email, otpCode);
      
      await _updateLastActivity();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Gera código OTP de 6 dígitos
  String _generateOTP() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  // Envia email com OTP (simulação - usar serviço de email real em produção)
  Future<void> _sendOTPEmail(String email, String otp) async {
    // TODO: Implementar envio de email real
    debugPrint('OTP enviado para $email: $otp');
  }

  // Verifica OTP
  Future<bool> verifyOTP(String otp) async {
    if (_user == null || _userData == null) return false;

    try {
      final storedOTP = _userData!['otpCode'];
      if (otp == storedOTP) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'emailVerified': true,
          'otpCode': null,
        });
        await _user!.reload();
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  // Reenvia OTP
  Future<void> resendOTP() async {
    if (_user == null || _userData == null) return;

    final newOTP = _generateOTP();
    await _firestore.collection('users').doc(_user!.uid).update({
      'otpCode': newOTP,
    });
    
    await _sendOTPEmail(_userData!['email'], newOTP);
    await _loadUserData();
  }

  // Atualiza tipo OTP (habilitar/desabilitar)
  Future<void> updateOTPStatus(bool enabled) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'otpEnabled': enabled,
        'otpCode': enabled ? _generateOTP() : null,
      });
      await _loadUserData();
    } catch (e) {
      debugPrint('Error updating OTP status: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastActivity');
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? coverPhotoURL,
    String? bio,
    String? school,
    String? address,
    String? city,
    String? state,
    String? country,
    String? phoneNumber,
  }) async {
    if (_user == null) return;

    try {
      if (displayName != null) {
        await _user!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }

      final updates = <String, dynamic>{
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['name'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (coverPhotoURL != null) updates['coverPhotoURL'] = coverPhotoURL;
      if (bio != null) updates['bio'] = bio;
      if (school != null) updates['school'] = school;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (country != null) updates['country'] = country;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;

      await _firestore.collection('users').doc(_user!.uid).update(updates);
      await _loadUserData();
      await _updateLastActivity();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Atualiza última atividade no Firestore
  Future<void> updateLastActive() async {
    if (_user == null) return;
    
    await _firestore.collection('users').doc(_user!.uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    });
    await _updateLastActivity();
  }
}