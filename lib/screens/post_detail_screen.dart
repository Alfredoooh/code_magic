// lib/screens/post_detail_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/expandable_link_text.dart';
import '../widgets/video_widget.dart';
import '../widgets/comments_widget.dart';
import '../widgets/custom_icons.dart';
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
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      if (!doc.exists) {
        setState(() {
          _error = 'Publicação não encontrada';
          _loading = false;
        });
        return;
      }
      setState(() {
        _post = Post.fromFirestore(doc);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sharePost() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em breve'),
        backgroundColor: Color(0xFF1877F2),
      ),
    );
  }

  Future<void> _bookmarkPost() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post salvo nos favoritos'),
        backgroundColor: Color(0xFF31A24C),
      ),
    );
  }

  // Formatação de texto estilo WhatsApp
  List<TextSpan> _parseFormattedText(String text, Color textColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*([^\*]+)\*|_([^_]+)_|~([^~]+)~|```([^`]+)```');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: textColor),
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(decoration: TextDecoration.lineThrough, color: textColor),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: textColor.withOpacity(0.1),
            color: textColor,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: textColor),
      ));
    }

    return spans.isEmpty
        ? [TextSpan(text: text, style: TextStyle(color: textColor))]
        : spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.string(
              CustomIcons.arrowBack,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(
                CustomIcons.error,
                width: 64,
                height: 64,
                colorFilter: ColorFilter.mode(
                  secondaryColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Erro: $_error',
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final post = _post!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowBack,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          post.title ?? 'Publicação',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.string(
              CustomIcons.bookmark,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            onPressed: _bookmarkPost,
          ),
          IconButton(
            icon: SvgPicture.string(
              CustomIcons.share,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            onPressed: _sharePost,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card do autor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1877F2),
                  backgroundImage: post.userAvatar != null
                      ? MemoryImage(base64Decode(post.userAvatar!))
                      : null,
                  child: post.userAvatar == null
                      ? Text(
                          post.userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          SvgPicture.string(
                            CustomIcons.schedule,
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(
                              secondaryColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.timestamp.day}/${post.timestamp.month}/${post.timestamp.year} às ${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Conteúdo
          if (post.content.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText.rich(
                TextSpan(
                  children: _parseFormattedText(post.content, textColor),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Imagem base64
          if (post.imageBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageService.buildImageFromBase64(post.imageBase64!),
            ),

          // Imagens por URL
          if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
            ...post.imageUrls!.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageService.buildImageFromUrl(url),
                  ),
                )),

          // Vídeo
          if (post.videoUrl != null)
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoWidget(url: post.videoUrl!),
              ),
            ),

          // Botão para abrir notícia
          if (post.isNews && post.newsUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.parse(post.newsUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SvgPicture.string(
                            CustomIcons.openInNew,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFFF9800),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Abrir notícia completa',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Acessar fonte original',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SvgPicture.string(
                          CustomIcons.arrowForward,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            secondaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Comentários
          CommentsWidget(postId: post.id),
        ],
      ),
    );
  }
}