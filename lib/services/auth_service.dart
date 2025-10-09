import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final apiUser = await ApiService().fetchUser(email, password);
    if (apiUser == null) {
      throw Exception('User not found in external API');
    }

    final userDoc = await _firestore.collection('users').doc(apiUser['id']).get();
    if (userDoc.exists && userDoc.data()!['is_online'] == true) {
      throw Exception('User is already logged in on another device');
    }

    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).update({
      'is_online': true,
      'last_login': DateTime.now().toIso8601String(),
    });
  }

  Future<void> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
    required BuildContext context,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      ...userData,
      'is_online': true,
      'last_login': DateTime.now().toIso8601String(),
    });

    await userCredential.user?.updateDisplayName(userData['full_name']);
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'is_online': false,
      });
    }
    await _auth.signOut();
  }
}