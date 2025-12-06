import 'package:flutter/material.dart';
import 'package:kanyoni/controllers/theme_controller.dart';

class AppTheme {
  static const double cornerRadius = 8.0;

  static ThemeData lightTheme(ThemeController themeController) {
    // Get the primary color from the controller
    final primaryColor = themeController.primaryColor;

    // Generate polished background colors
    const scaffoldBackgroundColor = Color(0xFFF8F9FA);
    const cardColor = Colors.white;
    const surfaceColor = Color(0xFFFAFAFA);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,

      // Comprehensive color scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        onPrimary: Colors.white,
        surface: cardColor,
        onSurface: const Color(0xFF1A1A1A),
        surfaceContainerHighest: surfaceColor,
        primaryContainer: primaryColor.withValues(alpha: 0.12),
        secondaryContainer: primaryColor.withValues(alpha: 0.08),
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: primaryColor.withValues(alpha: 0.05),
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: primaryColor.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: const Color(0xFF424242),
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF757575),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Text selection theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return const Color(0xFFBDBDBD);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withValues(alpha: 0.2),
        circularTrackColor: primaryColor.withValues(alpha: 0.2),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: Color(0xFF424242)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData darkTheme(ThemeController themeController) {
    // Get the primary color from the controller
    final primaryColor = themeController.primaryColor;

    // Polished dark theme colors
    const scaffoldBackgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF1A1A1A);
    const surfaceColor = Color(0xFF242424);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,

      // Comprehensive color scheme
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        onPrimary: Colors.black,
        surface: cardColor,
        onSurface: const Color(0xFFE8E8E8),
        surfaceContainerHighest: surfaceColor,
        primaryContainer: primaryColor.withValues(alpha: 0.18),
        secondaryContainer: primaryColor.withValues(alpha: 0.12),
        error: const Color(0xFFEF5350),
        onError: Colors.black,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: primaryColor.withValues(alpha: 0.08),
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: const Color(0xFFE8E8E8),
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.15,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: primaryColor.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: const Color(0xFFB0B0B0),
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Text selection theme
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.4),
        selectionHandleColor: primaryColor,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return const Color(0xFF616161);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return const Color(0xFF424242);
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withValues(alpha: 0.2),
        circularTrackColor: primaryColor.withValues(alpha: 0.2),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Color(0xFFE8E8E8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: Color(0xFFE8E8E8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
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

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );
}

class AppColors {
  // Base theme colors
  static const Color primaryLight = Color(0xFF333333); // Default dark gray
  static const Color primaryDark = Color(0xFFE0E0E0); // Default light gray

  // Polished theme color options with modern, accessible colors
  static const Map<String, ColorOption> themeColors = {
    'blue': ColorOption(
      name: 'Ocean Blue',
      light: Color(0xFF1976D2),
      dark: Color(0xFF64B5F6),
    ),
    'purple': ColorOption(
      name: 'Royal Purple',
      light: Color(0xFF7B1FA2),
      dark: Color(0xFFBA68C8),
    ),
    'teal': ColorOption(
      name: 'Teal',
      light: Color(0xFF00897B),
      dark: Color(0xFF4DB6AC),
    ),
    'indigo': ColorOption(
      name: 'Indigo',
      light: Color(0xFF3949AB),
      dark: Color(0xFF7986CB),
    ),
    'pink': ColorOption(
      name: 'Pink',
      light: Color(0xFFC2185B),
      dark: Color(0xFFF06292),
    ),
    'amber': ColorOption(
      name: 'Amber',
      light: Color(0xFFF57C00),
      dark: Color(0xFFFFB74D),
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
