import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController controller = Get.find<PlayerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Obx(() => Switch(
                value: controller.equalizerEnabled.value,
                onChanged: controller.isEqualizerInitialized.value
                    ? (value) {
                        controller.toggleEqualizer(value);
                      }
                    : null,
                activeThumbColor: Theme.of(context).primaryColor,
              )),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (!controller.isEqualizerInitialized.value) {
          return const Center(
            child: Text('Equalizer not available or loading...'),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 20),
            // Presets Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: controller.currentPreset.value.isEmpty
                        ? null
                        : controller.currentPreset.value,
                    hint: const Text('Select Preset'),
                    items: controller.equalizerPresets.map((String preset) {
                      return DropdownMenuItem<String>(
                        value: preset,
                        child: Text(preset),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.setPreset(newValue);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Bands Sliders
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.equalizerBands.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return Obx(() {
                    final freq = controller.equalizerCenterFreqs[index];
                    final level = controller.equalizerBands[index];
                    final min = controller.minBandLevel.value;
                    final max = controller.maxBandLevel.value;

                    return Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16),
                                ),
                                child: Slider(
                                  value: level.toDouble(),
                                  min: min,
                                  max: max,
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.2),
                                  onChanged: controller.equalizerEnabled.value
                                      ? (value) {
                                          controller.setBandLevel(
                                              index, value.toInt());
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${freq ~/ 1000}Hz',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${level}dB',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
