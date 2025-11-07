// lib/widgets/video_widget_web.dart
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoWidget extends StatefulWidget {
  final String url;
  const VideoWidget({super.key, required this.url});

  @override
  State<VideoWidget> createState() => _VideoWidgetWebState();
}

class _VideoWidgetWebState extends State<VideoWidget> {
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;
  late final String _viewId;
  bool _iframeRegistered = false;

  @override
  void initState() {
    super.initState();
    final id = _extractYoutubeId(widget.url);
    if (id != null) {
      _isYoutube = true;
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: id,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
        ),
      );
    } else {
      _isYoutube = false;
      _viewId = 'embed-${widget.url.hashCode}';
      
      // CORRIGIDO: Usar ui.platformViewRegistry corretamente
      if (!_iframeRegistered) {
        ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
          final iframe = html.IFrameElement()
            ..src = widget.url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
            ..allowFullscreen = true;
          return iframe;
        });
        _iframeRegistered = true;
      }
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  String? _extractYoutubeId(String url) {
    try {
      final regExp = RegExp(r'(?:v=|v\/|embed\/|youtu\.be\/|\/v\/)([A-Za-z0-9_-]{11})');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    } catch (_) {}
    return null;
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (uri != null) {
      html.window.open(widget.url, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(controller: _ytController!);
    }

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: Stack(
        children: [
          if (_iframeRegistered) 
            Positioned.fill(
              child: HtmlElementView(viewType: _viewId),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: ElevatedButton(
              onPressed: _openExternally,
              style: ElevatedButton.styleFrom(elevation: 2),
              child: const Text('Abrir em nova aba'),
            ),
          ),
        ],
      ),
    );
  }
}