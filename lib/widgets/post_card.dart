// lib/widgets/post_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/post_service.dart';
import '../widgets/expandable_link_text.dart';
import '../widgets/video_widget.dart';
import '../services/image_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/user_detail_screen.dart';
import 'custom_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _imageQuality;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty) {
      _analyzeImageQuality(widget.post.imageUrls!.first);
    }
  }

  Future<void> _analyzeImageQuality(String imageUrl) async {
    try {
      final image = NetworkImage(imageUrl);
      final stream = image.resolve(const ImageConfiguration());
      
      stream.addListener(ImageStreamListener((info, _) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        
        setState(() {
          _imageSize = Size(width, height);
          
          // Análise de qualidade baseada em resolução
          final pixels = width * height;
          if (pixels < 300 * 300) {
            _imageQuality = 'low'; // Imagem pequena/baixa qualidade
          } else if (pixels < 800 * 800) {
            _imageQuality = 'medium'; // Qualidade média
          } else {
            _imageQuality = 'high'; // Alta qualidade
          }
        });
      }));
    } catch (e) {
      print('Erro ao analisar imagem: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? const Color(0xFFE7E9EA) : const Color(0xFF0F1419);
    final secondaryColor = isDark ? const Color(0xFF71767B) : const Color(0xFF536471);
    final hoverColor = isDark ? const Color(0xFF16181C) : const Color(0xFFF7F9F9);
    final postService = PostService();

    final isLiked = auth.user != null ? widget.post.isLikedBy(auth.user!.uid) : false;

    // Para notícias sem imagem
    if (widget.post.isNews && (widget.post.imageUrls == null || widget.post.imageUrls!.isEmpty)) {
      return _buildCompactNewsCard(context, isDark, textColor, secondaryColor, bgColor);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: widget.post.isNews
            ? () async {
                if (widget.post.newsUrl != null) {
                  final uri = Uri.parse(widget.post.newsUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              }
            : null,
        hoverColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.post.isNews
                        ? null
                        : () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => 
                                  UserDetailScreen(userId: widget.post.userId),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOutCubic;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(position: animation.drive(tween), child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4),
                      backgroundImage: widget.post.userAvatar != null
                          ? MemoryImage(base64Decode(widget.post.userAvatar!))
                          : null,
                      child: widget.post.userAvatar == null
                          ? Icon(
                              widget.post.isNews ? Icons.article : Icons.person,
                              color: secondaryColor,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.post.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.post.isNews) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 18,
                                color: isDark ? const Color(0xFF1D9BF0) : const Color(0xFF1D9BF0),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Text(
                              '· ${_formatTimestamp(widget.post.timestamp)}',
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (auth.user?.uid == widget.post.userId && !widget.post.isNews)
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: secondaryColor, size: 20),
                      onPressed: () => _showOptions(context),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Content
              if (widget.post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: ExpandableLinkText(text: widget.post.content),
                ),

              // News Title
              if (widget.post.isNews && widget.post.title != null)
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 8),
                  child: Text(
                    widget.post.title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textColor,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Image - Adaptável baseado na qualidade
              if (widget.post.imageBase64 != null)
                _buildImageWidget(
                  context,
                  postService,
                  isDark,
                  Image.memory(
                    base64Decode(widget.post.imageBase64!),
                    fit: BoxFit.cover,
                  ),
                )
              else if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty)
                _buildImageWidget(
                  context,
                  postService,
                  isDark,
                  ImageService.buildImageFromUrl(
                    widget.post.imageUrls!.first,
                    fit: BoxFit.cover,
                  ),
                ),

              // Video
              if (widget.post.videoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VideoWidget(url: widget.post.videoUrl!),
                    ),
                  ),
                ),

              // Actions
              if (!widget.post.isNews)
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 8, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.chat_bubble_outline,
                        count: widget.post.comments,
                        color: secondaryColor,
                        activeColor: const Color(0xFF1D9BF0),
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => 
                                PostDetailScreen(postId: widget.post.id),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(position: animation.drive(tween), child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        count: widget.post.likes,
                        color: secondaryColor,
                        activeColor: const Color(0xFFF91880),
                        isActive: isLiked,
                        onTap: auth.user == null
                            ? null
                            : () => postService.toggleLike(widget.post.id, auth.user!.uid),
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.repeat,
                        count: widget.post.shares,
                        color: secondaryColor,
                        activeColor: const Color(0xFF00BA7C),
                        onTap: () => postService.sharePost(widget.post),
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.ios_share,
                        count: 0,
                        color: secondaryColor,
                        activeColor: const Color(0xFF1D9BF0),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(
    BuildContext context,
    PostService postService,
    bool isDark,
    Widget image,
  ) {
    // Determina o tamanho baseado na qualidade da imagem
    double? height;
    BoxFit fit = BoxFit.cover;

    if (_imageQuality == 'low') {
      height = 200; // Imagem pequena para baixa qualidade
      fit = BoxFit.contain;
    } else if (_imageQuality == 'medium') {
      height = 300;
    }
    // high quality = sem limite de altura

    return GestureDetector(
      onTap: () {
        if (widget.post.imageBase64 != null) {
          postService.openImageViewer(context, [widget.post.imageBase64!], widget.post.imageBase64!);
        } else if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty) {
          postService.openImageViewer(context, widget.post.imageUrls!, widget.post.imageUrls!.first);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 52, top: 12),
        constraints: height != null ? BoxConstraints(maxHeight: height) : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2F3336) : const Color(0xFFCFD9DE),
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: image,
      ),
    );
  }

  Widget _buildCompactNewsCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color secondaryColor,
    Color bgColor,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (widget.post.newsUrl != null) {
            final uri = Uri.parse(widget.post.newsUrl!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.article, size: 16, color: secondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.post.userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.post.title != null)
                Text(
                  widget.post.title!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (widget.post.summary != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.post.summary!,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(widget.post.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required int count,
    required Color color,
    required Color activeColor,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? activeColor : color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? activeColor : color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? const Color(0xFF16181C) : Colors.white,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Excluir', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  PostService().deletePost(widget.post.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}