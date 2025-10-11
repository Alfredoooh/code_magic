import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verificar acesso do usuário
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['access'] == false) {
          await FirebaseAuth.instance.signOut();
          throw Exception('Acesso negado. Entre em contato com o administrador.');
        }
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        // Criar documento do usuário no Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'full_name': _nameController.text.trim(),
          'access': true,
          'created_at': FieldValue.serverTimestamp(),
          'profile_image': '',
          'role': 'user',
          'blocked': false,
          'failed_attempts': 0,
          'theme': 'dark',
          'language': 'pt',
          'tokens': 50,
          'is_pro': false,
          'pro_expiration': null,
          'is_admin': false,
          'online': true,
          'last_seen': FieldValue.serverTimestamp(),
        });
      }

      // Atualizar status online
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'online': true,
          'last_seen': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email já está em uso';
      } else if (e.code == 'weak-password') {
        message = 'Senha muito fraca (mín. 6 caracteres)';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Card(
                  color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo do App
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage('https://alfredoooh.github.io/database/gallery/app_icon.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            _isLogin ? 'Entrar' : 'Criar Conta',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 32),
                          if (!_isLogin)
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextFormField(
                                controller: _nameController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  labelText: 'Nome',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.person_rounded, color: Color(0xFFFF444F)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Digite seu nome';
                                  return null;
                                },
                              ),
                            ),
                          if (!_isLogin) SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.email_rounded, color: Color(0xFFFF444F)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Digite seu email';
                                if (!value.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF2C2C2C) : Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                labelStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.lock_rounded, color: Color(0xFFFF444F)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Digite sua senha';
                                if (value.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF444F),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      _isLogin ? 'Entrar' : 'Criar Conta',
                                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin ? 'Não tem conta? Criar uma' : 'Já tem conta? Entrar',
                              style: TextStyle(fontSize: 16, color: Color(0xFFFF444F), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 28),
                onPressed: () {
                  // Fechar a tela (voltar ou minimizar)
                  Navigator.of(context).canPop() ? Navigator.of(context).pop() : null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}