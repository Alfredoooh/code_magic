// lib/widgets/video_widget.dart
// Conditionally export platform implementation: mobile (io) by default, web when compiled for web.
export 'video_widget_io.dart' 
  if (dart.library.html) 'video_widget_web.dart';