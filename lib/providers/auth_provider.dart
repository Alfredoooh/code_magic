import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationId;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
      await _setUserOnline(true);
    } else {
      if (_currentUser != null) {
        await _setUserOnline(false);
      }
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _setUserOnline(bool isOnline) async {
    if (_currentUser != null) {
      await _firestore.collection('onlineUsers').doc(_currentUser!.userId).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await _firestore.collection('users').doc(_currentUser!.userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Email/Password Sign In
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Email/Password Sign Up
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String nickname,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        // Create user document
        UserModel newUser = UserModel(
          userId: credential.user!.uid,
          name: name,
          nickname: nickname,
          email: email.trim(),
          phoneNumber: '',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
        
        // Create default settings
        UserSettings settings = UserSettings(userId: credential.user!.uid);
        await _firestore.collection('userSettings').doc(credential.user!.uid).set(settings.toMap());
        
        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  // Phone Authentication - Send OTP
  Future<void> sendPhoneVerification(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  // Phone Authentication - Verify OTP
  Future<bool> verifyPhoneOTP(String otp, String name, String nickname) async {
    try {
      if (_verificationId == null) return false;
      
      _isLoading = true;
      notifyListeners();
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user exists
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!doc.exists) {
          // Create new user
          UserModel newUser = UserModel(
            userId: userCredential.user!.uid,
            name: name,
            nickname: nickname,
            email: '',
            phoneNumber: userCredential.user!.phoneNumber ?? '',
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
          
          UserSettings settings = UserSettings(userId: userCredential.user!.uid);
          await _firestore.collection('userSettings').doc(userCredential.user!.uid).set(settings.toMap());
        }
        
        await _loadUserData(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _setUserOnline(false);
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}