// ============================================================
// HIDEOUT THEME
// Gunakan di MaterialApp: theme: HDTTheme.dark
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hideout_tokens.dart';

class HDTTheme {
  HDTTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: HDTColors.bg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoPageTransitionsBuilder(),
          TargetPlatform.linux: _NoPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoPageTransitionsBuilder(),
          TargetPlatform.windows: _NoPageTransitionsBuilder(),
        },
      ),

      // ── Color Scheme ──────────────────────────────────────
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: HDTColors.accent,
        onPrimary: Colors.white,
        primaryContainer: HDTColors.accentDim,
        onPrimaryContainer: HDTColors.accentHover,
        secondary: HDTColors.accentHover,
        onSecondary: Colors.white,
        secondaryContainer: HDTColors.s3,
        onSecondaryContainer: HDTColors.text,
        tertiary: HDTColors.info,
        onTertiary: Colors.white,
        error: HDTColors.danger,
        onError: Colors.white,
        background: HDTColors.bg,
        onBackground: HDTColors.text,
        surface: HDTColors.s1,
        onSurface: HDTColors.text,
        surfaceVariant: HDTColors.s2,
        onSurfaceVariant: HDTColors.text2,
        outline: HDTColors.s2,
        outlineVariant: HDTColors.s3,
        shadow: Colors.black,
      ),

      // ── Text Theme ────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.oswald(
            fontSize: 48, fontWeight: FontWeight.w700, color: HDTColors.text),
        displayMedium: GoogleFonts.oswald(
            fontSize: 36, fontWeight: FontWeight.w700, color: HDTColors.text),
        displaySmall: GoogleFonts.oswald(
            fontSize: 28, fontWeight: FontWeight.w600, color: HDTColors.text),
        headlineLarge: GoogleFonts.oswald(
            fontSize: 24, fontWeight: FontWeight.w600, color: HDTColors.text),
        headlineMedium: GoogleFonts.oswald(
            fontSize: 20, fontWeight: FontWeight.w600, color: HDTColors.text),
        headlineSmall: GoogleFonts.oswald(
            fontSize: 16, fontWeight: FontWeight.w500, color: HDTColors.text),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: HDTColors.text),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: HDTColors.text),
        bodySmall: GoogleFonts.inter(fontSize: 11, color: HDTColors.text2),
        labelLarge: GoogleFonts.oswald(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: HDTColors.text2),
        labelMedium: GoogleFonts.oswald(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: HDTColors.text3),
        labelSmall: GoogleFonts.oswald(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
            color: HDTColors.text3),
        titleLarge:
            GoogleFonts.jetBrainsMono(fontSize: 14, color: HDTColors.text),
        titleMedium:
            GoogleFonts.jetBrainsMono(fontSize: 12, color: HDTColors.text2),
        titleSmall:
            GoogleFonts.jetBrainsMono(fontSize: 10, color: HDTColors.text3),
      ),

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xEB0F1115),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.oswald(
            fontSize: 20, fontWeight: FontWeight.w600, color: HDTColors.text),
        iconTheme: const IconThemeData(color: HDTColors.text2, size: 20),
        actionsIconTheme: const IconThemeData(color: HDTColors.text2, size: 20),
        toolbarHeight: 56,
      ),

      // ── Card ──────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: HDTColors.s1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: HDTR.lg,
          side: BorderSide(color: HDTColors.s2),
        ),
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: HDTColors.s2,
        thickness: 1,
        space: 0,
      ),

      // ── Input ─────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HDTColors.s1,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: HDTColors.text3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: const OutlineInputBorder(
            borderRadius: HDTR.md, borderSide: BorderSide(color: HDTColors.s2)),
        enabledBorder: const OutlineInputBorder(
            borderRadius: HDTR.md, borderSide: BorderSide(color: HDTColors.s2)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: HDTR.md,
            borderSide: BorderSide(color: HDTColors.accent, width: 1.5)),
        errorBorder: const OutlineInputBorder(
            borderRadius: HDTR.md,
            borderSide: BorderSide(color: HDTColors.danger)),
      ),

      // ── Buttons ───────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HDTColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.oswald(
              fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HDTColors.text2,
          side: const BorderSide(color: HDTColors.s2),
          textStyle: GoogleFonts.oswald(
              fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HDTColors.text2,
          textStyle: GoogleFonts.oswald(
              fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: HDTColors.s2,
        selectedColor: HDTColors.accentDim,
        deleteIconColor: HDTColors.text3,
        side: const BorderSide(color: HDTColors.s2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
        labelStyle: GoogleFonts.oswald(
            fontSize: 10, letterSpacing: 1.4, color: HDTColors.text2),
        brightness: Brightness.dark,
      ),

      // ── List Tile ─────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: HDTColors.accentDim,
        iconColor: HDTColors.text3,
        textColor: HDTColors.text,
        selectedColor: HDTColors.accentHover,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: HDTR.md),
      ),

      // ── Bottom Nav ────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HDTColors.s1,
        selectedItemColor: HDTColors.accentHover,
        unselectedItemColor: HDTColors.text3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ── Navigation Bar (Material 3) ───────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HDTColors.s1,
        indicatorColor: HDTColors.accentDim,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: HDTColors.accentHover, size: 22);
          }
          return const IconThemeData(color: HDTColors.text3, size: 22);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.oswald(
                fontSize: 10, letterSpacing: 1.2, color: HDTColors.accentHover);
          }
          return GoogleFonts.oswald(
              fontSize: 10, letterSpacing: 1.2, color: HDTColors.text3);
        }),
        elevation: 0,
        height: 64,
      ),

      // ── Navigation Rail ───────────────────────────────────
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: HDTColors.s1,
        selectedIconTheme:
            IconThemeData(color: HDTColors.accentHover, size: 20),
        unselectedIconTheme: IconThemeData(color: HDTColors.text3, size: 20),
        selectedLabelTextStyle:
            TextStyle(color: HDTColors.accentHover, fontSize: 10),
        unselectedLabelTextStyle:
            TextStyle(color: HDTColors.text3, fontSize: 10),
        indicatorColor: HDTColors.accentDim,
        elevation: 0,
      ),

      // ── Popup / Dialog ────────────────────────────────────
      dialogTheme: const DialogThemeData(
        backgroundColor: HDTColors.s1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: HDTR.xl,
          side: BorderSide(color: HDTColors.s2),
        ),
      ),

      // ── Snackbar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HDTColors.s3,
        contentTextStyle:
            GoogleFonts.inter(fontSize: 13, color: HDTColors.text),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: HDTR.md),
      ),

      // ── Progress Indicator ────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HDTColors.accent,
        linearTrackColor: HDTColors.s2,
      ),

      // ── Date Picker ───────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: HDTColors.s1,
        headerBackgroundColor: HDTColors.accent,
        headerForegroundColor: Colors.white,
        dayStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
        todayBorder: const BorderSide(color: HDTColors.accent),
        todayBackgroundColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? HDTColors.accent : null),
        shape: const RoundedRectangleBorder(borderRadius: HDTR.xl),
      ),
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
