import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme.dart';
import 'font_data.dart';

// ─── POPUP CONTENTS ──────────────────────────────────────────────────────────

// POPUP HEADER
class PopupHeader extends StatelessWidget {
  final String title;
  const PopupHeader(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.divider)),
      ),
      child: Text(
        title.toUpperCase(),
        style: T.dmSans(size: 10.5, w: FontWeight.w700, color: T.muted),
      ),
    );
  }
}

// POPUP ITEM BUTTON
class PopupItemBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const PopupItemBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color ?? T.muted),
            const SizedBox(width: 10),
            Text(
              label,
              style: T.dmSans(size: 13, w: FontWeight.w500, color: color ?? T.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// COLOR POPUP
class ColorPopup extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColor;

  const ColorPopup({super.key, required this.currentColor, required this.onColor});

  @override
  State<ColorPopup> createState() => _ColorPopupState();
}

class _ColorPopupState extends State<ColorPopup> {
  final TextEditingController _hexCtrl = TextEditingController();
  Color _preview = T.ink;

  @override
  void initState() {
    super.initState();
    _preview = widget.currentColor;
    _hexCtrl.text =
        '#${widget.currentColor.red.toRadixString(16).padLeft(2, '0')}${widget.currentColor.green.toRadixString(16).padLeft(2, '0')}${widget.currentColor.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupHeader('Cor do texto'),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: kColors.map((c) {
              return GestureDetector(
                onTap: () => widget.onColor(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: c == Colors.white
                          ? const Color(0x26000000)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _preview,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x1F000000), width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  style: T.dmSans(size: 12, w: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: T.divider, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: T.divider, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                      setState(() {
                        _preview = Color(
                          int.parse('FF${v.substring(1)}', radix: 16),
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_hexCtrl.text)) {
                    widget.onColor(
                      Color(int.parse('FF${_hexCtrl.text.substring(1)}', radix: 16)),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _preview,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.check, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// FONT POPUP
class FontPopup extends StatefulWidget {
  final String currentFont;
  final ValueChanged<String> onFont;
  final VoidCallback onOpenFullscreen;

  const FontPopup({
    super.key,
    required this.currentFont,
    required this.onFont,
    required this.onOpenFullscreen,
  });

  @override
  State<FontPopup> createState() => _FontPopupState();
}

class _FontPopupState extends State<FontPopup> {
  String _query = '';
  FontEntry? _preview;

  List<FontEntry> get _filtered => _query.isEmpty
      ? kFonts
      : kFonts.where((f) => f.label.toLowerCase().contains(_query.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row with expand button
        Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: T.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'TIPO DE LETRA',
                  style: T.dmSans(size: 10.5, w: FontWeight.w700, color: T.muted),
                ),
              ),
              GestureDetector(
                onTap: widget.onOpenFullscreen,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: Colors.transparent,
                  ),
                  child: Icon(LucideIcons.maximize2, size: 14, color: T.muted),
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: T.dmSans(size: 12.5),
            decoration: InputDecoration(
              hintText: 'Pesquisar…',
              hintStyle: T.dmSans(size: 12.5, color: T.muted),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: T.divider, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: T.divider, width: 1.5),
              ),
            ),
          ),
        ),
        // Font list
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final f = _filtered[i];
              final isActive = f.family == widget.currentFont;
              return GestureDetector(
                onTap: () => setState(() => _preview = f),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
                  color: Colors.transparent,
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontFamily: f.family,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? T.accent : T.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Preview
        if (_preview != null)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F7),
              border: Border(top: BorderSide(color: T.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _preview!.group.toUpperCase(),
                  style: T.dmSans(size: 10, w: FontWeight.w700, color: T.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aa Bb Cc',
                  style: TextStyle(
                    fontFamily: _preview!.family,
                    fontSize: 26,
                    color: T.ink,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => widget.onFont(_preview!.family),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: T.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Aplicar',
                      style: T.dmSans(size: 12.5, w: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// SIZE POPUP
class SizePopup extends StatefulWidget {
  final int currentSize;
  final ValueChanged<int> onSize;

  const SizePopup({super.key, required this.currentSize, required this.onSize});

  @override
  State<SizePopup> createState() => _SizePopupState();
}

class _SizePopupState extends State<SizePopup> {
  late int _size;

  @override
  void initState() {
    super.initState();
    _size = widget.currentSize;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupHeader('Tamanho'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _size = math.max(6, _size - 1)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: T.divider, width: 1.5),
                    color: T.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text('−', style: T.dmSans(size: 18, color: T.sub)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_size',
                    style: T.dmSans(size: 20, w: FontWeight.w700),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _size = math.min(200, _size + 1)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: T.divider, width: 1.5),
                    color: T.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text('+', style: T.dmSans(size: 18, color: T.sub)),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: T.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: kSizes.map((s) {
              final active = s == _size;
              return GestureDetector(
                onTap: () {
                  widget.onSize(s);
                  setState(() => _size = s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? T.accent : T.divider,
                      width: 1.5,
                    ),
                    color: active ? T.accentBg : Colors.transparent,
                  ),
                  child: Text(
                    '$s',
                    style: T.dmSans(
                      size: 12,
                      w: FontWeight.w600,
                      color: active ? T.accent : T.sub,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// STYLES POPUP
class StylesPopup extends StatelessWidget {
  final ValueChanged<String> onStyle;

  const StylesPopup({super.key, required this.onStyle});

  @override
  Widget build(BuildContext context) {
    final styles = [
      (LucideIcons.pilcrow, 'Parágrafo', 'p'),
      (LucideIcons.heading1, 'Título 1', 'h1'),
      (LucideIcons.heading2, 'Título 2', 'h2'),
      (LucideIcons.caseSensitive, 'Título 3', 'h3'),
      (LucideIcons.heading4, 'Título 4', 'h4'),
      (LucideIcons.quote, 'Citação', 'blockquote'),
      (LucideIcons.code, 'Código', 'code'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupHeader('Estilo de parágrafo'),
        ...styles.map((s) => PopupItemBtn(
              icon: s.$1,
              label: s.$2,
              onTap: () => onStyle(s.$3),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

// INSERT POPUP
class InsertPopup extends StatelessWidget {
  final VoidCallback onLink;
  final VoidCallback onImage;
  final VoidCallback onTable;
  final VoidCallback onHR;
  final VoidCallback onDateTime;
  final ValueChanged<String> onCallout;

  const InsertPopup({
    super.key,
    required this.onLink,
    required this.onImage,
    required this.onTable,
    required this.onHR,
    required this.onDateTime,
    required this.onCallout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupHeader('Inserir'),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              children: [
                PopupItemBtn(icon: LucideIcons.link, label: 'Link', onTap: onLink),
                PopupItemBtn(icon: LucideIcons.image, label: 'Imagem', onTap: onImage),
                PopupItemBtn(icon: LucideIcons.table, label: 'Tabela 3×3', onTap: onTable),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              children: [
                PopupItemBtn(icon: LucideIcons.minus, label: 'Linha divisória', onTap: onHR),
                PopupItemBtn(
                  icon: LucideIcons.calendar,
                  label: 'Data e hora',
                  onTap: onDateTime,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CAIXAS DE DESTAQUE',
                style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
              ),
            ),
          ),
          PopupItemBtn(icon: LucideIcons.alertTriangle, label: 'Aviso', onTap: () => onCallout('warn')),
          PopupItemBtn(icon: LucideIcons.info, label: 'Informação', onTap: () => onCallout('info')),
          PopupItemBtn(icon: LucideIcons.checkCircle, label: 'Sucesso', onTap: () => onCallout('success')),
          PopupItemBtn(icon: LucideIcons.xCircle, label: 'Erro', onTap: () => onCallout('error')),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// FORMAT POPUP
class FormatPopup extends StatelessWidget {
  final ValueChanged<String> onCase;
  final VoidCallback onSuperscript;
  final VoidCallback onSubscript;
  final VoidCallback onInlineCode;
  final ValueChanged<double> onLineHeight;
  final VoidCallback onClearFormat;

  const FormatPopup({
    super.key,
    required this.onCase,
    required this.onSuperscript,
    required this.onSubscript,
    required this.onInlineCode,
    required this.onLineHeight,
    required this.onClearFormat,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupHeader('Formatar'),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'MAIÚSCULAS',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'MAIÚSCULAS', onTap: () => onCase('upper')),
                PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'minúsculas', onTap: () => onCase('lower')),
                PopupItemBtn(icon: LucideIcons.caseSensitive, label: 'Primeira Maiúscula', onTap: () => onCase('title')),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'INLINE',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                PopupItemBtn(icon: LucideIcons.superscript, label: 'Sobrescrito', onTap: onSuperscript),
                PopupItemBtn(icon: LucideIcons.subscript, label: 'Subscrito', onTap: onSubscript),
                PopupItemBtn(icon: LucideIcons.code, label: 'Código inline', onTap: onInlineCode),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: Text(
                    'ESPAÇAMENTO',
                    style: T.dmSans(size: 10, w: FontWeight.w700, color: const Color(0xFFCCCCCC)),
                  ),
                ),
                PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '1.0 — Compacto',
                  onTap: () => onLineHeight(1.0),
                ),
                PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '1.5 — Normal',
                  onTap: () => onLineHeight(1.5),
                ),
                PopupItemBtn(
                  icon: LucideIcons.alignVerticalJustifyStart,
                  label: '2.0 — Espaçado',
                  onTap: () => onLineHeight(2.0),
                ),
              ],
            ),
          ),
          PopupItemBtn(
            icon: LucideIcons.trash2,
            label: 'Limpar formatação',
            onTap: onClearFormat,
            color: Colors.red,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
