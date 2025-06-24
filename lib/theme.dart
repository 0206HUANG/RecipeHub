// theme.dart
import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Colors.green,
    onPrimary: Colors.white,
    secondary: Colors.orange,
    onSecondary: Colors.white,
    secondaryContainer: Color.fromARGB(255, 207, 237, 255),
    onSecondaryContainer: Color.fromARGB(255, 76, 189, 255),
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    error: Colors.red,
    onError: Colors.white,
  ),
  primaryColor: Colors.green[600],
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 239, 255, 237),
    foregroundColor: Colors.black,
    elevation: 1,
  ),
  iconTheme: const IconThemeData(color: Colors.black87),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Colors.green,
    unselectedItemColor: Colors.grey,
    backgroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  ),
  cardColor: Colors.grey[100],
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[200]!,
    labelStyle: const TextStyle(color: Colors.black),
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: Colors.white,
    textColor: Colors.black87,
    iconColor: Colors.black54,
  ),
  cardTheme: const CardThemeData(
    color: Color.fromARGB(255, 243, 245, 243),
    elevation: 2,
    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.green,
    onPrimary: Colors.black,
    secondary: Colors.orange,
    onSecondary: Colors.black,
    secondaryContainer: Color.fromARGB(255, 147, 215, 255),
    onSecondaryContainer: Color.fromARGB(255, 14, 115, 173),
    background: Color(0xFF121212),
    onBackground: Colors.white,
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
    error: Colors.red,
    onError: Colors.black,
  ),
  primaryColor: Colors.green[300],
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1F1F1F),
    foregroundColor: Colors.white,
    elevation: 1,
  ),
  iconTheme: const IconThemeData(color: Colors.white70),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Colors.greenAccent,
    unselectedItemColor: Colors.grey,
    backgroundColor: Color(0xFF1F1F1F),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(
        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
  ),
  cardColor: const Color.fromARGB(255, 53, 53, 53),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[800]!,
    labelStyle: const TextStyle(color: Colors.white),
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: Color(0xFF1E1E1E),
    textColor: Colors.white,
    iconColor: Colors.white70,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1E1E1E),
    elevation: 2,
    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);
