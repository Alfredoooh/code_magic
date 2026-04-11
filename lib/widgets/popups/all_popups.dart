import 'package:flutter/material.dart';
import '../../constants.dart';

// ============================================================
// SHARED POPUP COMPONENTS
// (declarados primeiro para estarem disponíveis a todos abaixo)
// ============================================================

class PopupHeader extends StatelessWidget {
  final String label;
  const PopupHeader({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: kMuted,
            letterSpacing: 0.07 * 10.5,
          ),
        ),
      );
}

class PopupListItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const PopupListItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  @override
  State<PopupListItem> createState() => _PopupListItemState();
}

class _PopupListItemState extends State<PopupListItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            color: _h ? Colors.black.withOpacity(0.04) : Colors.transparent,
            child: Row(children: [
              Icon(widget.icon,
                  size: 15,
                  color: widget.danger ? Colors.red.shade500 : kMuted),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.danger ? Colors.red.shade600 : kInk,
                ),
              ),
            ]),
          ),
        ),
      );
}

// ============================================================
// popup_color.dart
// ============================================================

class PopupColor extends StatefulWidget {
  final ValueChanged<Color> onColor;
  const PopupColor({super.key, required this.onColor});
  @override
  State<PopupColor> createState() => _PopupColorState();
}

