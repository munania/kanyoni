import 'package:flutter/material.dart';
import 'package:kanyoni/controllers/theme_controller.dart';

class AppTheme {
  static const double cornerRadius = 8.0;

  static ThemeData lightTheme(ThemeController themeController) {
    // Get the primary color from the controller
    final primaryColor = themeController.primaryColor;

    // Generate subtle background colors based on primary color
    final scaffoldBackgroundColor = _getLightBackground(primaryColor);
    final cardColor = _getLightCardColor(primaryColor);
    final appBarColor = _getLightAppBarColor(primaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,

      // Apply color scheme - this is critical for modern Flutter
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        onPrimary: Colors.white,
        surface: cardColor,
        onSurface: Colors.black87,
        primaryContainer: primaryColor.withValues(alpha: 0.1),
        secondaryContainer: primaryColor.withValues(alpha: 0.05),
      ),

      // Apply color to AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      // Apply color to cards
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        elevation: 2,
      ),

      // Apply color to buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
      ),

      // Apply color to floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Apply color to text selection and cursors
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),

      // Apply color to switches, checkboxes
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.5);
        }),
      ),
    );
  }

  static ThemeData darkTheme(ThemeController themeController) {
    // Get the primary color from the controller
    final primaryColor = themeController.primaryColor;

    // Generate subtle background colors based on primary color
    final scaffoldBackgroundColor = _getDarkBackground(primaryColor);
    final cardColor = _getDarkCardColor(primaryColor);
    final appBarColor = _getDarkAppBarColor(primaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,

      // Apply color scheme - this is critical for modern Flutter
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        onPrimary: Colors.white,
        surface: cardColor,
        onSurface: Colors.white,
        primaryContainer: primaryColor.withValues(alpha: 0.15),
        secondaryContainer: primaryColor.withValues(alpha: 0.1),
      ),

      // Apply color to AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      // Apply color to cards
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        elevation: 2,
      ),

      // Apply color to buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
      ),

      // Apply color to floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Apply color to text selection and cursors
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),

      // Apply color to switches, checkboxes
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
    );
  }

  // Helper methods to generate subtle background colors
  static Color _getLightBackground(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Very light, highly desaturated version for background
    return hsl.withLightness(0.97).withSaturation(0.10).toColor();
  }

  static Color _getLightCardColor(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Slightly less light than background for card contrast
    return hsl.withLightness(0.94).withSaturation(0.08).toColor();
  }

  static Color _getLightAppBarColor(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Subtle tint for app bar
    return hsl.withLightness(0.95).withSaturation(0.12).toColor();
  }

  static Color _getDarkBackground(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Very dark, slightly tinted version for background
    return hsl.withLightness(0.26).withSaturation(0.25).toColor();
  }

  static Color _getDarkCardColor(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Slightly lighter than background for card contrast
    return hsl.withLightness(0.26).withSaturation(0.25).toColor();
  }

  static Color _getDarkAppBarColor(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    // Subtle tint for app bar in dark mode
    return hsl.withLightness(0.26).withSaturation(0.25).toColor();
  }

  // Custom Colors for Music App - Dynamic based on theme
  static Color nowPlayingLight(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.95).withSaturation(0.08).toColor();
  }

  static Color nowPlayingDark(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.10).withSaturation(0.18).toColor();
  }

  static Color playerControlsLight(Color primaryColor) {
    // Slightly darker version of primary for controls
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.45).withSaturation(0.70).toColor();
  }

  static Color playerControlsDark(Color primaryColor) {
    // Slightly lighter version of primary for controls
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.65).withSaturation(0.65).toColor();
  }

  static Color progressBarLight(Color primaryColor) {
    // Medium version of primary for progress bar
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.50).withSaturation(0.75).toColor();
  }

  static Color progressBarDark(Color primaryColor) {
    // Lighter version of primary for progress bar
    final hsl = HSLColor.fromColor(primaryColor);
    return hsl.withLightness(0.60).withSaturation(0.70).toColor();
  }

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );
}

class AppColors {
  // Base theme colors
  static const Color primaryLight = Color(0xFF333333); // Default dark gray
  static const Color primaryDark = Color(0xFFE0E0E0); // Default light gray

  // Theme color options - Updated with subtle, well-contrasting colors
  static const Map<String, ColorOption> themeColors = {
    'gray': ColorOption(
      name: 'Gray',
      light: Color(0xFF333333),
      dark: Color(0xFFE0E0E0),
    ),
    'blue': ColorOption(
      name: 'Blue',
      light: Color(0xFF2962FF),
      dark: Color(0xFF448AFF),
    ),
    'purple': ColorOption(
      name: 'Purple',
      light: Color(0xFF6200EA),
      dark: Color(0xFF7C4DFF),
    ),
    'green': ColorOption(
      name: 'Green',
      light: Color(0xFF00C853),
      dark: Color(0xFF69F0AE),
    ),
    'red': ColorOption(
      name: 'Red',
      light: Color(0xFFD50000),
      dark: Color(0xFFFF5252),
    ),
    'orange': ColorOption(
      name: 'Orange',
      light: Color(0xFFFF6D00),
      dark: Color(0xFFFF9E40),
    ),
  };
}

class ColorOption {
  final String name;
  final Color light;
  final Color dark;

  const ColorOption({
    required this.name,
    required this.light,
    required this.dark,
  });
}
