import 'package:flutter/material.dart';

class AppStyles {
  // --- COLORS ---
  static const Color primaryColor = Color(0xFF0D47A1); // A deep, rich blue
  static const Color primaryColorLight = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(
    0xFFF5F5F5,
  ); // Light grey for background
  static const Color cardColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF212121); // Nearly black
  static const Color secondaryTextColor = Color(0xFF757575); // Grey

  // --- TEXT STYLES ---
  static const TextStyle h1 = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.bold,
    fontSize: 24,
    color: primaryTextColor,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.bold,
    fontSize: 20,
    color: primaryTextColor,
  );

  static const TextStyle articleTitle = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: primaryTextColor,
    height: 1.3,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    color: secondaryTextColor,
    height: 1.5,
  );

  static const TextStyle cardSnippet = TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 14,
    color: secondaryTextColor,
    height: 1.4,
  );

  static const TextStyle metadata = TextStyle(
    fontFamily: 'sans-serif',
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: secondaryTextColor,
  );

  // --- THEME DATA ---
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'sans-serif',

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0, // Flat app bar
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accentColor, width: 3.0),
        ),
      ),

      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: secondaryTextColor),
        prefixIconColor: secondaryTextColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColorLight),
      ),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
