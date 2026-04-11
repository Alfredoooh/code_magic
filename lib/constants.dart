import 'package:flutter/material.dart';

const kAccent   = Color(0xFF2563EB);
const kAccentBg = Color(0xFFEFF6FF);
const kInk      = Color(0xFF34322D);
const kSub      = Color(0xFF5E5E5B);
const kMuted    = Color(0xFF858481);
const kBg       = Color(0xFFF8F8F7);
const kWhite    = Colors.white;
const kBorder   = Color(0x14000000);
const kDark     = Color(0xFF1C1C1E);

const kPageWidth  = 794.0;
const kPageHeight = 1123.0;
const kPagePadH   = 88.0;
const kPagePadV   = 96.0;

const kCurve = Cubic(0.22, 1, 0.36, 1);
const kPopIn  = Cubic(0.34, 1.56, 0.64, 1);
const kPopOut = Cubic(0.55, 0, 0.45, 1);
const kSelIn  = Cubic(0.34, 1.56, 0.64, 1);

const kSwatchColors = [
  Color(0xFF000000), Color(0xFF34322D), Color(0xFF5E5E5B), Color(0xFF858481),
  Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFFFFFFF),
  Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFCA8A04),
  Color(0xFF65A30D), Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB),
  Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777),
  Color(0xFFFCA5A5), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFF86EFAC),
  Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFF9A8D4), Color(0xFFFDE68A),
  Color(0xFF6EE7B7), Color(0xFFA5B4FC), Color(0xFFFBCFE8), Color(0xFFE9D5FF),
];

class FontEntry {
  final String label;
  final String group;
  const FontEntry(this.label, this.group);
}

const kFonts = [
  FontEntry('Lora',              'Serif'),
  FontEntry('Playfair Display',  'Serif'),
  FontEntry('Merriweather',      'Serif'),
  FontEntry('Georgia',           'Serif'),
  FontEntry('Times New Roman',   'Serif'),
  FontEntry('Source Serif 4',    'Serif'),
  FontEntry('PT Serif',          'Serif'),
  FontEntry('Libre Baskerville', 'Serif'),
  FontEntry('EB Garamond',       'Serif'),
  FontEntry('Crimson Text',      'Serif'),
  FontEntry('Cormorant Garamond','Serif'),
  FontEntry('Noto Serif',        'Serif'),
  FontEntry('Spectral',          'Serif'),
  FontEntry('Zilla Slab',        'Serif'),
  FontEntry('Alegreya',          'Serif'),
  FontEntry('Vollkorn',          'Serif'),
  FontEntry('Bitter',            'Serif'),
  FontEntry('Arvo',              'Serif'),
  FontEntry('Cardo',             'Serif'),
  FontEntry('IBM Plex Serif',    'Serif'),
  FontEntry('Inter',             'Sans-serif'),
  FontEntry('Open Sans',         'Sans-serif'),
  FontEntry('Montserrat',        'Sans-serif'),
  FontEntry('DM Sans',           'Sans-serif'),
  FontEntry('Roboto',            'Sans-serif'),
  FontEntry('Nunito',            'Sans-serif'),
  FontEntry('Poppins',           'Sans-serif'),
  FontEntry('Raleway',           'Sans-serif'),
  FontEntry('Josefin Sans',      'Sans-serif'),
  FontEntry('Quicksand',         'Sans-serif'),
  FontEntry('Mulish',            'Sans-serif'),
  FontEntry('Work Sans',         'Sans-serif'),
  FontEntry('Karla',             'Sans-serif'),
  FontEntry('Cabin',             'Sans-serif'),
  FontEntry('Barlow',            'Sans-serif'),
  FontEntry('Fira Sans',         'Sans-serif'),
  FontEntry('Rubik',             'Sans-serif'),
  FontEntry('IBM Plex Sans',     'Sans-serif'),
  FontEntry('Arial',             'Sans-serif'),
  FontEntry('Helvetica',         'Sans-serif'),
  FontEntry('Verdana',           'Sans-serif'),
  FontEntry('Courier New',       'Monospace'),
  FontEntry('IBM Plex Mono',     'Monospace'),
  FontEntry('Source Code Pro',   'Monospace'),
  FontEntry('Fira Code',         'Monospace'),
  FontEntry('JetBrains Mono',    'Monospace'),
  FontEntry('Space Mono',        'Monospace'),
  FontEntry('Inconsolata',       'Monospace'),
  FontEntry('Ubuntu Mono',       'Monospace'),
  FontEntry('Cinzel',            'Decorativa'),
  FontEntry('Abril Fatface',     'Decorativa'),
  FontEntry('Pacifico',          'Decorativa'),
  FontEntry('Dancing Script',    'Manuscrita'),
  FontEntry('Great Vibes',       'Manuscrita'),
  FontEntry('Sacramento',        'Manuscrita'),
  FontEntry('Caveat',            'Manuscrita'),
  FontEntry('Kalam',             'Manuscrita'),
  FontEntry('Patrick Hand',      'Manuscrita'),
  FontEntry('Indie Flower',      'Manuscrita'),
  FontEntry('Permanent Marker',  'Manuscrita'),
];

const kFontSizePresets = [8,10,12,13,14,15,16,18,20,22,24,28,32,36,48,64,72];

// Icons.format_paragraph não existe no Flutter — substituído por Icons.notes.
const kStyleItems = [
  {'label': 'Parágrafo',  'block': 'p',          'icon': Icons.notes},
  {'label': 'Título 1',   'block': 'h1',         'icon': Icons.looks_one},
  {'label': 'Título 2',   'block': 'h2',         'icon': Icons.looks_two},
  {'label': 'Título 3',   'block': 'h3',         'icon': Icons.looks_3},
  {'label': 'Título 4',   'block': 'h4',         'icon': Icons.looks_4},
  {'label': 'Citação',    'block': 'blockquote', 'icon': Icons.format_quote},
  {'label': 'Código',     'block': 'pre',        'icon': Icons.code},
];

const kHighlightBoxes = [
  {'id': 'warn',    'label': 'Aviso',      'bg': Color(0xFFFEF3C7), 'border': Color(0xFFF59E0B), 'icon': '▲'},
  {'id': 'info',    'label': 'Informação', 'bg': Color(0xFFEFF6FF), 'border': Color(0xFF3B82F6), 'icon': 'i'},
  {'id': 'success', 'label': 'Sucesso',    'bg': Color(0xFFF0FDF4), 'border': Color(0xFF22C55E), 'icon': '✓'},
  {'id': 'error',   'label': 'Erro',       'bg': Color(0xFFFEF2F2), 'border': Color(0xFFEF4444), 'icon': '✕'},
];