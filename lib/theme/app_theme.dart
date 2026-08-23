import 'package:flutter/material.dart';

class FuturisticThemeExtension
    extends ThemeExtension<FuturisticThemeExtension> {
  final Color glowColor1;
  final Color glowColor2;
  final Color accentColor;
  final Color logoBg;
  final Color borderColor;
  final LinearGradient headerGradient;

  const FuturisticThemeExtension({
    required this.glowColor1,
    required this.glowColor2,
    required this.accentColor,
    required this.logoBg,
    required this.borderColor,
    required this.headerGradient,
  });

  @override
  FuturisticThemeExtension copyWith({
    Color? glowColor1,
    Color? glowColor2,
    Color? accentColor,
    Color? logoBg,
    Color? borderColor,
    LinearGradient? headerGradient,
  }) {
    return FuturisticThemeExtension(
      glowColor1: glowColor1 ?? this.glowColor1,
      glowColor2: glowColor2 ?? this.glowColor2,
      accentColor: accentColor ?? this.accentColor,
      logoBg: logoBg ?? this.logoBg,
      borderColor: borderColor ?? this.borderColor,
      headerGradient: headerGradient ?? this.headerGradient,
    );
  }

  @override
  FuturisticThemeExtension lerp(
    ThemeExtension<FuturisticThemeExtension>? other,
    double t,
  ) {
    if (other is! FuturisticThemeExtension) {
      return this;
    }
    return FuturisticThemeExtension(
      glowColor1: Color.lerp(glowColor1, other.glowColor1, t)!,
      glowColor2: Color.lerp(glowColor2, other.glowColor2, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      logoBg: Color.lerp(logoBg, other.logoBg, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      headerGradient: LinearGradient.lerp(
        headerGradient,
        other.headerGradient,
        t,
      )!,
    );
  }
}

class AppTheme {
  // Futuristic Dark Theme Colors
  static const Color darkBg = Color(0xFF0F111A);
  static const Color darkCard = Color(0xFF161925);
  static const Color darkPrimary = Color(0xFF00F2FE);
  static const Color darkSecondary = Color(0xFF4FACFE);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSubText = Color(0xFF8F94AD);

  // Futuristic Light Theme Colors (Silver Teal)
  static const Color lightBg = Color(0xFFF4F7FC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF00B4D8);
  static const Color lightSecondary = Color(0xFF0077B6);
  static const Color lightText = Color(0xFF1E2235);
  static const Color lightSubText = Color(0xFF6C7293);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        surface: darkCard,
        primary: darkPrimary,
        secondary: darkSecondary,
        onSurface: darkText,
        onSurfaceVariant: darkSubText,
      ),
      cardTheme: const CardThemeData(color: darkCard, elevation: 4),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: darkPrimary,
        unselectedItemColor: Color(0xFF454B6B),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkSubText),
        bodyLarge: TextStyle(color: darkText),
        bodySmall: TextStyle(color: darkSubText),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white.withValues(alpha: 0.3);
          }
          return Colors.transparent;
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        checkmarkColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      extensions: const [
        FuturisticThemeExtension(
          glowColor1: Color(0xFF00F2FE),
          glowColor2: Color(0xFF4FACFE),
          accentColor: Color(0xFF00F2FE),
          logoBg: Color(0xFF1E2235),
          borderColor: Color(0xFF333852),
          headerGradient: LinearGradient(
            colors: [Color(0xFF0F111A), Color(0xFF1E2235)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.light(
        surface: lightCard,
        primary: lightPrimary,
        secondary: lightSecondary,
        onSurface: lightText,
        onSurfaceVariant: lightSubText,
      ),
      cardTheme: const CardThemeData(color: lightCard, elevation: 2),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: lightPrimary,
        unselectedItemColor: Color(0xFF8F94AD),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: lightSubText),
        bodyLarge: TextStyle(color: lightText),
        bodySmall: TextStyle(color: lightSubText),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightSecondary;
          }
          return lightPrimary;
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        checkmarkColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      extensions: const [
        FuturisticThemeExtension(
          glowColor1: Color(0xFF00B4D8),
          glowColor2: Color(0xFF0077B6),
          accentColor: Color(0xFF00B4D8),
          logoBg: Color(0xFFE2F6FC),
          borderColor: Color(0xFFE2E8F0),
          headerGradient: LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }
}
