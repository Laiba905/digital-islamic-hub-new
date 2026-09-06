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
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green.shade800,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.green.shade800,
      secondary: accentGreen,
      surface: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    useMaterial3: true,
  );

  // DARK THEME (Yahan update karna hai)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: primaryDark, // Background deep green ho gaya
    cardColor: primaryLight,             // Cards aur containers deep green ho gaye
    canvasColor: primaryLight,
    dialogBackgroundColor: primaryLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: accentGreen,
      secondary: accentGreen,
      surface: primaryLight,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
    useMaterial3: true,
  );
}