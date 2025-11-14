// lib/widgets/rich_text_field.dart
import 'package:flutter/material.dart';

enum TextFormat { bold, italic, underline, strikethrough }

class RichTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final Color textColor;
  final Color hintColor;
  final String? fontFamily;

  const RichTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textColor,
    required this.hintColor,
    this.fontFamily,
  });

  @override
  State<RichTextField> createState() => RichTextFieldState();
}

class RichTextFieldState extends State<RichTextField> {
  final Map<int, Set<TextFormat>> _formatMap = {};

  void applyFormatting(TextFormat format) {
    final selection = widget.controller.selection;
    
    if (!selection.isValid || selection.start == selection.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o texto que deseja formatar'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      for (int i = selection.start; i < selection.end; i++) {
        _formatMap.putIfAbsent(i, () => {});
        
        if (_formatMap[i]!.contains(format)) {
          _formatMap[i]!.remove(format);
        } else {
          _formatMap[i]!.add(format);
        }
      }
    });

    // Manter seleção
    widget.controller.selection = selection;
  }

  String getFormattedText() {
    // Retorna o texto com marcadores de formatação
    final text = widget.controller.text;
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final formats = _formatMap[i];
      if (formats != null && formats.isNotEmpty) {
        if (formats.contains(TextFormat.bold)) buffer.write('**');
        if (formats.contains(TextFormat.italic)) buffer.write('_');
        if (formats.contains(TextFormat.underline)) buffer.write('__');
        if (formats.contains(TextFormat.strikethrough)) buffer.write('~~');
      }
      
      buffer.write(text[i]);
      
      if (formats != null && formats.isNotEmpty) {
        if (formats.contains(TextFormat.strikethrough)) buffer.write('~~');
        if (formats.contains(TextFormat.underline)) buffer.write('__');
        if (formats.contains(TextFormat.italic)) buffer.write('_');
        if (formats.contains(TextFormat.bold)) buffer.write('**');
      }
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: TextStyle(
        fontSize: 16,
        color: widget.textColor,
        height: 1.6,
        fontFamily: widget.fontFamily,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: widget.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(20),
      ),
      maxLines: null,
      minLines: 10,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Padding(
          padding: const EdgeInsets.only(right: 20, bottom: 10),
          child: Text(
            '$currentLength caracteres',
            style: TextStyle(
              fontSize: 12,
              color: widget.hintColor,
            ),
          ),
        );
      },
    );
  }
}