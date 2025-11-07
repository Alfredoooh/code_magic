// lib/widgets/video_widget.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoWidget extends StatefulWidget {
  final String url;
  const VideoWidget({super.key, required this.url});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  YoutubePlayerController? _ytController;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    final id = YoutubePlayer.convertUrlToId(widget.url);
    if (id != null) {
      _isYoutube = true;
      _ytController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    } else {
      _isYoutube = false;
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytController != null) {
      return YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true);
    } else {
      return WebView(initialUrl: widget.url, javascriptMode: JavascriptMode.unrestricted);
    }
  }
}