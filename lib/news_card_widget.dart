// news_card_widget.dart - Cards de notícias em HTML com Tailwind CSS
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models.dart';

class HtmlNewsCard extends StatefulWidget {
  final NewsArticle article;
  final bool isDarkTheme;
  final Color primaryColor;
  final String? translatedTitle;
  final String? translatedDescription;
  final Function(String) onTap;
  final Function() onTranslate;

  const HtmlNewsCard({
    Key? key,
    required this.article,
    required this.isDarkTheme,
    required this.primaryColor,
    this.translatedTitle,
    this.translatedDescription,
    required this.onTap,
    required this.onTranslate,
  }) : super(key: key);

  @override
  State<HtmlNewsCard> createState() => _HtmlNewsCardState();
}

class _HtmlNewsCardState extends State<HtmlNewsCard> {
  late final WebViewController controller;
  double _height = 400;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('action://open')) {
              widget.onTap(widget.article.link);
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('action://translate')) {
              widget.onTranslate();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_generateHtml());

    // Ajusta altura dinamicamente
    Future.delayed(const Duration(milliseconds: 300), () {
      controller.runJavaScriptReturningResult('document.body.scrollHeight').then((result) {
        final height = double.tryParse(result.toString()) ?? 400;
        if (mounted) {
          setState(() {
            _height = height + 20;
          });
        }
      });
    });
  }

  @override
  void didUpdateWidget(HtmlNewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translatedTitle != widget.translatedTitle ||
        oldWidget.translatedDescription != widget.translatedDescription ||
        oldWidget.isDarkTheme != widget.isDarkTheme) {
      controller.loadHtmlString(_generateHtml());
    }
  }

  String _generateHtml() {
    final bgColor = widget.isDarkTheme ? '#1A1A1A' : '#FFFFFF';
    final textColor = widget.isDarkTheme ? '#E4E6EB' : '#050505';
    final subTextColor = widget.isDarkTheme ? '#B0B3B8' : '#65676B';
    final borderColor = widget.isDarkTheme ? '#3A3B3C' : '#DDDFE2';
    
    final title = widget.translatedTitle ?? widget.article.title;
    final description = widget.translatedDescription ?? widget.article.description ?? '';
    
    final primaryColorHex = '#${widget.primaryColor.value.toRadixString(16).substring(2)}';
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      background: transparent;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      -webkit-tap-highlight-color: transparent;
    }
  </style>
</head>
<body>
  <div onclick="location.href='action://open'" class="cursor-pointer rounded-xl overflow-hidden shadow-lg transition-transform active:scale-98" style="background: ${bgColor}; border: 1px solid ${primaryColorHex}20;">
    
    <!-- Top Border Accent -->
    <div class="h-1.5" style="background: ${primaryColorHex};"></div>
    
    ${widget.article.hasImage ? '''
    <!-- Image -->
    <div class="relative">
      <img 
        src="${widget.article.imageUrl}" 
        class="w-full h-56 object-cover"
        onerror="this.parentElement.innerHTML='<div class=\\'w-full h-56 flex items-center justify-center\\' style=\\'background: ${borderColor};color: ${subTextColor}\\'><svg class=\\'w-12 h-12\\' fill=\\'none\\' stroke=\\'currentColor\\' viewBox=\\'0 0 24 24\\'><path stroke-linecap=\\'round\\' stroke-linejoin=\\'round\\' stroke-width=\\'2\\' d=\\'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z\\'></path></svg></div>';"
      />
      <div class="absolute bottom-0 left-0 right-0 h-9" style="background: linear-gradient(to bottom, transparent, ${widget.isDarkTheme ? 'rgba(0,0,0,0.55)' : 'rgba(0,0,0,0.10)'});"></div>
    </div>
    ''' : ''}
    
    <!-- Content -->
    <div class="p-4">
      <!-- Header -->
      <div class="flex items-center justify-between mb-2">
        <div class="flex items-center gap-2 flex-1">
          <div class="w-5.5 h-5.5 rounded-full overflow-hidden flex-shrink-0" style="background: ${borderColor}50;">
            <img 
              src="${widget.article.source.favicon}" 
              class="w-full h-full object-cover"
              onerror="this.style.display='none'"
            />
          </div>
          <span class="text-xs font-semibold truncate" style="color: ${subTextColor};">
            ${widget.article.source.name}
          </span>
          ${widget.article.pubDate != null ? '''
          <span style="color: ${subTextColor};">·</span>
          <span class="text-xs" style="color: ${subTextColor};">
            ${_formatTime(widget.article.pubDate!)}
          </span>
          ''' : ''}
        </div>
        
        <button 
          onclick="event.stopPropagation(); location.href='action://translate';"
          class="p-1 rounded-full hover:bg-opacity-10 transition-colors flex-shrink-0"
          style="color: ${subTextColor};"
        >
          <svg class="w-4.5 h-4.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path>
          </svg>
        </button>
      </div>
      
      <!-- Title -->
      <h2 class="text-base font-semibold leading-snug mb-2" style="color: ${textColor};">
        ${_escapeHtml(title)}
      </h2>
      
      ${description.isNotEmpty ? '''
      <!-- Description -->
      <p class="text-sm leading-relaxed line-clamp-3" style="color: ${subTextColor};">
        ${_escapeHtml(description)}
      </p>
      ''' : ''}
    </div>
  </div>