class _PopupColorState extends State<PopupColor> {
  final _hexCtrl = TextEditingController(text: '#34322d');
  Color _preview = const Color(0xFF34322D);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PopupHeader(label: 'Cor do texto'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1,
            ),
            itemCount: kSwatchColors.length,
            itemBuilder: (_, i) {
              final c = kSwatchColors[i];
              return _Swatch(color: c, onTap: () => widget.onColor(c));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _preview,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.12), width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  maxLength: 7,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: ['monospace'],
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kAccent, width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                  onChanged: (v) {
                    final re = RegExp(r'^#[0-9a-fA-F]{6}$');
                    if (re.hasMatch(v)) {
                      setState(() {
                        _preview = Color(
                            int.parse('FF${v.substring(1)}', radix: 16));
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  final re = RegExp(r'^#[0-9a-fA-F]{6}$');
                  if (re.hasMatch(_hexCtrl.text)) widget.onColor(_preview);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _preview,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  const _Swatch({required this.color, required this.onTap});
  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hovered ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(4),
                border: widget.color.value == 0xFFFFFFFF
                    ? Border.all(
                        color: Colors.black.withOpacity(0.15), width: 2)
                    : null,
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// popup_font.dart
// ============================================================

class PopupFont extends StatefulWidget {
  final ValueChanged<String> onFont;
  final VoidCallback onExpand;
  const PopupFont(
      {super.key, required this.onFont, required this.onExpand});
  @override
  State<PopupFont> createState() => _PopupFontState();
}

class _PopupFontState extends State<PopupFont> {
  final _searchCtrl = TextEditingController();
  String? _previewFont;
  String _query = '';

  List<FontEntry> get _filtered => kFonts
      .where((f) => f.label.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<FontEntry>>{};
    for (final f in _filtered) {
      grouped.putIfAbsent(f.group, () => []).add(f);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: PopupHeader(label: 'Tipo de letra')),
            IconButton(
              icon: const Icon(Icons.open_in_full, size: 14, color: kMuted),
              onPressed: widget.onExpand,
              tooltip: 'Ver todas',
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: TextField(
            controller: _searchCtrl,
            style:
                const TextStyle(fontFamily: 'DMSans', fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Pesquisar…',
              hintStyle: const TextStyle(color: kMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccent, width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView(
            children: [
              if (_query.isEmpty)
                ...grouped.entries.expand((e) => [
                      _FontGroupLabel(
                          label: e.key,
                          first: grouped.keys.first == e.key),
                      ...e.value.map((f) => _FontItem(
                            font: f,
                            onTap: () =>
                                setState(() => _previewFont = f.label),
                          )),
                    ])
              else
                ..._filtered.map((f) => _FontItem(
                      font: f,
                      onTap: () =>
                          setState(() => _previewFont = f.label),
                    )),
            ],
          ),
        ),
        if (_previewFont != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _previewFont!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kMuted,
                    letterSpacing: 0.06 * 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aa Bb Cc',
                  style: TextStyle(
                      fontFamily: _previewFont,
                      fontSize: 26,
                      color: kInk,
                      height: 1.2),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => widget.onFont(_previewFont!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Aplicar',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FontGroupLabel extends StatelessWidget {
  final String label;
  final bool first;
  const _FontGroupLabel({required this.label, required this.first});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
        margin: EdgeInsets.only(top: first ? 0 : 2),
        decoration: BoxDecoration(
          border:
              first ? null : const Border(top: BorderSide(color: kBorder)),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFFCCCCCC),
            letterSpacing: 0.06 * 10,
          ),
        ),
      );
}

class _FontItem extends StatefulWidget {
  final FontEntry font;
  final VoidCallback onTap;
  const _FontItem({required this.font, required this.onTap});
  @override
  State<_FontItem> createState() => _FontItemState();
}

class _FontItemState extends State<_FontItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            color:
                _h ? Colors.black.withOpacity(0.04) : Colors.transparent,
            child: Row(children: [
              Expanded(
                  child: Text(
                widget.font.label,
                style: TextStyle(
                    fontFamily: widget.font.label,
                    fontSize: 14,
                    color: kInk),
              )),
            ]),
          ),
        ),
      );
}

// ============================================================
// popup_size.dart
// ============================================================

class PopupSize extends StatefulWidget {
  final int current;
  final ValueChanged<int> onSize;
  const PopupSize(
      {super.key, required this.current, required this.onSize});
  @override
  State<PopupSize> createState() => _PopupSizeState();
}

class _PopupSizeState extends State<PopupSize> {
  late int _val;
  @override
  void initState() {
    super.initState();
    _val = widget.current;
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PopupHeader(label: 'Tamanho'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _StepBtn(
                    label: '−',
                    onTap: () => setState(
                        () => _val = (_val - 1).clamp(6, 200))),
                Expanded(
                  child: Center(
                      child: Text(
                    '$_val',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kInk),
                  )),
                ),
                _StepBtn(
                    label: '+',
                    onTap: () => setState(
                        () => _val = (_val + 1).clamp(6, 200))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: kFontSizePresets
                  .map((s) => _SizePreset(
                        size: s,
                        active: s == _val,
                        onTap: () {
                          widget.onSize(s);
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      );
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: kBorder, width: 1.5),
          ),
          child: Center(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 18, color: kSub))),
        ),
      );
}

class _SizePreset extends StatefulWidget {
  final int size;
  final bool active;
  final VoidCallback onTap;
  const _SizePreset(
      {required this.size, required this.active, required this.onTap});
  @override
  State<_SizePreset> createState() => _SizePresetState();
}

class _SizePresetState extends State<_SizePreset> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.active || _h ? kAccentBg : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.active || _h ? kAccent : kBorder,
                width: 1.5,
              ),
            ),
            child: Text(
              '${widget.size}',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.active || _h ? kAccent : kSub,
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// popup_styles.dart
// ============================================================

class PopupStyles extends StatelessWidget {
  final ValueChanged<String> onStyle;
  const PopupStyles({super.key, required this.onStyle});

  @override
  Widget build(BuildContext context) {
    final items = [
      // Icons.format_paragraph não existe no Flutter — substituído por
      // Icons.notes, que representa visualmente um parágrafo de texto.
      {'label': 'Parágrafo',  'block': 'p',          'icon': Icons.notes},
      {'label': 'Título 1',   'block': 'h1',         'icon': Icons.looks_one_outlined},
      {'label': 'Título 2',   'block': 'h2',         'icon': Icons.looks_two_outlined},
      {'label': 'Título 3',   'block': 'h3',         'icon': Icons.looks_3_outlined},
      {'label': 'Título 4',   'block': 'h4',         'icon': Icons.looks_4_outlined},
      {'label': 'Citação',    'block': 'blockquote', 'icon': Icons.format_quote},
      {'label': 'Código',     'block': 'pre',        'icon': Icons.code},
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PopupHeader(label: 'Estilo de parágrafo'),
        ...items.map((s) => PopupListItem(
              icon: s['icon'] as IconData,
              label: s['label'] as String,
              onTap: () => onStyle(s['block'] as String),
            )),
      ],
    );
  }
}

