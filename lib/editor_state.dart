import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'constants.dart';

class EditorState extends ChangeNotifier {
  // ── Quill ──────────────────────────────────────────────
  final QuillController quill = QuillController.basic();
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
    bold      = style.containsKey(Attribute.bold.key);
    italic    = style.containsKey(Attribute.italic.key);
    underline = style.containsKey(Attribute.underline.key);
    strike    = style.containsKey(Attribute.strikeThrough.key);
    notifyListeners();
  }

  void applyBold()      => quill.formatSelection(bold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
  void applyItalic()    => quill.formatSelection(italic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
  void applyUnderline() => quill.formatSelection(underline ? Attribute.clone(Attribute.underline, null) : Attribute.underline);
  void applyStrike()    => quill.formatSelection(strike ? Attribute.clone(Attribute.strikeThrough, null) : Attribute.strikeThrough);

  void applyAlign(String a) {
    setAlign(a);
    Attribute attr;
    switch (a) {
      case 'center':  attr = Attribute.centerAlignment; break;
      case 'right':   attr = Attribute.rightAlignment; break;
      case 'justify': attr = Attribute.justifyAlignment; break;
      default:        attr = Attribute.leftAlignment;
    }
    quill.formatSelection(attr);
  }

  void applyFontSize(int sz) {
    setFontSize(sz);
    quill.formatSelection(SizeAttribute(sz.toString()));
  }

  void applyFont(String family) {
    setFontLabel(family);
    quill.formatSelection(FontAttribute(family));
  }

  void applyColor(Color c) {
    setTextColor(c);
    quill.formatSelection(ColorAttribute('#${c.value.toRadixString(16).substring(2)}'));
  }

  void applyBlockStyle(String block) {
    switch (block) {
      case 'h1': quill.formatSelection(Attribute.h1); break;
      case 'h2': quill.formatSelection(Attribute.h2); break;
      case 'h3': quill.formatSelection(Attribute.h3); break;
      case 'blockquote': quill.formatSelection(Attribute.blockQuote); break;
      case 'pre': quill.formatSelection(Attribute.codeBlock); break;
      default: quill.formatSelection(Attribute.clone(Attribute.h1, null));
    }
  }

  void insertUnorderedList() => quill.formatSelection(Attribute.ul);
  void insertOrderedList()   => quill.formatSelection(Attribute.ol);
  void indent()              => quill.formatSelection(Attribute.indentL1);
  void outdent()             => quill.formatSelection(Attribute.clone(Attribute.indentL1, null));
  void undo()                => quill.undo();
  void redo()                => quill.redo();

  void applySuperscript() => quill.formatSelection(ScriptAttribute('super'));
  void applySubscript()   => quill.formatSelection(ScriptAttribute('sub'));

  void applyLineHeight(double h) {
    quill.formatSelection(LineHeightAttribute(h.toString()));
  }

  void clearFormat() {
    quill.formatSelection(Attribute.clone(Attribute.bold, null));
    quill.formatSelection(Attribute.clone(Attribute.italic, null));
    quill.formatSelection(Attribute.clone(Attribute.underline, null));
    quill.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
  }

  void transformCase(String mode) {
    final sel = quill.selection;
    if (sel.isCollapsed) return;
    final text = quill.document.toPlainText().substring(sel.start, sel.end);
    String transformed;
    switch (mode) {
      case 'upper': transformed = text.toUpperCase(); break;
      case 'lower': transformed = text.toLowerCase(); break;
      case 'title': transformed = text.replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase()); break;
      default: transformed = text;
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