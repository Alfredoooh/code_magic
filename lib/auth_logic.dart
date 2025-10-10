import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Provider para gerenciar autenticação e dados do usuário
class AuthLogic extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  // Dados do usuário em cache
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  // Tema do usuário
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  AuthLogic() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
        _isDarkMode = false;
      }
      notifyListeners();
    });
  }

  // Carregar dados do usuário do Firestore
  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _isDarkMode = _userData?['isDarkMode'] ?? false;
      } else {
        // Criar documento do usuário se não existir
        await _createUserDocument();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
    }
  }

  // Criar documento do usuário no Firestore
  Future<void> _createUserDocument() async {
    if (currentUser == null) return;

    _userData = {
      'uid': currentUser!.uid,
      'email': currentUser!.email,
      'displayName': currentUser!.displayName ?? currentUser!.email?.split('@')[0],
      'photoURL': currentUser!.photoURL,
      'isDarkMode': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(currentUser!.uid).set(_userData!);
    notifyListeners();
  }

  // Login
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Erro ao fazer login';
    }
  }

  // Cadastro
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user?.updateDisplayName(name.trim());
      await _createUserDocument();
      
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'Erro ao criar conta';
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    _userData = null;
    _isDarkMode = false;
    notifyListeners();
  }

  // Alterar tema
  Future<void> toggleTheme() async {
    if (currentUser == null) return;

    _isDarkMode = !_isDarkMode;
    
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'isDarkMode': _isDarkMode,
    });

    if (_userData != null) {
      _userData!['isDarkMode'] = _isDarkMode;
    }

    notifyListeners();
  }

  // Atualizar foto de perfil
  Future<String?> updateProfileImage() async {
    if (currentUser == null) return 'Usuário não autenticado';

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return null;

      // Upload para Firebase Storage
      final ref = _storage.ref().child('profile_images/${currentUser!.uid}.jpg');
      await ref.putFile(File(image.path));
      
      final photoURL = await ref.getDownloadURL();

      // Atualizar perfil
      await currentUser!.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'photoURL': photoURL,
      });

      if (_userData != null) {
        _userData!['photoURL'] = photoURL;
      }

      notifyListeners();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao atualizar foto: $e';
    }
  }

  // Atualizar nome
  Future<String?> updateDisplayName(String name) async {
    if (currentUser == null) return 'Usuário não autenticado';

    try {
      await currentUser!.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'displayName': name.trim(),
      });

      if (_userData != null) {
        _userData!['displayName'] = name.trim();
      }

      notifyListeners();
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao atualizar nome: $e';
    }
  }

  // Obter nome de exibição
  String get displayName {
    return currentUser?.displayName ?? 
           _userData?['displayName'] ?? 
           currentUser?.email?.split('@')[0] ?? 
           'Usuário';
  }

  // Obter foto de perfil
  String? get photoURL {
    return currentUser?.photoURL ?? _userData?['photoURL'];
  }

  // Obter inicial do nome
  String get nameInitial {
    return displayName[0].toUpperCase();
  }

  // Salvar dados personalizados do usuário
  Future<void> saveUserData(String key, dynamic value) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      key: value,
    });

    if (_userData != null) {
      _userData![key] = value;
    }

    notifyListeners();
  }

  // Obter dados personalizados do usuário
  dynamic getUserData(String key) {
    return _userData?[key];
  }

  // Mensagens de erro
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca (mín. 6 caracteres)';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      default:
        return 'Erro ao autenticar';
    }
  }
}