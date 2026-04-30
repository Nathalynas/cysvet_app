import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );
    final buttonTextStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
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
        hintStyle: GoogleFonts.inter(color: mutedTextColor),
        labelStyle: GoogleFonts.inter(color: mutedTextColor),
        floatingLabelStyle: GoogleFonts.inter(color: primaryColor),
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
          textStyle: buttonTextStyle,
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
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: borderColor),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: buttonTextStyle,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tertiaryColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }

          return GoogleFonts.inter(
            color: mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }

          return const IconThemeData(color: mutedTextColor, size: 22);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tertiaryColor,
        elevation: 0,
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 24),
        unselectedIconTheme: const IconThemeData(
          color: mutedTextColor,
          size: 22,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: mutedTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        useIndicator: false,
        minExtendedWidth: 220,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: secondaryColor,
        selectionHandleColor: primaryColor,
      ),
    );
  }
}
