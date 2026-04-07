import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── THEME TOKENS ────────────────────────────────────────────────────────────
class T {
  static const accent = Color(0xFF2563EB);
  static const accentBg = Color(0xFFEFF6FF);
  static const ink = Color(0xFF34322D);
  static const sub = Color(0xFF5E5E5B);
  static const muted = Color(0xFF858481);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF8F8F7);
  static const divider = Color(0x14000000);
  static const dark = Color(0xFF1C1C1E);

  static TextStyle dmSans({
    double size = 14,
    FontWeight w = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color ?? ink);

  static TextStyle lora({
    double size = 16,
    FontWeight w = FontWeight.w400,
    Color? color,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.lora(
          fontSize: size, fontWeight: w, color: color ?? ink, fontStyle: style);
}
