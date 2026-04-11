import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill_lib;
import 'constants.dart';

/// Renomeado para [AppEditorState] para evitar conflito com
/// [EditorState] exportado pelo flutter_quill (raw_editor.dart).
class AppEditorState extends ChangeNotifier {
  // ── Quill ──────────────────────────────────────────────
  final quill_lib.QuillController quill = quill_lib.QuillController.basic();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  // ── Title ──────────────────────────────────────────────
  String title = '';

  // ── Page mode ──────────────────────────────────────────
  bool a4Mode = false;

  // ── AI mode ────────────────────────────────────────────
  bool aiMode = false;
  bool aiLoading = false;

  // ── Format state ───────────────────────────────────────
  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool strike = false;
  String align = 'left';
  String fontLabel = 'Lora';
  int fontSize = 16;
  Color textColor = const Color(0xFFF0A500);

  // ── Drawer ─────────────────────────────────────────────
  bool drawerOpen = false;

  // ── Active popup ───────────────────────────────────────
  String? activePopup;

  void toggleDrawer() {
    drawerOpen = !drawerOpen;
    notifyListeners();
  }

  void closeDrawer() {
    drawerOpen = false;
    notifyListeners();
  }

  void toggleAI() {
    aiMode = !aiMode;
    notifyListeners();
  }

  void setAILoading(bool v) {
    aiLoading = v;
    notifyListeners();
  }

  void setActivePopup(String? v) {
    activePopup = v;
    notifyListeners();
  }

  void setFontLabel(String v) {
    fontLabel = v;
    notifyListeners();
  }

  void setFontSize(int v) {
    fontSize = v;
    notifyListeners();
  }

  void setTextColor(Color v) {
    textColor = v;
    notifyListeners();
  }

  void setAlign(String v) {
    align = v;
    notifyListeners();
  }

  void toggleA4() {
    a4Mode = !a4Mode;
    notifyListeners();
  }

  void updateFormatFromSelection() {
    final style = quill.getSelectionStyle();
    bold = style.containsKey(quill_lib.Attribute.bold.key);
    italic = style.containsKey(quill_lib.Attribute.italic.key);
    underline = style.containsKey(quill_lib.Attribute.underline.key);
    strike = style.containsKey(quill_lib.Attribute.strikeThrough.key);
    notifyListeners();
  }

  void applyBold() => quill.formatSelection(
        bold
            ? quill_lib.Attribute.clone(quill_lib.Attribute.bold, null)
            : quill_lib.Attribute.bold,
      );

  void applyItalic() => quill.formatSelection(
        italic
            ? quill_lib.Attribute.clone(quill_lib.Attribute.italic, null)
            : quill_lib.Attribute.italic,
      );

  void applyUnderline() => quill.formatSelection(
        underline
            ? quill_lib.Attribute.clone(quill_lib.Attribute.underline, null)
            : quill_lib.Attribute.underline,
      );

  void applyStrike() => quill.formatSelection(
        strike
            ? quill_lib.Attribute.clone(quill_lib.Attribute.strikeThrough, null)
            : quill_lib.Attribute.strikeThrough,
      );

  void applyAlign(String a) {
    setAlign(a);
    quill_lib.Attribute attr;
    switch (a) {
      case 'center':
        attr = quill_lib.Attribute.centerAlignment;
        break;
      case 'right':
        attr = quill_lib.Attribute.rightAlignment;
        break;
      case 'justify':
        attr = quill_lib.Attribute.justifyAlignment;
        break;
      default:
        attr = quill_lib.Attribute.leftAlignment;
    }
    quill.formatSelection(attr);
  }

  void applyFontSize(int sz) {
    setFontSize(sz);
    quill.formatSelection(quill_lib.SizeAttribute(sz.toString()));
  }

  void applyFont(String family) {
    setFontLabel(family);
    quill.formatSelection(quill_lib.FontAttribute(family));
  }

  void applyColor(Color c) {
    setTextColor(c);
    quill.formatSelection(
      quill_lib.ColorAttribute('#${c.value.toRadixString(16).substring(2)}'),
    );
  }

  void applyBlockStyle(String block) {
    switch (block) {
      case 'h1':
        quill.formatSelection(quill_lib.Attribute.h1);
        break;
      case 'h2':
        quill.formatSelection(quill_lib.Attribute.h2);
        break;
      case 'h3':
        quill.formatSelection(quill_lib.Attribute.h3);
        break;
      case 'blockquote':
        quill.formatSelection(quill_lib.Attribute.blockQuote);
        break;
      case 'pre':
        quill.formatSelection(quill_lib.Attribute.codeBlock);
        break;
      default:
        quill.formatSelection(
          quill_lib.Attribute.clone(quill_lib.Attribute.h1, null),
        );
    }
  }

  void insertUnorderedList() => quill.formatSelection(quill_lib.Attribute.ul);
  void insertOrderedList() => quill.formatSelection(quill_lib.Attribute.ol);
  void indent() => quill.formatSelection(quill_lib.Attribute.indentL1);
  void outdent() =>
      quill.formatSelection(quill_lib.Attribute.clone(quill_lib.Attribute.indentL1, null));
  void undo() => quill.undo();
  void redo() => quill.redo();

  // ── Superscript / Subscript ────────────────────────────
  void applySuperscript() =>
      quill.formatSelection(quill_lib.ScriptAttribute(quill_lib.ScriptAttributes.sup));

  void applySubscript() =>
      quill.formatSelection(quill_lib.ScriptAttribute(quill_lib.ScriptAttributes.sub));

  // ── Line height ────────────────────────────────────────
  void applyLineHeight(double h) {
    quill.formatSelection(quill_lib.LineHeightAttribute(lineHeight: h));
  }

  void clearFormat() {
    quill.formatSelection(quill_lib.Attribute.clone(quill_lib.Attribute.bold, null));
    quill.formatSelection(quill_lib.Attribute.clone(quill_lib.Attribute.italic, null));
    quill.formatSelection(quill_lib.Attribute.clone(quill_lib.Attribute.underline, null));
    quill.formatSelection(quill_lib.Attribute.clone(quill_lib.Attribute.strikeThrough, null));
  }

  void transformCase(String mode) {
    final sel = quill.selection;
    if (sel.isCollapsed) return;
    final text = quill.document.toPlainText().substring(sel.start, sel.end);
    String transformed;
    switch (mode) {
      case 'upper':
        transformed = text.toUpperCase();
        break;
      case 'lower':
        transformed = text.toLowerCase();
        break;
      case 'title':
        transformed = text.replaceAllMapped(
          RegExp(r'\b\w'),
          (m) => m.group(0)!.toUpperCase(),
        );
        break;
      default:
        transformed = text;
    }
    quill.replaceText(sel.start, sel.end - sel.start, transformed, sel);
  }

  void insertText(String text) {
    final index = quill.selection.baseOffset;
    quill.document.insert(index, text);
  }

  @override
  void dispose() {
    quill.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }
}