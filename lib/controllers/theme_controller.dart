import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  // Observable variables
  final RxString themeMode = 'system'.obs; // 'system', 'light', 'dark'
  final RxString themeColor = 'blue'.obs; // Default color theme

  final RxString waveformStyle =
      'Polygon'.obs; // 'Polygon', 'Rectangle', 'Squiggly', 'Curved'

  // Computed value for dark mode based on theme mode and system brightness
  bool get isDarkMode {
    if (themeMode.value == 'system') {
      // Get system brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode.value == 'dark';
  }

  // Initialize controller
  @override
  void onInit() {
    super.onInit();
    loadThemeSettings();
  }

  // Load saved theme settings
  Future<void> loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode (system/light/dark)
    final savedThemeMode = prefs.getString('themeMode');
    if (savedThemeMode != null &&
        ['system', 'light', 'dark'].contains(savedThemeMode)) {
      themeMode.value = savedThemeMode;
    } else {
      // Default to system on first launch
      themeMode.value = 'system';
    }

    // Load theme color
    final savedColor = prefs.getString('themeColor');
    if (savedColor != null && AppColors.themeColors.containsKey(savedColor)) {
      themeColor.value = savedColor;
    }

    // Load waveform style
    final savedWaveformStyle = prefs.getString('waveformStyle');
    if (savedWaveformStyle != null &&
        ['Polygon', 'Rectangle', 'Squiggly', 'Curved']
            .contains(savedWaveformStyle)) {
      waveformStyle.value = savedWaveformStyle;
    }
  }

  // Set theme mode (system/light/dark)
  Future<void> setThemeMode(String mode) async {
    if (['system', 'light', 'dark'].contains(mode)) {
      themeMode.value = mode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode);
    }
  }

  // Toggle between light and dark mode (for backward compatibility)
  Future<void> toggleThemeMode() async {
    if (themeMode.value == 'light') {
      await setThemeMode('dark');
    } else {
      await setThemeMode('light');
    }
  }

  // Change theme color
  Future<void> changeThemeColor(String colorKey) async {
    if (AppColors.themeColors.containsKey(colorKey)) {
      themeColor.value = colorKey;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeColor', colorKey);
    }
  }

  // Set waveform style
  Future<void> setWaveformStyle(String style) async {
    if (['Polygon', 'Rectangle', 'Squiggly', 'Curved'].contains(style)) {
      waveformStyle.value = style;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('waveformStyle', style);
    }
  }

  // Get current primary color based on theme mode
  Color get primaryColor {
    final colorOption = AppColors.themeColors[themeColor.value] ??
        AppColors.themeColors['blue']!;

    return isDarkMode ? colorOption.dark : colorOption.light;
  }

  // Get ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (themeMode.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
