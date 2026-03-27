import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF059669);
    const accentColor = Color(0xFF059669);
    const accentLight = Color(0xFFD1FAE5);
    const accentDark = Color(0xFF064E3B);

    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFFAFAF9);
    final surfaceColor = isDark ? const Color(0xFF181C24) : const Color(0xFFFFFFFF);
    final cardBorder = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        background: bgColor,
        surface: surfaceColor,
        primary: accentColor,
        onPrimary: Colors.white,
        primaryContainer: isDark ? accentDark : accentLight,
        onPrimaryContainer: isDark ? const Color(0xFF6EE7B7) : accentDark,
        secondary: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
        tertiary: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
        error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917),
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C),
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        color: surfaceColor,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: const BorderSide(color: accentColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF5F5F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF78716C) : const Color(0xFF92928A),
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
          fontSize: 14,
        ),
        prefixStyle: TextStyle(
          color: isDark ? const Color(0xFF6EE7B7) : accentColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minLeadingWidth: 0,
      ),
      dividerTheme: DividerThemeData(color: cardBorder, thickness: 1, space: 0),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: isDark ? accentDark.withOpacity(0.7) : accentLight,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: accentColor, size: 22);
          }
          return IconThemeData(
            color: isDark ? const Color(0xFF57534E) : const Color(0xFF9CA3AF),
            size: 22,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.2,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF57534E) : const Color(0xFF9CA3AF),
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isDark ? const Color(0xFF292524) : const Color(0xFF1C1917),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: accentLight,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: isDark ? accentDark.withOpacity(0.5) : accentLight,
        labelPadding: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}