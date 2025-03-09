import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/base_controller.dart';

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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode'),
                Obx(() {
                  return Switch(
                    value: baseController.isDarkModeEnabled.value,
                    onChanged: (value) {
                      baseController.toggleDarkMode(value);
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
