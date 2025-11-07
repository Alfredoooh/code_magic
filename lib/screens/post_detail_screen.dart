// lib/screens/post_detail_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/expandable_link_text.dart';
import '../widgets/video_widget.dart';
import '../widgets/comments_widget.dart';
import '../services/image_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool isNews;
  const PostDetailScreen({super.key, required this.postId, this.isNews = false});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      if (!doc.exists) {
        setState(() { _error = 'Publicação não encontrada'; _loading = false; });
        return;
      }
      setState(() { _post = Post.fromFirestore(doc); _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error.isNotEmpty) return Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $_error')));
    final post = _post!;
    return Scaffold(
      appBar: AppBar(title: Text(post.title ?? 'Publicação')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        ListTile(
          leading: post.userAvatar != null ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(post.userAvatar!))) : const CircleAvatar(),
          title: Text(post.userName),
          subtitle: Text('${post.timestamp.day}/${post.timestamp.month} ${post.timestamp.hour}:${post.timestamp.minute}'),
        ),
        if (post.content.isNotEmpty) ExpandableLinkText(text: post.content),
        const SizedBox(height: 12),
        if (post.imageBase64 != null) ImageService.buildImageFromBase64(post.imageBase64!),
        if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...post.imageUrls!.map((u) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ImageService.buildImageFromUrl(u))).toList(),
        if (post.videoUrl != null) SizedBox(height: 200, child: VideoWidget(url: post.videoUrl!)),
        if (post.isNews && post.newsUrl != null)
          ElevatedButton(onPressed: () async {
            final uri = Uri.parse(post.newsUrl!);
            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
          }, child: const Text('Abrir notícia')),
        const SizedBox(height: 12),
        CommentsWidget(postId: post.id),
      ]),
    );
  }
}