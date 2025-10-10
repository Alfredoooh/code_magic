import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

/// App principal com tema escuro profundo
class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFF1F8A8A);
    return MaterialApp(
      title: 'Chat Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema escuro profundo
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0B0B0D),
        primaryColor: primary,
        colorScheme: ColorScheme.dark(
          primary: primary,
          background: Color(0xFF0B0B0D),
          surface: Color(0xFF111215),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF121214),
          labelStyle: TextStyle(color: Colors.white70),
          hintStyle: TextStyle(color: Colors.white38),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF0F1112),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF071014),
          elevation: 1,
          centerTitle: true,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.redAccent.shade700,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: AuthGate(),
    );
  }
}

/// Redireciona para tela de login ou chat conforme estado de autenticação
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return ChatScreen();
        return LoginScreen();
      },
    );
  }
}

/// Tela de login / registro
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await userCredential.user?.updateDisplayName(_nameController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      if (e.code == 'user-not-found') message = 'Usuário não encontrado';
      else if (e.code == 'wrong-password') message = 'Senha incorreta';
      else if (e.code == 'email-already-in-use') message = 'Email já está em uso';
      else if (e.code == 'weak-password') message = 'Senha muito fraca (mín. 6 caracteres)';
      else if (e.code == 'invalid-email') message = 'Email inválido';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone e título
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF071012),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline, size: 64, color: accent),
                      ),
                      SizedBox(height: 14),
                      Text(
                        _isLogin ? 'Entrar' : 'Criar Conta',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      SizedBox(height: 18),

                      // Nome (registro)
                      if (!_isLogin)
                        Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Digite seu nome';
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                          ],
                        ),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Digite seu email';
                          if (!value.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Senha
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Digite sua senha';
                          if (value.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      SizedBox(height: 18),

                      // Botão enviar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(_isLogin ? 'Entrar' : 'Criar Conta', style: TextStyle(fontSize: 16)),
                        ),
                      ),

                      // Alternar entre login/registro
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Não tem conta? Criar uma' : 'Já tem conta? Entrar',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela principal do chat
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('messages').add({
      'text': text,
      'userId': user.uid,
      'userEmail': user.email,
      'userName': user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final bgMe = Color(0xFF0DC0B3); // aqua-ish for my messages
    final bgOther = Color(0xFF1A1C1E); // dark bubble for others
    final textColorMe = Colors.black;
    final textColorOther = Colors.white70;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 320),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? bgMe : bgOther,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    message['userName'] ?? 'Usuário',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                  ),
                ),
              Text(
                message['text'] ?? '',
                style: TextStyle(fontSize: 16, color: isMe ? textColorMe : textColorOther),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Firebase'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                user?.displayName ?? user?.email?.split('@')[0] ?? 'Usuário',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensagens (stream)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar mensagens', style: TextStyle(color: Colors.white70)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 76, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'Nenhuma mensagem ainda.\nSeja o primeiro a enviar!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMe = data['userId'] == user?.uid;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(right: 8, left: 4),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF1F8A8A),
                              child: Text(
                                (data['userName'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        Expanded(child: _buildMessageBubble(data, isMe)),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF1F8A8A),
                              child: Text(
                                (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input de mensagem
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFF071014),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Color(0xFF0D0E10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Material(
                    color: Color(0xFF1F8A8A),
                    shape: CircleBorder(),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}