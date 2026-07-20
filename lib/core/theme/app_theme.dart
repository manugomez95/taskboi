import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Represents a selectable app theme with a primary color
class AppColorTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;

  const AppColorTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Get light theme data for this color theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }

  /// Get dark theme data for this color theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
    );
  }
}

/// Collection of all available themes
class AppTheme {
  // Default theme (original Todoist red)
  static const defaultTheme = AppColorTheme(
    id: 'default',
    name: 'Default',
    primaryColor: Color(0xFFDC4C3E),
    secondaryColor: Color(0xFF6366F1),
  );

  // Blue theme
  static const blueTheme = AppColorTheme(
    id: 'blue',
    name: 'Ocean',
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF0EA5E9),
  );

  // Green theme
  static const greenTheme = AppColorTheme(
    id: 'green',
    name: 'Forest',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF34D399),
  );

  // Purple theme
  static const purpleTheme = AppColorTheme(
    id: 'purple',
    name: 'Lavender',
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
  );

  // Orange theme
  static const orangeTheme = AppColorTheme(
    id: 'orange',
    name: 'Sunset',
    primaryColor: Color(0xFFF59E0B),
    secondaryColor: Color(0xFFFBBF24),
  );

  // Teal theme
  static const tealTheme = AppColorTheme(
    id: 'teal',
    name: 'Teal',
    primaryColor: Color(0xFF14B8A6),
    secondaryColor: Color(0xFF2DD4BF),
  );

  // Pink theme
  static const pinkTheme = AppColorTheme(
    id: 'pink',
    name: 'Rose',
    primaryColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFF472B6),
  );

  // Indigo theme
  static const indigoTheme = AppColorTheme(
    id: 'indigo',
    name: 'Indigo',
    primaryColor: Color(0xFF6366F1),
    secondaryColor: Color(0xFF818CF8),
  );

  // Slate theme (dark/neutral)
  static const slateTheme = AppColorTheme(
    id: 'slate',
    name: 'Slate',
    primaryColor: Color(0xFF64748B),
    secondaryColor: Color(0xFF94A3B8),
  );

  // Amber theme
  static const amberTheme = AppColorTheme(
    id: 'amber',
    name: 'Amber',
    primaryColor: Color(0xFFD97706),
    secondaryColor: Color(0xFFF59E0B),
  );

  /// List of all available themes
  static const List<AppColorTheme> allThemes = [
    defaultTheme,
    blueTheme,
    greenTheme,
    purpleTheme,
    orangeTheme,
    tealTheme,
    pinkTheme,
    indigoTheme,
    slateTheme,
    amberTheme,
  ];

  /// Get theme by ID, defaults to defaultTheme if not found
  static AppColorTheme getThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => defaultTheme,
    );
  }

  // Backward compatibility - get static themes
  static ThemeData get lightTheme => defaultTheme.lightTheme;
  static ThemeData get darkTheme => defaultTheme.darkTheme;
}

// Priority colors (unchanged)
class TaskPriority {
  static const int none = 0;
  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;
  static const int urgent = 4;

  static Color getColor(int priority) {
    switch (priority) {
      case urgent:
        return const Color(0xFFDC4C3E); // Red
      case high:
        return const Color(0xFFF59E0B); // Orange
      case medium:
        return const Color(0xFF3B82F6); // Blue
      case low:
        return const Color(0xFF6B7280); // Gray
      default:
        return Colors.transparent;
    }
  }

  static String getLabel(int priority) {
    switch (priority) {
      case urgent:
        return 'Urgent';
      case high:
        return 'High';
      case medium:
        return 'Medium';
      case low:
        return 'Low';
      default:
        return 'None';
    }
  }

  static String getLabelWithL10n(int priority, AppLocalizations l10n) {
    switch (priority) {
      case urgent:
        return l10n.priorityUrgent;
      case high:
        return l10n.priorityHigh;
      case medium:
        return l10n.priorityMedium;
      case low:
        return l10n.priorityLow;
      default:
        return l10n.priorityNone;
    }
  }
}
