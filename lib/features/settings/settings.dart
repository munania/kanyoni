import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/features/settings/behavior_settings.dart';
import 'package:kanyoni/features/settings/theme_settings.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BaseController baseController = Get.find<BaseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Iconsax.activity),
              title: const Text('Behavior'),
              subtitle: const Text('Customize app behavior'),
              onTap: () {
                Get.to(() => const BehaviorSettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.color_swatch),
              title: Text('Theme Settings', style: AppTheme.bodyLarge),
              onTap: () {
                Get.to(() => ThemeSettingsView());
              },
            ),
          ],
        ),
      ),
    );
  }
}
