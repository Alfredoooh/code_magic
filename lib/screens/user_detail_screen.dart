// lib/screens/user_detail_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _userData;
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final snap = await FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: widget.userId).orderBy('timestamp', descending: true).get();
    setState(() {
      _userData = doc.exists ? doc.data() : null;
      _posts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(_userData?['name'] ?? 'Usuário')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        ListTile(
          leading: _userData?['photoBase64'] != null ? CircleAvatar(radius: 30, backgroundImage: MemoryImage(base64Decode(_userData!['photoBase64']))) : CircleAvatar(radius: 30, child: Text((_userData?['name'] ?? 'U').toString().substring(0,1).toUpperCase())),
          title: Text(_userData?['name'] ?? ''),
          subtitle: Text(_userData?['email'] ?? ''),
        ),
        const SizedBox(height: 12),
        const Text('Publicações', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._posts.map((p) => PostCard(post: p)).toList(),
      ]),
    );
  }
}