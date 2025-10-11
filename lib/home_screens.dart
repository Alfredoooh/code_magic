import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  final Function(String) onThemeChange;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  HomeScreen({
    required this.onThemeChange,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAdmin = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _isAdmin = _userData?['admin'] ?? false;
        });
      }
    }
  }

  void _showProfileModal() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_userData?['photoURL'] ?? ''),
            ),
            SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Usuário',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            if (_userData?['isPro'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Conta Pro', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sair',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.line_horizontal_3),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Center(
          child: Text(
            'K Paga',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showProfileModal,
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_userData?['photoURL'] ?? ''),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('messages').snapshots(),
        builder: (context, snapshot) {
          int totalMessages = snapshot.data?.docs.length ?? 0;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Icon(CupertinoIcons.house_fill, size: 80, color: Colors.orange),
                SizedBox(height: 20),
                Text(
                  'Bem-vindo, ${user?.displayName ?? "Usuário"}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Estatísticas do App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 40),
                _buildStatCard('Total de Mensagens', totalMessages.toString(), CupertinoIcons.chat_bubble_2_fill),
                SizedBox(height: 16),
                _buildStatCard('Tipo de Conta', _userData?['isPro'] == true ? 'Pro ⭐' : 'Grátis', CupertinoIcons.person_circle_fill),
                if (_isAdmin) ...[
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminPanelScreen()),
                        );
                      },
                      icon: Icon(CupertinoIcons.shield_fill),
                      label: Text('Painel de Administrador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orange, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Opções',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(color: Theme.of(context).dividerColor),
              ListTile(
                leading: Icon(CupertinoIcons.paintbrush, color: Colors.orange),
                title: Text('Tema'),
                subtitle: Text('Claro / Escuro'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    widget.onThemeChange(value ? 'dark' : 'light');
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'theme': value ? 'dark' : 'light',
                      });
                    }
                  },
                  activeColor: Colors.orange,
                ),
              ),
              ListTile(
                leading: Icon(CupertinoIcons.globe, color: Colors.orange),
                title: Text('Idioma'),
                trailing: DropdownButton<String>(
                  value: widget.currentLanguage,
                  underline: SizedBox(),
                  dropdownColor: Theme.of(context).cardColor,
                  items: [
                    DropdownMenuItem(value: 'pt', child: Text('🇵🇹 Português')),
                    DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                    DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      widget.onLanguageChange(value);
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                          'language': value,
                        });
                      }
                    }
                  },
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'K Paga v1.0',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MARKETPLACE SCREEN ====================
class MarketplaceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.bag_fill, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Marketplace',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Em breve você poderá comprar e vender aqui',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEWS SCREEN ====================
class NewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Novidades', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.news_solid, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Novidades',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Fique atento às últimas notícias',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CHAT SCREEN ====================
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 100) {
      if (_showFab) setState(() => _showFab = false);
    } else {
      if (!_showFab) setState(() => _showFab = true);
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('messages').add({
        'text': _controller.text.trim(),
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? user.email?.split('@')[0] ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
        'editedAt': null,
      });
      _controller.clear();
      setState(() => _isComposing = false);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }

  void _editMessage(String messageId, String currentText) {
    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Editar Mensagem'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Digite a nova mensagem',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _firestore.collection('messages').doc(messageId).update({
                  'text': editController.text.trim(),
                  'edited': true,
                  'editedAt': FieldValue.serverTimestamp(),
                });
              }
              Navigator.pop(context);
            },
            child: Text('Salvar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _toggleReaction(String messageId, String reactionType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reactionRef = _firestore
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .doc('${user.uid}_$reactionType');

    final reactionDoc = await reactionRef.get();
    if (reactionDoc.exists) {
      await reactionRef.delete();
    } else {
      await reactionRef.set({
        'userId': user.uid,
        'type': reactionType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showReactionMenu(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Reações',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _reactionButton('👍', messageId, 'like'),
                _reactionButton('❤️', messageId, 'love'),
                _reactionButton('😂', messageId, 'laugh'),
                _reactionButton('😮', messageId, 'wow'),
                _reactionButton('👎', messageId, 'dislike'),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _reactionButton(String emoji, String messageId, String type) {
    return GestureDetector(
      onTap: () {
        _toggleReaction(messageId, type);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(emoji, style: TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    List<InlineSpan> spans = [];
    
    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _launchURL(word),
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      } else if (word.startsWith('*') && word.endsWith('*') && word.length > 2) {
        spans.add(
          TextSpan(
            text: word.substring(1, word.length - 1) + ' ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      } else if (word.startsWith('_') && word.endsWith('_') && word.length > 2) {
        spans.add(
          TextSpan(
            text: word.substring(1, word.length - 1) + ' ',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        );
      }
    });

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Chat Global', style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('userStatus').where('isOnline', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                int onlineCount = snapshot.data?.docs.length ?? 0;
                return Text(
                  '$onlineCount usuários online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://alfredoooh.github.io/database/gallery/image_background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro ao carregar mensagens', style: TextStyle(color: Colors.red)),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.orange));
                    }

                    final messages = snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.chat_bubble, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem ainda.\nSeja o primeiro a enviar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageDoc = messages[index];
                        final message = messageDoc.data() as Map<String, dynamic>;
                        final isMe = message['userId'] == user?.uid;
                        final messageId = messageDoc.id;

                        if (message['timestamp'] == null) return SizedBox.shrink();

                        final timestamp = message['timestamp'] as Timestamp;
                        final createdAt = timestamp.toDate();
                        final now = DateTime.now();
                        final difference = now.difference(createdAt);
                        final canEdit = isMe && difference.inMinutes < 5;

                        return GestureDetector(
                          onLongPress: () {
                            if (canEdit) {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: Icon(CupertinoIcons.pencil, color: Colors.orange),
                                        title: Text('Editar'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _editMessage(messageId, message['text']);
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(CupertinoIcons.smiley, color: Colors.orange),
                                        title: Text('Reagir'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showReactionMenu(messageId);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              _showReactionMenu(messageId);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 16,
                                    child: Text(
                                      (message['userName'] ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                if (!isMe) SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.orange : Color(0xFF1C1C1E),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                                        bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Text(
                                            message['userName'] ?? 'Usuário',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        if (!isMe) SizedBox(height: 4),
                                        _buildMessageText(message['text'] ?? '', isMe),
                                        if (message['edited'] == true)
                                          Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              'editado',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe ? Colors.white70 : Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: _firestore
                                              .collection('messages')
                                              .doc(messageId)
                                              .collection('reactions')
                                              .snapshots(),
                                          builder: (context, reactionSnapshot) {
                                            if (!reactionSnapshot.hasData || reactionSnapshot.data!.docs.isEmpty) {
                                              return SizedBox.shrink();
                                            }

                                            Map<String, int> reactionCounts = {};
                                            for (var doc in reactionSnapshot.data!.docs) {
                                              final type = (doc.data() as Map<String, dynamic>)['type'];
                                              reactionCounts[type] = (reactionCounts[type] ?? 0) + 1;
                                            }

                                            return Padding(
                                              padding: EdgeInsets.only(top: 8),
                                              child: Wrap(
                                                spacing: 4,
                                                children: reactionCounts.entries.map((entry) {
                                                  final emoji = {
                                                    'like': '👍',
                                                    'love': '❤️',
                                                    'laugh': '😂',
                                                    'wow': '😮',
                                                    'dislike': '👎',
                                                  }[entry.key] ?? '👍';
                                                  
                                                  return Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '$emoji ${entry.value}',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) SizedBox(width: 8),
                                if (isMe)
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 16,
                                    child: Text(
                                      'EU',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showFab ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _isComposing = true);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.all(16),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLines: null,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Mensagem',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              _sendMessage();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.orange, size: 32),
                          onPressed: () {
                            _sendMessage();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).then((_) => setState(() => _isComposing = false));
          },
          backgroundColor: Colors.orange,
          child: Icon(CupertinoIcons.pencil, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ==================== ADMIN PANEL SCREEN ====================
class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar usuários'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.purple));
          }

          final users = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;

              return Card(
                color: Theme.of(context).cardColor,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userData['photoURL'] ?? ''),
                    backgroundColor: Colors.orange,
                  ),
                  title: Text(
                    userData['displayName'] ?? 'Sem nome',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(userData['email'] ?? ''),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAdminSwitch(
                            'Administrador',
                            userData['admin'] ?? false,
                            (value) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .update({'admin': value});
                            },
                            Colors.purple,
                          ),
                          SizedBox(height: 12),
                          _buildAdminSwitch(
                            'Conta Pro',
                            userData['isPro'] ?? false,
                            (value) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .update({'isPro': value});
                            },
                            Colors.orange,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Informações Adicionais:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text('Tema: ${userData['theme'] ?? 'dark'}'),
                          Text('Idioma: ${userData['language'] ?? 'pt'}'),
                          Text('UID: ${userData['uid']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminSwitch(String title, bool value, Function(bool) onChanged, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }