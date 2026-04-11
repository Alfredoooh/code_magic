import 'package:flutter/material.dart';
import '../../constants.dart';

class PopupColor extends StatefulWidget {
  final ValueChanged<Color> onColor;
  const PopupColor({super.key, required this.onColor});
  @override State<PopupColor> createState() => _PopupColorState();
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
        _PopupHeader(label: 'Cor do texto'),
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
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: _preview,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black.withOpacity(0.12), width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  maxLength: 7,
                  style: const TextStyle(
                    fontFamily: 'DMSans', fontSize: 12,
                    fontWeight: FontWeight.w600, fontFamilyFallback: ['monospace'],
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                  onChanged: (v) {
                    final re = RegExp(r'^#[0-9a-fA-F]{6}$');
                    if (re.hasMatch(v)) {
                      setState(() {
                        _preview = Color(int.parse('FF${v.substring(1)}', radix: 16));
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _preview,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
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
  @override State<_Swatch> createState() => _SwatchState();
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
                ? Border.all(color: Colors.black.withOpacity(0.15), width: 2)
                : null,
          ),
        ),
      ),
    ),
  );
}
