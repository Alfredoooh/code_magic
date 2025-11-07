// lib/widgets/video_widget_io.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// VideoWidget para mobile (Android/iOS).
/// - Detecta YouTube e usa youtube_player_flutter
/// - Para outros URLs usa webview_flutter
class VideoWidget extends StatefulWidget {
  final String url;
  const VideoWidget({super.key, required this.url});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;
  late final String _initialUrl;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.url;
    final id = _extractYoutubeId(widget.url);
    if (id != null) {
      _isYoutube = true;
      _ytController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          forceHD: false,
        ),
      );
    } else {
      _isYoutube = false;
    }

    // webview_flutter: enable hybrid composition for Android if needed
    if (!kIsWeb && Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    _ytController?.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF1877F2),
      );
    }

    // Fallback: generic webview for other URLs
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 210,
        child: WebView(
          initialUrl: _initialUrl,
          javascriptMode: JavascriptMode.unrestricted,
          allowsInlineMediaPlayback: true,
          initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
        ),
      ),
    );
  }
}