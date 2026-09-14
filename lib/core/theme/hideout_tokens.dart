// ============================================================
// HIDEOUT DESIGN TOKENS
// Source of truth for all colors, spacing, radius, and
// typography helpers. Import this file wherever you need
// Access to the HIDEOUT design system.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ─────────────────────────────────────────────────
class HDTColors {
  HDTColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0F1115);
  static const Color s1 = Color(0xFF181B21);
  static const Color s2 = Color(0xFF23282F);
  static const Color s3 = Color(0xFF2C333D);

  // Brand / Accent
  static const Color accent = Color(0xFF9B4FA3);
  static const Color accentDim = Color(0x229B4FA3);
  static const Color accentHover = Color(0xFFBB6FC3);

  // Text hierarchy
  static const Color text = Color(0xFFF1F3F7);
  static const Color text2 = Color(0xFF8B95A5);
  static const Color text3 = Color(0xFF4A5568);

  // State
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF5DADE2);

  // Deck classes
  static const Color rusher = Color(0xFFE67E22);
  static const Color stamina = Color(0xFF27AE60);
  static const Color defender = Color(0xFF3498DB);
  static const Color balance = Color(0xFF9B59B6);

  /// Return a color based on the deck class string.
  static Color fromDeckClass(String cls) {
    switch (cls.toUpperCase()) {
      case 'RUSHER':
        return rusher;
      case 'STAMINA':
        return stamina;
      case 'DEFENDER':
        return defender;
      case 'BALANCE':
        return balance;
      default:
        return text3;
    }
  }

  /// Return a color based on match result.
  static Color fromResult(String r) {
    switch (r.toUpperCase()) {
      case 'WIN':
        return success;
      case 'LOSS':
        return danger;
      default:
        return text3;
    }
  }

  /// Return a color based on game finish type.
  static Color fromFinish(String f) {
    switch (f.toUpperCase()) {
      case 'BURST':
        return accent;
      case 'OVER':
        return warning;
      case 'SPIN':
        return success;
      case 'LOSS':
        return danger;
      default:
        return text3;
    }
  }
}

// ─── Typography ─────────────────────────────────────────────
/// Helper for building TextStyle values that match the HIDEOUT design system.
/// - display / overline → Oswald
/// - mono               → JetBrains Mono
/// - body               → Inter
class HDTText {
  HDTText._();

  /// Oswald - used for headings, player names, and ELO numbers.
  static TextStyle display({
    double size = 20,
    Color? color,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
  }) =>
      GoogleFonts.oswald(
        fontSize: size,
        fontWeight: weight,
        color: color ?? HDTColors.text,
        letterSpacing: letterSpacing,
      );

  /// Small Oswald ALLCAPS - used for labels, badges, and overlines.
  static TextStyle overline({
    double size = 9,
    Color? color,
    double letterSpacing = 1.8,
  }) =>
      GoogleFonts.oswald(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? HDTColors.text3,
        letterSpacing: letterSpacing,
      );

  /// JetBrains Mono - IDs, dates, and technical numbers.
  static TextStyle mono({
    double size = 11,
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? HDTColors.text2,
      );

  /// Inter — body text umum, deskripsi
  static TextStyle body({
    double size = 13,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? HDTColors.text,
        height: height,
      );
}

// ─── Spacing ────────────────────────────────────────────────
class HDTSpace {
  HDTSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

// ─── Border Radius ──────────────────────────────────────────
class HDTR {
  HDTR._();
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius md = BorderRadius.all(Radius.circular(6));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(8));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(12));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

// ─── Box Decoration Helpers ──────────────────────────────────
/// Card standar HIDEOUT
BoxDecoration hdtCard({
  Color? bg,
  Color? borderColor,
  BorderRadius? radius,
  List<BoxShadow>? shadow,
}) =>
    BoxDecoration(
      color: bg ?? HDTColors.s1,
      borderRadius: radius ?? HDTR.lg,
      border: Border.all(color: borderColor ?? HDTColors.s2),
      boxShadow: shadow,
    );

/// Card with accent color in the gradient background.
BoxDecoration hdtAccentCard({
  required Color accentColor,
  BorderRadius? radius,
  bool highlighted = false,
}) =>
    BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.14),
          HDTColors.s1,
        ],
      ),
      borderRadius: radius ?? HDTR.lg,
      border: Border.all(
        color: highlighted ? accentColor.withValues(alpha: 0.5) : HDTColors.s2,
      ),
      boxShadow: highlighted
          ? [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 16)]
          : null,
    );

/// Divider horizontal standar
Widget hdtDivider({EdgeInsets margin = EdgeInsets.zero}) => Container(
      margin: margin,
      height: 1,
      color: HDTColors.s2,
    );
