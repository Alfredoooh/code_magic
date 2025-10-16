import 'dart:typed_data';
import 'package:webview_flutter/webview_flutter.dart';

class WebTab {
  final String id;
  String url;
  String title;
  WebViewController? controller;
  Uint8List? screenshot;

  WebTab({
    required this.id,
    required this.url,
    this.title = 'Nova Aba',
    this.controller,
    this.screenshot,
  });
}