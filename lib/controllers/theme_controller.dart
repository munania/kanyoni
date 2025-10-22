import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  // Observable variables
  final RxBool isDarkMode = false.obs;
  final RxString themeColor = 'blue'.obs; // Default color theme

  // Initialize controller
  @override
  void onInit() {
    super.onInit();
    loadThemeSettings();
  }

  // Load saved theme settings
  Future<void> loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode (light/dark)
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      isDarkMode.value = isDark;
    }

    // Load theme color
    final savedColor = prefs.getString('themeColor');
    if (savedColor != null && AppColors.themeColors.containsKey(savedColor)) {
      themeColor.value = savedColor;
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    isDarkMode.value = !isDarkMode.value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode.value);
  }

  // Change theme color
  Future<void> changeThemeColor(String colorKey) async {
    if (AppColors.themeColors.containsKey(colorKey)) {
      themeColor.value = colorKey;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeColor', colorKey);
    }
  }

  // Get current primary color based on theme mode
  Color get primaryColor {
    final colorOption = AppColors.themeColors[themeColor.value] ??
        AppColors.themeColors['blue']!;

    return isDarkMode.value ? colorOption.dark : colorOption.light;
  }
}
