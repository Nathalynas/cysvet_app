import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFF1B4332);
  static const Color secondaryColor = Color(0xFFD8F3DC);
  static const Color tertiaryColor = Color.fromARGB(255, 253, 251, 248);
  static const Color neutralColor = Color.fromARGB(255, 250, 250, 250);

  static const Color backgroundColor = neutralColor;
  static const Color cardColor = tertiaryColor;
  static const Color textColor = Color(0xFF191C1A);
  static const Color bodyTextColor = Color(0xFF3F4843);
  static const Color mutedTextColor = Color(0xFF7B827E);
  static const Color borderColor = Color(0xFFC6CBC7);
  static const Color invertedColor = Color(0xFF303331);
  static const Color dangerColor = Color(0xFFD11F1F);

  static ThemeData get lightTheme => _buildTheme(
    palette: const _AppPalette(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: primaryColor,
      tertiary: tertiaryColor,
      neutral: neutralColor,
      background: backgroundColor,
      card: cardColor,
      text: textColor,
      bodyText: bodyTextColor,
      mutedText: mutedTextColor,
      border: borderColor,
      danger: dangerColor,
      onDanger: Colors.white,
      shadow: Color(0x33000000),
    ),
  );

  static ThemeData get darkTheme => _buildTheme(
    palette: const _AppPalette(
      brightness: Brightness.dark,
      primary: Color(0xFF95D5B2),
      onPrimary: Color(0xFF00391F),
      secondary: Color(0xFF1B4332),
      onSecondary: Color(0xFFE5F6EA),
      tertiary: Color(0xFF18211C),
      neutral: Color(0xFF101512),
      background: Color(0xFF101512),
      card: Color(0xFF18211C),
      text: Color(0xFFE7ECE8),
      bodyText: Color(0xFFC8D0CB),
      mutedText: Color(0xFF94A09A),
      border: Color(0xFF38443D),
      danger: Color(0xFFFFB4AB),
      onDanger: Color(0xFF690005),
      shadow: Color(0x99000000),
    ),
  );

  static ThemeData _buildTheme({required _AppPalette palette}) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: palette.brightness,
          primary: palette.primary,
          secondary: palette.secondary,
          tertiary: palette.tertiary,
          surface: palette.card,
          error: palette.danger,
        ).copyWith(
          onPrimary: palette.onPrimary,
          onSecondary: palette.onSecondary,
          onTertiary: palette.text,
          onSurface: palette.text,
          onError: palette.onDanger,
          outline: palette.border,
          surfaceContainerHighest: palette.neutral,
          surfaceTint: Colors.transparent,
        );

    final baseTextTheme = GoogleFonts.interTextTheme(
      palette.brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    );
    final buttonTextStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final disabledBackgroundColor = colorScheme.onSurface.withValues(
      alpha: 0.12,
    );
    final disabledForegroundColor = colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: palette.background,
      shadowColor: palette.shadow,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.apply(
        bodyColor: palette.bodyText,
        displayColor: palette.text,
      ),
      iconTheme: IconThemeData(color: colorScheme.primary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
        labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: GoogleFonts.inter(color: colorScheme.primary),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.45),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabledBackgroundColor,
          disabledForegroundColor: disabledForegroundColor,
          elevation: 0,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabledBackgroundColor,
          disabledForegroundColor: disabledForegroundColor,
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: buttonTextStyle,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }

          return GoogleFonts.inter(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }

          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        useIndicator: false,
        minExtendedWidth: 220,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.24),
        selectionHandleColor: colorScheme.primary,
      ),
    );
  }
}

class _AppPalette {
  const _AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.neutral,
    required this.background,
    required this.card,
    required this.text,
    required this.bodyText,
    required this.mutedText,
    required this.border,
    required this.danger,
    required this.onDanger,
    required this.shadow,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color neutral;
  final Color background;
  final Color card;
  final Color text;
  final Color bodyText;
  final Color mutedText;
  final Color border;
  final Color danger;
  final Color onDanger;
  final Color shadow;
}
