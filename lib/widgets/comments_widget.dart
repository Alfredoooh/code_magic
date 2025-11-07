// lib/widgets/comments_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';

class CommentsWidget extends StatefulWidget {
  final String postId;
  const CommentsWidget({super.key, required this.postId});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
          if (!snapshot.hasData) return const SizedBox();
          final docs = snapshot.data!.docs;
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              final comment = Comment.fromFirestore(d);
              return ListTile(
                leading: CircleAvatar(
                  child: comment.userAvatar != null ? Image.memory(base64Decode(comment.userAvatar!)) : Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U'),
                ),
                title: Text(comment.userName),
                subtitle: Text(comment.content),
                trailing: Text(_formatTimestamp(comment.timestamp)),
              );
            },
          );
        },
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Escreve um comentário...'))),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: uid == null ? null : () async {
            final text = _ctrl.text.trim();
            if (text.isEmpty) return;
            final now = FieldValue.serverTimestamp();
            await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
              'postId': widget.postId,
              'userId': uid,
              'userName': auth.userData?['name'] ?? 'Usuário',
              'userAvatar': auth.userData?['photoBase64'] ?? null,
              'content': text,
              'timestamp': now,
              'likes': 0,
              'likedBy': [],
            });
            await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'comments': FieldValue.increment(1)});
            _ctrl.clear();
          },
        ),
      ])
    ]);
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }
}