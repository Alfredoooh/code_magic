import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupsScreen extends StatefulWidget {
  final String language;

  const GroupsScreen({required this.language});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _showFAB = true;
  ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _userData;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadActiveUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection.toString().contains('forward')) {
        if (!_showFAB) setState(() => _showFAB = true);
      } else {
        if (_showFAB) setState(() => _showFAB = false);
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  Future<void> _loadActiveUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('last_active', isGreaterThan: DateTime.now().subtract(Duration(minutes: 5)))
        .get();
    if (mounted) {
      setState(() {
        _activeUsers = snapshot.docs.length;
      });
    }
  }

  void _createGroup() {
    if (_userData?['is_pro'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Apenas usuários PRO podem criar grupos'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                  SizedBox(width: 6),
                  Text(
                    '$_activeUsers online',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Spacer(),
            Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar grupos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
          }

          final groups = snapshot.data?.docs ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum grupo ainda',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _userData?['is_pro'] == true
                        ? 'Crie o primeiro grupo!'
                        : 'Apenas usuários PRO podem criar grupos',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.all(8),
            itemCount: groups.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final group = groups[index].data() as Map<String, dynamic>;
              return _buildGroupCard(group, groups[index].id);
            },
          );
        },
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showFAB ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: _createGroup,
          backgroundColor: Color(0xFFFF444F),
          child: Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, String groupId) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(
                groupId: groupId,
                groupName: group['name'] ?? 'Grupo',
                groupImage: group['image'] ?? '',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFF444F).withOpacity(0.2),
                backgroundImage: group['image'] != null && group['image'].isNotEmpty
                    ? NetworkImage(group['image'])
                    : null,
                child: group['image'] == null || group['image'].isEmpty
                    ? Icon(Icons.group_rounded, color: Color(0xFFFF444F))
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? 'Grupo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      group['description'] ?? 'Sem descrição',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _CreateGroupDialog extends StatefulWidget {
  @override
  __CreateGroupDialogState createState() => __CreateGroupDialogState();
}

