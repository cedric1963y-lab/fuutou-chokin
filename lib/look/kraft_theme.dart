import 'package:flutter/material.dart';

import '../domain/ledger.dart';

/// クラフト紙と茶封筒の色。
abstract final class Kraft {
  static const paper = Color(0xFFEADBC0);
  static const paperDeep = Color(0xFFDCC7A2);
  static const card = Color(0xFFF6EEDD);
  static const ink = Color(0xFF3B2A1E);
  static const inkSoft = Color(0xFF7A6250);
  static const line = Color(0xFFC9B08A);
  static const stamp = Color(0xFFB4442E);
  static const leaf = Color(0xFF5E7A4C);
  static const coin = Color(0xFFD9A93E);
  static const coinDeep = Color(0xFFA9781E);
  static const bar = Color(0xFF4A3727);

  static const display = 'KiwiMaru';

  static Color tint(EnvelopeTint t) => switch (t) {
        EnvelopeTint.kraft => const Color(0xFFC79A64),
        EnvelopeTint.clay => const Color(0xFFBF7354),
        EnvelopeTint.mustard => const Color(0xFFD6AC4E),
        EnvelopeTint.sage => const Color(0xFF97A983),
        EnvelopeTint.slate => const Color(0xFF8299AE),
        EnvelopeTint.rose => const Color(0xFFCF9590),
        EnvelopeTint.ivory => const Color(0xFFE9DCBD),
        EnvelopeTint.plum => const Color(0xFFA7869A),
      };

  static String tintName(EnvelopeTint t) => switch (t) {
        EnvelopeTint.kraft => '茶封筒',
        EnvelopeTint.clay => 'れんが',
        EnvelopeTint.mustard => 'からし',
        EnvelopeTint.sage => 'よもぎ',
        EnvelopeTint.slate => 'ねずみ',
        EnvelopeTint.rose => 'さくら',
        EnvelopeTint.ivory => '生成り',
        EnvelopeTint.plum => 'ふじ',
      };

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C6B3C),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF7B4F2A),
      onPrimary: Colors.white,
      secondary: stamp,
      surface: card,
      onSurface: ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: display,
          fontSize: 22,
          color: ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF3E7D0),
        indicatorColor: const Color(0xFFE2C79C),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7B4F2A),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDCC8A6)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFDCC8A6)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBF6EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bar,
      ),
    );
  }
}
