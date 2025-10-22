import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class ThemeSettingsView extends StatelessWidget {
  final ThemeController themeController = Get.find<ThemeController>();

  ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Settings', style: AppTheme.headlineMedium),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark/Light mode toggle
          Obx(() => SwitchListTile(
                title: Text('Dark Mode', style: AppTheme.bodyLarge),
                secondary: Icon(themeController.isDarkMode.value
                    ? Iconsax.moon
                    : Iconsax.sun_1),
                value: themeController.isDarkMode.value,
                onChanged: (bool value) {
                  themeController.toggleThemeMode();
                },
              )),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Theme Color',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),

          // Color options grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: AppColors.themeColors.length,
              itemBuilder: (context, index) {
                final colorKey = AppColors.themeColors.keys.elementAt(index);
                final colorOption = AppColors.themeColors[colorKey]!;

                return Obx(() => GestureDetector(
                      onTap: () => themeController.changeThemeColor(colorKey),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: themeController.isDarkMode.value
                                  ? colorOption.dark
                                  : colorOption.light,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    themeController.themeColor.value == colorKey
                                        ? Colors.white
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: themeController.themeColor.value == colorKey
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(colorOption.name),
                        ],
                      ),
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