class __CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Digite o nome do grupo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('groups').add({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'created_by': FirebaseAuth.instance.currentUser?.uid,
        'created_at': FieldValue.serverTimestamp(),
        'members': [FirebaseAuth.instance.currentUser?.uid],
        'image': '',
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grupo criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar grupo'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Criar Grupo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome do Grupo',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF444F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Criar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupImage;

  const ChatRoomScreen({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  Map<String, DateTime> _messageTimestamps = {};
  final int _editTimeLimit = 300;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateLastActive();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  Future<void> _updateLastActive() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'last_active': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> _checkTokenLimit() async {
    if (_userData?['is_pro'] == true) return true;

    final tokensUsed = _userData?['tokens_used_today'] ?? 0;
    final maxTokens = _userData?['max_daily_tokens'] ?? 50;

    if (tokensUsed >= maxTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Limite diário de tokens atingido. Upgrade para PRO!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
      'tokens_used_today': FieldValue.increment(1),
    });

    return true;
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    if (!await _checkTokenLimit()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final messageText = _controller.text.trim();
      _controller.clear();

      final docRef = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': messageText,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': _userData?['username'] ?? user.email?.split('@')[0] ?? 'Usuário',
        'userImage': _userData?['profile_image'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'dislikes': [],
        'edited': false,
      });

      _messageTimestamps[docRef.id] = DateTime.now();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
    }
  }

  bool _canEdit(String messageId) {
    if (!_messageTimestamps.containsKey(messageId)) return false;
    final diff = DateTime.now().difference(_messageTimestamps[messageId]!);
    return diff.inSeconds <= _editTimeLimit;
  }

  void _editMessage(String messageId, String currentText) {
    if (!_canEdit(messageId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tempo para editar expirado (5 minutos)')),
      );
      return;
    }

    final editController = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Mensagem'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .doc(messageId)
                  .update({
                'text': editController.text.trim(),
                'edited': true,
              });
              Navigator.pop(context);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _toggleReaction(String messageId, bool isLike) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    final data = doc.data() as Map<String, dynamic>;

    List likes = data['likes'] ?? [];
    List dislikes = data['dislikes'] ?? [];

    if (isLike) {
      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
        dislikes.remove(user.uid);
      }
    } else {
      if (dislikes.contains(user.uid)) {
        dislikes.remove(user.uid);
      } else {
        dislikes.add(user.uid);
        likes.remove(user.uid);
      }
    }

    await messageRef.update({
      'likes': likes,
      'dislikes': dislikes,
    });
  }

  Widget _buildMessageText(String text, bool isMe) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    List<InlineSpan> spans = [];

    text.split(' ').forEach((word) {
      if (urlPattern.hasMatch(word)) {
        spans.add(
          WidgetSpan(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(word);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: Colors.blue,
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
              fontSize: 16,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: word + ' ', style: TextStyle(fontSize: 16)));
      }
    });

    return RichText(text: TextSpan(children: spans, style: TextStyle(color: isMe ? Colors.white : Colors.black87)));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFF444F).withOpacity(0.2),
              backgroundImage: widget.groupImage.isNotEmpty
                  ? NetworkImage(widget.groupImage)
                  : null,
              child: widget.groupImage.isEmpty
                  ? Icon(Icons.group_rounded, color: Color(0xFFFF444F), size: 20)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.groupName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://alfredoooh.github.io/database/gallery/image_background.jpg'),
            fit: BoxFit.cover,
            opacity: isDark ? 0.05 : 0.03,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar mensagens'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Sem mensagens ainda',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final message = messageDoc.data() as Map<String, dynamic>;
                      final isMe = message['userId'] == user?.uid;

                      if (message['timestamp'] == null) return SizedBox.shrink();

                      return _buildMessage(message, messageDoc.id, isMe);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1A1A1A) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(fontSize: 16),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Mensagem',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, String messageId, bool isMe) {
    final likes = List.from(message['likes'] ?? []);
    final dislikes = List.from(message['dislikes'] ?? []);
    final isLiked = likes.contains(_auth.currentUser?.uid);
    final isDisliked = dislikes.contains(_auth.currentUser?.uid);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message['userImage']?.isNotEmpty == true
                  ? NetworkImage(message['userImage'])
                  : null,
              backgroundColor: Color(0xFFFF444F),
              child: message['userImage']?.isEmpty != false
                  ? Text(
                      (message['userName'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : null,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isMe ? () => _editMessage(messageId, message['text']) : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Color(0xFFFF444F)
                      : (isDark ? Color(0xFF1C1C1E) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          message['userName'] ?? 'Usuário',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFFFF444F),
                          ),
                        ),
                      ),
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
                    if (likes.isNotEmpty || dislikes.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (likes.isNotEmpty) ...[
                              Icon(Icons.thumb_up_rounded, size: 14, color: isLiked ? Colors.blue : Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                '${likes.length}',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(width: 12),
                            ],
                            if (dislikes.isNotEmpty) ...[
                              Icon(Icons.thumb_down_rounded, size: 14, color: isDisliked ? Colors.red : Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                '${dislikes.length}',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!isMe)
            PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _toggleReaction(messageId, true),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_up_rounded, color: isLiked ? Colors.blue : null),
                      SizedBox(width: 8),
                      Text('Curtir'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _toggleReaction(messageId, false),
                  child: Row(
                    children: [
                      Icon(Icons.thumb_down_rounded, color: isDisliked ? Colors.red : null),
                      SizedBox(width: 8),
                      Text('Não curtir'),
                    ],
                  ),
                ),
              ],
            ),
          if (isMe) SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage: _userData?['profile_image']?.isNotEmpty == true
                  ? NetworkImage(_userData!['profile_image'])
                  : null,
              backgroundColor: Color(0xFFFF444F),
              child: _userData?['profile_image']?.isEmpty != false
                  ? Text(
                      (_auth.currentUser?.displayName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
