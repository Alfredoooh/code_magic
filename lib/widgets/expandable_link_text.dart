// lib/widgets/expandable_link_text.dart
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpandableLinkText extends StatefulWidget {
  final String text;
  final int trimLines;
  const ExpandableLinkText({super.key, required this.text, this.trimLines = 3});

  @override
  State<ExpandableLinkText> createState() => _ExpandableLinkTextState();
}

class _ExpandableLinkTextState extends State<ExpandableLinkText> {
  bool _expanded = false;

  Future<void> _onOpen(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRIGIDO: bodyText1 → bodyLarge
    final textStyle = TextStyle(fontSize: 15, height: 1.4, color: Theme.of(context).textTheme.bodyLarge?.color);
    const linkStyle = TextStyle(color: Colors.red);

    if (_expanded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Linkify(text: widget.text, onOpen: _onOpen, style: textStyle, linkStyle: linkStyle),
        const SizedBox(height: 6),
        GestureDetector(onTap: () => setState(() => _expanded = false), child: const Text('Ver menos', style: TextStyle(fontWeight: FontWeight.w600))),
      ]);
    }

    return LayoutBuilder(builder: (context, size) {
      final span = TextSpan(text: widget.text, style: textStyle);
      final tp = TextPainter(text: span, maxLines: widget.trimLines, textDirection: TextDirection.ltr)..layout(maxWidth: size.maxWidth);
      final didOverflow = tp.didExceedMaxLines;
      if (!didOverflow) {
        return Linkify(text: widget.text, onOpen: _onOpen, style: textStyle, linkStyle: linkStyle);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: size.maxWidth,
          child: Linkify(
            text: widget.text,
            onOpen: _onOpen,
            style: textStyle,
            linkStyle: linkStyle,
            maxLines: widget.trimLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(onTap: () => setState(() => _expanded = true), child: const Text('Ver mais', style: TextStyle(fontWeight: FontWeight.w600))),
      ]);
    });
  }
}