</body>
</html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return '1 dia';
    if (diff.inDays < 7) return '${diff.inDays} dias';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: WebViewWidget(controller: controller),
    );
  }
}

// Card pequeno (grid)
class HtmlSmallNewsCard extends StatefulWidget {
  final NewsArticle article;
  final bool isDarkTheme;
  final String? translatedTitle;
  final Function(String) onTap;

  const HtmlSmallNewsCard({
    Key? key,
    required this.article,
    required this.isDarkTheme,
    this.translatedTitle,
    required this.onTap,
  }) : super(key: key);

  @override
  State<HtmlSmallNewsCard> createState() => _HtmlSmallNewsCardState();
}

class _HtmlSmallNewsCardState extends State<HtmlSmallNewsCard> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('action://open')) {
              widget.onTap(widget.article.link);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    final bgColor = widget.isDarkTheme ? '#1A1A1A' : '#FFFFFF';
    final textColor = widget.isDarkTheme ? '#E4E6EB' : '#050505';
    final subTextColor = widget.isDarkTheme ? '#B0B3B8' : '#65676B';
    final borderColor = widget.isDarkTheme ? '#3A3B3C' : '#DDDFE2';
    
    final title = widget.translatedTitle ?? widget.article.title;
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: transparent; font-family: -apple-system, sans-serif; -webkit-tap-highlight-color: transparent; }
  </style>
</head>
<body>
  <div onclick="location.href='action://open'" class="cursor-pointer rounded-xl overflow-hidden shadow-md h-full flex flex-col" style="background: ${bgColor};">
    
    ${widget.article.hasImage ? '''
    <div class="relative">
      <img src="${widget.article.imageUrl}" class="w-full h-24 object-cover" />
      <div class="absolute bottom-0 left-0 right-0 h-3.5" style="background: linear-gradient(to bottom, transparent, ${widget.isDarkTheme ? 'rgba(0,0,0,0.35)' : 'rgba(0,0,0,0.08)'});"></div>
    </div>
    ''' : ''}
    
    <div class="p-2.5 flex-1 flex flex-col">
      <div class="flex items-center gap-2 mb-1">
        <div class="w-5 h-5 rounded-full flex-shrink-0" style="background: ${borderColor};">
          <img src="${widget.article.source.favicon}" class="w-full h-full object-cover rounded-full" onerror="this.style.display='none'" />
        </div>
        <span class="text-xs font-semibold truncate" style="color: ${subTextColor};">${widget.article.source.name}</span>
      </div>
      
      <p class="text-xs font-semibold leading-snug line-clamp-3 flex-1" style="color: ${textColor};">
        ${_escapeHtml(title)}
      </p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}

// Card compacto (horizontal)
class HtmlCompactNewsCard extends StatefulWidget {
  final NewsArticle article;
  final bool isDarkTheme;
  final String? translatedTitle;
  final Function(String) onTap;

  const HtmlCompactNewsCard({
    Key? key,
    required this.article,
    required this.isDarkTheme,
    this.translatedTitle,
    required this.onTap,
  }) : super(key: key);

  @override
  State<HtmlCompactNewsCard> createState() => _HtmlCompactNewsCardState();
}

class _HtmlCompactNewsCardState extends State<HtmlCompactNewsCard> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('action://open')) {
              widget.onTap(widget.article.link);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_generateHtml());
  }

  String _generateHtml() {
    final bgColor = widget.isDarkTheme ? '#1A1A1A' : '#FFFFFF';
    final textColor = widget.isDarkTheme ? '#E4E6EB' : '#050505';
    final subTextColor = widget.isDarkTheme ? '#B0B3B8' : '#65676B';
    final borderColor = widget.isDarkTheme ? '#3A3B3C' : '#DDDFE2';
    
    final title = widget.translatedTitle ?? widget.article.title;
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: transparent; font-family: -apple-system, sans-serif; -webkit-tap-highlight-color: transparent; }
  </style>
</head>
<body>
  <div onclick="location.href='action://open'" class="cursor-pointer rounded-xl p-3 shadow-md h-full flex flex-col" style="background: ${bgColor}; width: 200px;">
    
    <div class="flex items-center gap-1.5 mb-2">
      <div class="w-4.5 h-4.5 rounded-full flex-shrink-0" style="background: ${borderColor};">
        <img src="${widget.article.source.favicon}" class="w-full h-full object-cover rounded-full" onerror="this.style.display='none'" />
      </div>
      <span class="text-xs font-semibold truncate" style="color: ${subTextColor};">${widget.article.source.name}</span>
    </div>
    
    <p class="text-sm font-semibold leading-snug flex-1 line-clamp-4" style="color: ${textColor};">
      ${_escapeHtml(title)}
    </p>
    
    ${widget.article.pubDate != null ? '''
    <span class="text-xs mt-1" style="color: ${subTextColor};">
      ${_formatTime(widget.article.pubDate!)}
    </span>
    ''' : ''}
  </div>
</body>
</html>
    ''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return '1 dia';
    if (diff.inDays < 7) return '${diff.inDays} dias';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}