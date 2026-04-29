import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1B4332);
  static const Color secondaryColor = Color(0xFFD8F3DC);
  static const Color tertiaryColor = Color(0xFFF5F3F0);
  static const Color neutralColor = Color(0xFFE5E5E5);

  static const Color backgroundColor = neutralColor;
  static const Color cardColor = tertiaryColor;
  static const Color textColor = Color(0xFF191C1A);
  static const Color bodyTextColor = Color(0xFF3F4843);
  static const Color mutedTextColor = Color(0xFF7B827E);
  static const Color borderColor = Color(0xFFC6CBC7);
  static const Color invertedColor = Color(0xFF303331);
  static const Color dangerColor = Color(0xFFD11F1F);

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: cardColor,
          error: dangerColor,
        ).copyWith(
          onPrimary: Colors.white,
          onSecondary: primaryColor,
          onTertiary: textColor,
          onSurface: textColor,
          outline: borderColor,
          surfaceContainerHighest: neutralColor,
          surfaceTint: Colors.transparent,
        );

    final baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.apply(
        bodyColor: bodyTextColor,
        displayColor: textColor,
      ),
      iconTheme: const IconThemeData(color: primaryColor, size: 22),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tertiaryColor,
        hintStyle: const TextStyle(color: mutedTextColor),
        labelStyle: const TextStyle(color: mutedTextColor),
        floatingLabelStyle: const TextStyle(color: primaryColor),
        prefixIconColor: mutedTextColor,
        suffixIconColor: mutedTextColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: mutedTextColor,
          elevation: 0,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: mutedTextColor,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: borderColor),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: tertiaryColor,
        indicatorColor: primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: secondaryColor,
        selectionHandleColor: primaryColor,
      ),
    );
  }
}
