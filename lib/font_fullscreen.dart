import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme.dart';
import 'font_data.dart';

// ─── FONT FULLSCREEN ─────────────────────────────────────────────────────────
class FontFullscreen extends StatefulWidget {
  final String currentFont;
  final ValueChanged<String> onFont;

  const FontFullscreen({super.key, required this.currentFont, required this.onFont});

  @override
  State<FontFullscreen> createState() => _FontFullscreenState();
}

class _FontFullscreenState extends State<FontFullscreen> {
  String _query = '';
  String _category = 'Todas';
  FontEntry? _selected;

  List<String> get _categories {
    final cats = ['Todas', ...kFonts.map((f) => f.group).toSet().toList()];
    return cats;
  }

  List<FontEntry> get _filtered {
    return kFonts.where((f) {
      final matchCat = _category == 'Todas' || f.group == _category;
      final matchQ = _query.isEmpty || f.label.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: Row(
              children: [
                Text('Fontes', style: T.dmSans(size: 14, w: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: T.dmSans(size: 13),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar fonte…',
                      hintStyle: T.dmSans(size: 13, color: T.muted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: T.divider, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: T.divider, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.transparent,
                    ),
                    // CORRIGIDO: removido const — LucideIcons não é constante em compile-time
                    child: Icon(LucideIcons.x, size: 17, color: T.sub),
                  ),
                ),
              ],
            ),
          ),
          // Categories
          Container(
            height: 50,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: T.divider)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              children: _categories.map((cat) {
                final active = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? T.accent : T.divider,
                        width: 1.5,
                      ),
                      color: active ? T.accentBg : Colors.transparent,
                    ),
                    child: Text(
                      cat,
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
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final f = _filtered[i];
                final isSelected = _selected?.family == f.family;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? T.accent : T.divider,
                        width: 1.5,
                      ),
                      color: isSelected ? T.accentBg : Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.group.toUpperCase(),
                          style: T.dmSans(size: 10, w: FontWeight.w700, color: T.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            'Aa Bb',
                            style: TextStyle(
                              fontFamily: f.family,
                              fontSize: 20,
                              color: T.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          f.label,
                          style: T.dmSans(size: 10, color: T.sub),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: T.divider)),
            ),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _selected != null ? () => widget.onFont(_selected!.family) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selected != null ? T.accent : const Color(0x14000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _selected != null
                        ? 'Aplicar "${_selected!.label}"'
                        : 'Aplicar fonte',
                    style: T.dmSans(
                      size: 13.5,
                      w: FontWeight.w600,
                      color: _selected != null ? Colors.white : T.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