// ============================================================
// popup_insert.dart
// ============================================================

class PopupInsert extends StatelessWidget {
  final ValueChanged<String> onAction;
  const PopupInsert({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PopupHeader(label: 'Inserir'),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Column(children: [
            PopupListItem(
                icon: Icons.link,
                label: 'Link',
                onTap: () => onAction('link')),
            PopupListItem(
                icon: Icons.image_outlined,
                label: 'Imagem',
                onTap: () => onAction('image')),
            PopupListItem(
                icon: Icons.table_chart_outlined,
                label: 'Tabela 3×3',
                onTap: () => onAction('table')),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Column(children: [
            PopupListItem(
                icon: Icons.remove,
                label: 'Linha divisória',
                onTap: () => onAction('hr')),
            PopupListItem(
                icon: Icons.calendar_today_outlined,
                label: 'Data e hora',
                onTap: () => onAction('date')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CAIXAS DE DESTAQUE',
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCCCCCC),
                  letterSpacing: 0.06 * 10),
            ),
          ),
        ),
        PopupListItem(
            icon: Icons.warning_amber_outlined,
            label: 'Aviso',
            onTap: () => onAction('warn')),
        PopupListItem(
            icon: Icons.info_outline,
            label: 'Informação',
            onTap: () => onAction('info')),
        PopupListItem(
            icon: Icons.check_circle_outline,
            label: 'Sucesso',
            onTap: () => onAction('success')),
        PopupListItem(
            icon: Icons.cancel_outlined,
            label: 'Erro',
            onTap: () => onAction('error')),
      ],
    );
  }
}

// ============================================================
// popup_format.dart
// ============================================================

class PopupFormat extends StatelessWidget {
  final ValueChanged<String> onAction;
  const PopupFormat({super.key, required this.onAction});

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFCCCCCC),
              letterSpacing: 0.06 * 10,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PopupHeader(label: 'Formatar'),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Column(children: [
            _sectionLabel('MAIÚSCULAS'),
            PopupListItem(
                icon: Icons.text_fields,
                label: 'MAIÚSCULAS',
                onTap: () => onAction('upper')),
            PopupListItem(
                icon: Icons.text_fields,
                label: 'minúsculas',
                onTap: () => onAction('lower')),
            PopupListItem(
                icon: Icons.text_fields,
                label: 'Primeira Maiúscula',
                onTap: () => onAction('title')),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Column(children: [
            _sectionLabel('INLINE'),
            PopupListItem(
                icon: Icons.superscript,
                label: 'Sobrescrito',
                onTap: () => onAction('superscript')),
            PopupListItem(
                icon: Icons.subscript,
                label: 'Subscrito',
                onTap: () => onAction('subscript')),
            PopupListItem(
                icon: Icons.code,
                label: 'Código inline',
                onTap: () => onAction('code')),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Column(children: [
            _sectionLabel('ESPAÇAMENTO'),
            PopupListItem(
                icon: Icons.format_line_spacing,
                label: '1.0 — Compacto',
                onTap: () => onAction('lh1')),
            PopupListItem(
                icon: Icons.format_line_spacing,
                label: '1.5 — Normal',
                onTap: () => onAction('lh15')),
            PopupListItem(
                icon: Icons.format_line_spacing,
                label: '2.0 — Espaçado',
                onTap: () => onAction('lh2')),
          ]),
        ),
        PopupListItem(
          icon: Icons.delete_outline,
          label: 'Limpar formatação',
          onTap: () => onAction('clear'),
          danger: true,
        ),
      ],
    );
  }
}