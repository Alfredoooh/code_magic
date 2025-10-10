import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // 1. Validar na API externa primeiro
      final apiUser = await ApiService().fetchUser(email, password);
      if (apiUser == null) {
        throw Exception('Usuário não encontrado na API externa');
      }

      // 2. Fazer login no Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // 3. Verificar se já está logado em outro dispositivo
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['is_online'] == true) {
          // Fazer logout antes de lançar exceção
          await _auth.signOut();
          throw Exception('Usuário já está logado em outro dispositivo');
        }
        
        // Atualizar status de online
        await _firestore.collection('users').doc(userId).update({
          'is_online': true,
          'last_login': FieldValue.serverTimestamp(),
          'api_user_id': apiUser['id'], // Guardar ID da API para referência
        });
      } else {
        // Criar documento se não existir (caso de primeira autenticação)
        await _firestore.collection('users').doc(userId).set({
          'email': email,
          'is_online': true,
          'last_login': FieldValue.serverTimestamp(),
          'api_user_id': apiUser['id'],
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      // Tratar erros específicos do Firebase
      if (e.code == 'user-not-found') {
        throw Exception('Nenhum usuário encontrado com este email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Senha incorreta');
      } else if (e.code == 'user-disabled') {
        throw Exception('Usuário desabilitado');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Muitas tentativas. Tente novamente mais tarde');
      } else {
        throw Exception('Erro de autenticação: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
    required BuildContext context,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        ...userData,
        'is_online': true,
        'last_login': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName(userData['full_name']);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Senha muito fraca');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email já está em uso');
      } else {
        throw Exception('Erro ao criar conta: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao fazer cadastro: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'is_online': false,
          'last_logout': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      // Mesmo com erro, tenta fazer logout
      await _auth.signOut();
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  // Método auxiliar para verificar estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  User? get currentUser => _auth.currentUser;
}