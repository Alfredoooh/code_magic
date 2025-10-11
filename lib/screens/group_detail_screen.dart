import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    required this.groupId,
    required this.groupName,
  });

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGroup();
  }

  Future<void> _initializeGroup() async {
    await _loadUserData();
    await _loadGroupData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() => _userData = doc.data());
        }
      } catch (e) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<void> _loadGroupData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (doc.exists) {
        setState(() => _groupData = doc.data());
      }
    } catch (e) {
      print('Erro ao carregar dados do grupo: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Verificar se o usuário é membro do grupo
    if (_groupData != null) {
      final members = List.from(_groupData!['members'] ?? []);
      if (!members.contains(currentUser.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você não é membro deste grupo'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    // Verificar tokens para usuários não-PRO
    if (_userData?['pro'] != true) {
      if ((_userData?['tokens'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tokens insuficientes'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'tokens': FieldValue.increment(-1),
        });
        // Atualizar localmente
        if (_userData != null) {
          _userData!['tokens'] = (_userData!['tokens'] ?? 0) - 1;
        }
      } catch (e) {
        print('Erro ao decrementar tokens: $e');
      }
    }

    final messageText = _controller.text.trim();
    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUser.uid,
        'senderName': _userData?['username'] ?? 'Usuário',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'edited': false,
      });

      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem'), backgroundColor: Colors.red),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _likeMessage(String messageId, List likedBy) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (likedBy.contains(currentUser.uid)) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId)
            .update({
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId)
            .update({
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Erro ao curtir mensagem: $e');
    }
  }

  Future<void> _editMessage(String messageId, String currentText, DateTime timestamp) async {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não é possível editar após 5 minutos'), backgroundColor: Colors.red),
      );
      return;
    }

    final controller = TextEditingController(text: currentText);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        title: Text('Editar Mensagem', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Digite a nova mensagem',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('messages')
                      .doc(messageId)
                      .update({
                    'text': controller.text.trim(),
                    'edited': true,
                  });
                  Navigator.pop(context);
                } catch (e) {
                  print('Erro ao editar mensagem: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF444F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
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
              backgroundColor: Colors.green,
              child: Icon(Icons.group_rounded, color: Colors.white, size: 50),
            ),
            SizedBox(height: 16),
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${_groupData?['members']?.length ?? 0}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF444F),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                  }

                  final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                  final members = List<String>.from(groupData?['members'] ?? []);

                  if (members.isEmpty) {
                    return Center(child: Text('Nenhum membro', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(members[index]).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                            return SizedBox.shrink();
                          }

                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          final isOnline = userData['isOnline'] == true;
                          final isCreator = members[index] == groupData?['createdBy'];

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Color(0xFFFF444F),
                                    backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                                        ? NetworkImage(userData['profile_image'])
                                        : null,
                                    child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                                        ? Text(
                                            (userData['username'] ?? 'U')[0].toUpperCase(),
                                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5), width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userData['username'] ?? 'Usuário',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCreator)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 12),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
              onTap: () async {
                try {
                  final uri = Uri.parse(word);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  print('Erro ao abrir URL: $e');
                }
              },
              child: Text(
                word + ' ',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 15,
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
              fontSize: 15,
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
              fontSize: 15,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word + ' ',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        );
      }
    });

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF444F))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showGroupInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.groupName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox.shrink();
                  final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                  final members = List.from(groupData?['members'] ?? []);
                  return Text(
                    '${members.length} membros',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: _showGroupInfo,
          ),
        ],
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
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma mensagem ainda',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Seja o primeiro a enviar uma mensagem!',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final message = messageDoc.data() as Map<String, dynamic>;
                      final isMe = message['senderId'] == currentUser?.uid;
                      final timestamp = message['timestamp'] as Timestamp?;
                      final likes = message['likes'] ?? 0;
                      final likedBy = List.from(message['likedBy'] ?? []);
                      final isLiked = likedBy.contains(currentUser?.uid);
                      final isEdited = message['edited'] == true;

                      if (timestamp == null) return SizedBox.shrink();

                      return GestureDetector(
                        onLongPress: () {
                          if (isMe) {
                            _editMessage(messageDoc.id, message['text'], timestamp.toDate());
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? Color(0xFFFF444F) : (isDark ? Color(0xFF1A1A1A) : Colors.white),
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
                                            message['senderName'] ?? 'Usuário',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Color(0xFFFF444F),
                                            ),
                                          ),
                                        ),
                                      _buildMessageText(message['text'] ?? '', isMe),
                                      if (isEdited)
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
                                      if (likes > 0)
                                        Padding(
                                          padding: EdgeInsets.only(top: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                size: 14,
                                                color: isMe ? Colors.white : Colors.red,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '$likes',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _likeMessage(messageDoc.id, likedBy),
                                child: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: isLiked ? Colors.red : Colors.grey,
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Mensagem',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}