import 'package:flutter/material.dart';

class AppTheme {
  // 1. Light Theme Colors & Configuration
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4F8), // Soft Light Slate
    cardColor: Colors.white,
    primaryColor: const Color(0xFF007AFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF007AFF),
      secondary: Color(0xFFFF5722),
      surface: Colors.white,
      onSurface: Color(0xFF102A43), // Dark text
    ),
  );

  // 2. Dark Theme Colors & Configuration (Image Wala Deep Teal Look)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1E29), // Deep Teal Background
    cardColor: const Color(0xFF162A38),     // Card Surface Color
    primaryColor: const Color(0xFF00E5FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5FF),     // Cyan Accent for Charts/Buttons
      secondary: Color(0xFFFF7A59),   // Orange Accent
      surface: Color(0xFF162A38),
      onSurface: Colors.white,        // White text
    ),
  );
}