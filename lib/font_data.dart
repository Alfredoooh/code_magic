import 'package:flutter/material.dart';

// ─── FONT DATA ────────────────────────────────────────────────────────────────
class FontEntry {
  final String label;
  final String family;
  final String group;
  const FontEntry(this.label, this.family, this.group);
}

const List<FontEntry> kFonts = [
  // Serif
  FontEntry('Lora', 'Lora', 'Serif'),
  FontEntry('Playfair Display', 'Playfair Display', 'Serif'),
  FontEntry('Merriweather', 'Merriweather', 'Serif'),
  FontEntry('Source Serif 4', 'Source Serif 4', 'Serif'),
  FontEntry('PT Serif', 'PT Serif', 'Serif'),
  FontEntry('Libre Baskerville', 'Libre Baskerville', 'Serif'),
  FontEntry('EB Garamond', 'EB Garamond', 'Serif'),
  FontEntry('Crimson Text', 'Crimson Text', 'Serif'),
  FontEntry('Cormorant Garamond', 'Cormorant Garamond', 'Serif'),
  FontEntry('Noto Serif', 'Noto Serif', 'Serif'),
  FontEntry('Spectral', 'Spectral', 'Serif'),
  FontEntry('Bitter', 'Bitter', 'Serif'),
  // Sans-serif
  FontEntry('Inter', 'Inter', 'Sans-serif'),
  FontEntry('Open Sans', 'Open Sans', 'Sans-serif'),
  FontEntry('Montserrat', 'Montserrat', 'Sans-serif'),
  FontEntry('DM Sans', 'DM Sans', 'Sans-serif'),
  FontEntry('Roboto', 'Roboto', 'Sans-serif'),
  FontEntry('Nunito', 'Nunito', 'Sans-serif'),
  FontEntry('Poppins', 'Poppins', 'Sans-serif'),
  FontEntry('Raleway', 'Raleway', 'Sans-serif'),
  FontEntry('Josefin Sans', 'Josefin Sans', 'Sans-serif'),
  FontEntry('Work Sans', 'Work Sans', 'Sans-serif'),
  FontEntry('Karla', 'Karla', 'Sans-serif'),
  FontEntry('Rubik', 'Rubik', 'Sans-serif'),
  FontEntry('IBM Plex Sans', 'IBM Plex Sans', 'Sans-serif'),
  FontEntry('Mulish', 'Mulish', 'Sans-serif'),
  FontEntry('Quicksand', 'Quicksand', 'Sans-serif'),
  // Monospace
  FontEntry('IBM Plex Mono', 'IBM Plex Mono', 'Monospace'),
  FontEntry('Source Code Pro', 'Source Code Pro', 'Monospace'),
  FontEntry('Fira Code', 'Fira Code', 'Monospace'),
  FontEntry('JetBrains Mono', 'JetBrains Mono', 'Monospace'),
  FontEntry('Space Mono', 'Space Mono', 'Monospace'),
  FontEntry('Inconsolata', 'Inconsolata', 'Monospace'),
  FontEntry('Ubuntu Mono', 'Ubuntu Mono', 'Monospace'),
  // Decorativa
  FontEntry('Cinzel', 'Cinzel', 'Decorativa'),
  FontEntry('Abril Fatface', 'Abril Fatface', 'Decorativa'),
  FontEntry('Pacifico', 'Pacifico', 'Decorativa'),
  FontEntry('Dancing Script', 'Dancing Script', 'Manuscrita'),
  FontEntry('Caveat', 'Caveat', 'Manuscrita'),
  FontEntry('Kalam', 'Kalam', 'Manuscrita'),
  FontEntry('Patrick Hand', 'Patrick Hand', 'Manuscrita'),
  FontEntry('Indie Flower', 'Indie Flower', 'Manuscrita'),
  FontEntry('Permanent Marker', 'Permanent Marker', 'Manuscrita'),
  FontEntry('Sacramento', 'Sacramento', 'Manuscrita'),
  FontEntry('Great Vibes', 'Great Vibes', 'Manuscrita'),
];

const List<Color> kColors = [
  Color(0xFF000000), Color(0xFF34322D), Color(0xFF5E5E5B), Color(0xFF858481),
  Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFFFFFFF),
  Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFD97706), Color(0xFFCA8A04),
  Color(0xFF65A30D), Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB),
  Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777),
  Color(0xFFFCA5A5), Color(0xFFFDBA74), Color(0xFFFCD34D), Color(0xFF86EFAC),
  Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFF9A8D4), Color(0xFFFDE68A),
  Color(0xFF6EE7B7), Color(0xFFA5B4FC), Color(0xFFFBCFE8), Color(0xFFE9D5FF),
];

const List<int> kSizes = [8, 10, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 32, 36, 48, 64, 72];
