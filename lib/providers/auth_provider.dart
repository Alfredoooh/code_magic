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
  bool _isInitialized = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  // CORRIGIDO: Verifica se o usuário precisa fazer verificação OTP
  bool get needsOTPVerification {
    if (_user == null || _userData == null) return false;

    // Se o email JÁ foi verificado PERMANENTEMENTE, não precisa de OTP NUNCA MAIS
    if (_userData!['isEmailVerified'] == true) return false;

    // Se o OTP está habilitado E não foi verificado, precisa verificar
    return _userData!['otpEnabled'] == true;
  }

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _user = _auth.currentUser;

      await _checkLastActivity();

      if (_user != null) {
        await _loadUserData();
        await _setOnlineStatus(true);
        await _updateLastActivity();
        await _saveLoginState(true);
      }

      _isInitialized = true;
      notifyListeners();

      _auth.authStateChanges().listen((User? user) async {
        _user = user;
        if (user != null) {
          await _loadUserData();
          await _setOnlineStatus(true);
          await _updateLastActivity();
          await _saveLoginState(true);
        } else {
          await _setOnlineStatus(false);
          _userData = null;
          await _saveLoginState(false);
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', isLoggedIn);
      if (isLoggedIn && _user != null) {
        await prefs.setString('user_uid', _user!.uid);
        await prefs.setString('user_email', _user!.email ?? '');
      } else {
        await prefs.remove('user_uid');
        await prefs.remove('user_email');
      }
    } catch (e) {
      debugPrint('Erro ao salvar estado de login: $e');
    }
  }

  Future<void> _checkLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getInt('lastActivity');
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (lastActivity != null && isLoggedIn) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final twoDays = 2 * 24 * 60 * 60 * 1000;

        if (now - lastActivity > twoDays) {
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar última atividade: $e');
    }
  }

  Future<void> _updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastActivity', DateTime.now().millisecondsSinceEpoch);

      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar lastActive: $e');
    }
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao atualizar status online: $e');
    }
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
      await _saveLoginState(true);
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

      final otpCode = _generateOTP();

      // CORRIGIDO: Usa isEmailVerified (consistente)
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'nickname': nickname,
        'userType': userType,
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
        'isEmailVerified': false, // CORRIGIDO: Nome consistente
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'isProfilePublic': true,
        'allowMessages': true,
        'allowOrders': true,
      });

      await credential.user!.updateDisplayName(name);
      await _sendOTPEmail(email, otpCode);
      await _updateLastActivity();
      await _saveLoginState(true);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  String _generateOTP() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  Future<void> _sendOTPEmail(String email, String otp) async {
    debugPrint('OTP enviado para $email: $otp');
  }

  // CORRIGIDO: Marca permanentemente como verificado
  Future<bool> verifyOTP(String otp) async {
    if (_user == null || _userData == null) return false;

    try {
      final storedOTP = _userData!['otpCode'];
      if (otp == storedOTP) {
        // MARCA PERMANENTEMENTE como verificado e DESATIVA o OTP
        await _firestore.collection('users').doc(_user!.uid).update({
          'isEmailVerified': true, // Campo permanente
          'otpEnabled': false, // DESATIVA o OTP após verificação
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

  Future<void> resendOTP() async {
    if (_user == null || _userData == null) return;

    final newOTP = _generateOTP();
    await _firestore.collection('users').doc(_user!.uid).update({
      'otpCode': newOTP,
    });

    await _sendOTPEmail(_userData!['email'], newOTP);
    await _loadUserData();
  }

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

  // CORRIGIDO: NÃO reativa o OTP no logout se já foi verificado
  Future<void> signOut() async {
    if (_user != null) {
      try {
        // VERIFICA se o email foi verificado ANTES de reativar OTP
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        final isVerified = doc.data()?['isEmailVerified'] == true;

        // SÓ reativa o OTP se o email NUNCA foi verificado
        if (!isVerified) {
          final newOTP = _generateOTP();
          await _firestore.collection('users').doc(_user!.uid).update({
            'otpEnabled': true,
            'otpCode': newOTP,
            'isOnline': false,
          });

          // Envia novo código por email
          if (_userData != null && _userData!['email'] != null) {
            await _sendOTPEmail(_userData!['email'], newOTP);
          }
        } else {
          // Se já foi verificado, apenas atualiza o status online
          await _firestore.collection('users').doc(_user!.uid).update({
            'isOnline': false,
          });
        }
      } catch (e) {
        debugPrint('Erro ao atualizar status no logout: $e');
      }
    }

    await _setOnlineStatus(false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastActivity');
    await prefs.remove('isLoggedIn');
    await prefs.remove('user_uid');
    await prefs.remove('user_email');

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

  Future<void> updateLastActive() async {
    if (_user == null) return;

    await _firestore.collection('users').doc(_user!.uid).update({
      'lastActive': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
    await _updateLastActivity();
  }
}