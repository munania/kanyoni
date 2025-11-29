import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerController controller = Get.find<PlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Equalizer'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Glassmorphic Toggle Switch
          Obx(() => _GlassmorphicToggle(
                value: controller.equalizerEnabled.value,
                enabled: controller.isEqualizerInitialized.value,
                onChanged: (value) {
                  controller.toggleEqualizer(value);
                },
                isDarkMode: isDarkMode,
              )),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ]
                    : [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (!controller.isEqualizerInitialized.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.music_filter,
                          size: 64,
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Equalizer not available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Play a song to enable equalizer',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 20),

                    // Glassmorphic Preset Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _GlassmorphicDropdown(
                        controller: controller,
                        isDarkMode: isDarkMode,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Equalizer Bands
                    Expanded(
                      child: _EqualizerBands(
                        controller: controller,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Glassmorphic Toggle Switch
class _GlassmorphicToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool isDarkMode;

  const _GlassmorphicToggle({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Transform.scale(
            scale: 1.3,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Theme.of(context).primaryColor,
              activeTrackColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// Glassmorphic Dropdown
class _GlassmorphicDropdown extends StatefulWidget {
  final PlayerController controller;
  final bool isDarkMode;

  const _GlassmorphicDropdown({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_GlassmorphicDropdown> createState() => _GlassmorphicDropdownState();
}

class _GlassmorphicDropdownState extends State<_GlassmorphicDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(
              () => DropdownButton<String>(
                isExpanded: true,
                value: widget.controller.currentPreset.value.isEmpty
                    ? null
                    : widget.controller.currentPreset.value,
                hint: Row(
                  children: [
                    Icon(
                      Iconsax.music_filter,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Text('Select Preset'),
                  ],
                ),
                icon: RotationTransition(
                  turns:
                      Tween(begin: 0.0, end: 0.5).animate(_rotationController),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                dropdownColor:
                    widget.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                items: widget.controller.equalizerPresets.map((String preset) {
                  return DropdownMenuItem<String>(
                    value: preset,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          Icon(
                            _getPresetIcon(preset),
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            preset,
                            style: TextStyle(
                              fontWeight: preset ==
                                      widget.controller.currentPreset.value
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.controller.setPreset(newValue);
                  }
                },
                onTap: () {
                  _rotationController.forward();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPresetIcon(String preset) {
    switch (preset) {
      case 'Flat':
        return Iconsax.minus;
      case 'Bass Boost':
        return Iconsax.sound;
      case 'Treble Boost':
        return Iconsax.volume_high;
      default:
        return Iconsax.setting_2;
    }
  }
}

// Equalizer Bands
class _EqualizerBands extends StatelessWidget {
  final PlayerController controller;
  final bool isDarkMode;

  const _EqualizerBands({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Obx(() {
            final bandCount = controller.equalizerBands.length;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(bandCount, (index) {
                final freq = controller.equalizerCenterFreqs[index];
                final level = controller.equalizerBands[index];
                final min = controller.minBandLevel.value;
                final max = controller.maxBandLevel.value;

                return Expanded(
                  child: _EqualizerBand(
                    frequency: freq,
                    level: level,
                    min: min,
                    max: max,
                    enabled: controller.equalizerEnabled.value,
                    isDarkMode: isDarkMode,
                    onChanged: (value) {
                      controller.setBandLevel(index, value);
                    },
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

// Individual Equalizer Band
class _EqualizerBand extends StatefulWidget {
  final int frequency;
  final int level;
  final double min;
  final double max;
  final bool enabled;
  final bool isDarkMode;
  final ValueChanged<double> onChanged;

  const _EqualizerBand({
    required this.frequency,
    required this.level,
    required this.min,
    required this.max,
    required this.enabled,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  State<_EqualizerBand> createState() => _EqualizerBandState();
}

class _EqualizerBandState extends State<_EqualizerBand> {
  bool _isActive = false;

  String _formatFrequency(int frequency) {
    if (frequency >= 1000) {
      final kHz = frequency / 1000;
      // Format to remove unnecessary decimals
      if (kHz == kHz.toInt()) {
        return '${kHz.toInt()}k';
      } else {
        return '${kHz.toStringAsFixed(1)}k';
      }
    } else {
      return '${frequency}Hz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Frequency Label
          Text(
            _formatFrequency(widget.frequency),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: _isActive
                      ? Theme.of(context).primaryColor
                      : (widget.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600]),
                ),
          ),
          const SizedBox(height: 12),

          // Slider
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isActive
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                      elevation: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    thumbColor: Theme.of(context).primaryColor,
                    overlayColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: widget.level.toDouble(),
                    min: widget.min,
                    max: widget.max,
                    divisions: null,
                    // Allow smooth dragging
                    onChanged: widget.enabled
                        ? (value) {
                            setState(() => _isActive = true);
                            widget.onChanged(value);
                          }
                        : null,
                    onChangeStart: (_) {
                      setState(() => _isActive = true);
                    },
                    onChangeEnd: (_) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          setState(() => _isActive = false);
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Level Display
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isActive
                  ? Theme.of(context).primaryColor
                  : (widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.level > 0 ? '+' : ''}${widget.level}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: _isActive
                        ? Colors.white
                        : (widget.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700]),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
