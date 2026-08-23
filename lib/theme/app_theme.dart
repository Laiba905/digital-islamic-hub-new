import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF002419);
  static const Color primaryLight = Color(0xFF004D40);
  static const Color accentGreen = Color(0xFF81C784);

  // LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green.shade800,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(backgroundColor: Colors.green.shade800),
    colorScheme: ColorScheme.light(primary: Colors.green.shade800, secondary: accentGreen),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
    ),
  );

  // DARK THEME
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryLight,
    scaffoldBackgroundColor: primaryDark,
    colorScheme: const ColorScheme.dark(primary: accentGreen, secondary: accentGreen),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    ),
  );
}