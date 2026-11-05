import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'eq_math.dart';
import 'equalizer_controller.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

enum _MenuAction { save, delete, reset }

class _EqualizerScreenState extends State<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final EqualizerController _eq = Get.find<EqualizerController>();

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

  Future<void> _onMenu(_MenuAction action) async {
    switch (action) {
      case _MenuAction.save:
        await _askPresetName();
        break;
      case _MenuAction.delete:
        _eq.deleteCustomPreset(_eq.currentPreset.value);
        break;
      case _MenuAction.reset:
        await _eq.reset();
        break;
    }
  }

  Future<void> _askPresetName() async {
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Save preset'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Preset name',
              errorText: error,
            ),
            onSubmitted: (_) {
              final result = _eq.saveCustomPreset(controller.text);
              if (result == null) {
                Navigator.pop(dialogContext);
              } else {
                setDialogState(() => error = result);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final result = _eq.saveCustomPreset(controller.text);
                if (result == null) {
                  Navigator.pop(dialogContext);
                } else {
                  setDialogState(() => error = result);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Obx(
            () => _GlassmorphicToggle(
              value: _eq.enabled.value,
              enabled: _eq.isReady.value,
              onChanged: _eq.setEnabled,
              isDarkMode: isDarkMode,
            ),
          ),
          Obx(
            () => PopupMenuButton<_MenuAction>(
              enabled: _eq.isReady.value,
              onSelected: _onMenu,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _MenuAction.save,
                  child: Text('Save as preset...'),
                ),
                if (_eq.isCustomPreset)
                  const PopupMenuItem(
                    value: _MenuAction.delete,
                    child: Text('Delete this preset'),
                  ),
                const PopupMenuItem(
                  value: _MenuAction.reset,
                  child: Text('Reset to flat'),
                ),
              ],
            ),
          ),
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

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (!_eq.isReady.value) {
                  return _buildUnavailable(context, isDarkMode);
                }
                return _buildContent(context, isDarkMode);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.music_filter,
            size: 64,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Equalizer not available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Play a song to enable the equalizer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDarkMode) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Preset selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _PresetDropdown(controller: _eq, isDarkMode: isDarkMode),
        ),

        // Band count (only when the engine supports it)
        Obx(() {
          if (!_eq.canChangeBands.value) return const SizedBox(height: 12);
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final n in EqBands.supportedCounts)
                    ButtonSegment<int>(value: n, label: Text('$n bands')),
                ],
                selected: {_eq.bandCount.value},
                onSelectionChanged: (selection) =>
                    _eq.setBandCount(selection.first),
              ),
            ),
          );
        }),

        // Live response curve
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _GlassCard(
            isDarkMode: isDarkMode,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SizedBox(
              height: 96,
              width: double.infinity,
              child: Obx(
                () => CustomPaint(
                  painter: _CurvePainter(
                    freqs: _eq.freqs.toList(),
                    gains: _eq.gains.toList(),
                    minDb: _eq.minDb.value,
                    maxDb: _eq.maxDb.value,
                    color: Theme.of(context).primaryColor,
                    dimmed: !_eq.enabled.value,
                    gridColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.1),
                    labelColor: isDarkMode
                        ? Colors.grey[500]!
                        : Colors.grey[600]!,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Preamp
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _PreampRow(controller: _eq, isDarkMode: isDarkMode),
        ),

        const SizedBox(height: 8),

        // Bands
        Expanded(
          child: _EqualizerBands(controller: _eq, isDarkMode: isDarkMode),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Obx(
            () => Text(
              '${_eq.engineName.value}  -  0.1 dB steps  -  tap a value to fine-tune',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Shared glass container
// -----------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    required this.isDarkMode,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Toggle
// -----------------------------------------------------------------------------

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
          padding: const EdgeInsets.all(2.0),
          child: Transform.scale(
            scale: 1.1,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Theme.of(context).primaryColor,
              activeTrackColor: Theme.of(context).primaryColor
                  .withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Preset dropdown
// -----------------------------------------------------------------------------

class _PresetDropdown extends StatelessWidget {
  final EqualizerController controller;
  final bool isDarkMode;

  const _PresetDropdown({required this.controller, required this.isDarkMode});

  IconData _iconFor(String preset) {
    if (controller.customPresets.containsKey(preset)) {
      return Icons.bookmark_outline;
    }
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(() {
              final names = controller.presetNames;
              final current = controller.currentPreset.value;
              return DropdownButton<String>(
                isExpanded: true,
                value: names.contains(current) ? current : null,
                hint: const Text('Select Preset'),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: [
                  for (final preset in names)
                    DropdownMenuItem<String>(
                      value: preset,
                      child: Row(
                        children: [
                          Icon(
                            _iconFor(preset),
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            preset,
                            style: TextStyle(
                              fontWeight: preset == current
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) controller.applyPreset(value);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Preamp
// -----------------------------------------------------------------------------

class _PreampRow extends StatelessWidget {
  final EqualizerController controller;
  final bool isDarkMode;

  const _PreampRow({required this.controller, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Obx(() {
        final supported = controller.supportsPreamp.value;
        return Row(
          children: [
            Text(
              'Preamp',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Slider(
                value: controller.preamp.value,
                min: -EqualizerController.maxPreampDb,
                max: EqualizerController.maxPreampDb,
                onChanged: supported ? controller.setPreamp : null,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${EqMath.formatDb(controller.preamp.value)} dB',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            TextButton(
              onPressed: supported ? controller.autoPreamp : null,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Auto'),
            ),
          ],
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// Response curve
// -----------------------------------------------------------------------------

class _CurvePainter extends CustomPainter {
  final List<double> freqs;
  final List<double> gains;
  final double minDb;
  final double maxDb;
  final Color color;
  final bool dimmed;
  final Color gridColor;
  final Color labelColor;

  _CurvePainter({
    required this.freqs,
    required this.gains,
    required this.minDb,
    required this.maxDb,
    required this.color,
    required this.dimmed,
    required this.gridColor,
    required this.labelColor,
  });

  static const double _minHz = 20;
  static const double _maxHz = 20000;
  static const double _labelHeight = 14;

  double _x(double hz, double width) {
    final t =
        (math.log(hz) - math.log(_minHz)) /
        (math.log(_maxHz) - math.log(_minHz));
    return t * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (freqs.isEmpty || freqs.length != gains.length) return;

    final plotHeight = size.height - _labelHeight;
    final range = maxDb - minDb;
    double y(double db) => plotHeight * (1 - (db - minDb) / range);

    // Grid: the 0 dB line (stronger) and the half-way lines.
    final zeroLine = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final halfLine = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), zeroLine);
    canvas.drawLine(
      Offset(0, y(maxDb / 2)),
      Offset(size.width, y(maxDb / 2)),
      halfLine,
    );
    canvas.drawLine(
      Offset(0, y(minDb / 2)),
      Offset(size.width, y(minDb / 2)),
      halfLine,
    );

    // Frequency labels.
    for (final hz in const [100.0, 1000.0, 10000.0]) {
      final painter = TextPainter(
        text: TextSpan(
          text: EqMath.formatFrequency(hz),
          style: TextStyle(color: labelColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(_x(hz, size.width) - painter.width / 2, size.height - 12),
      );
    }

    // The curve itself, sampled on a log frequency axis.
    const samples = 160;
    final line = Path();
    final fill = Path();
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final hz = _minHz * math.pow(_maxHz / _minHz, t).toDouble();
      final db = EqMath.responseDb(
        hz,
        freqs,
        gains,
      ).clamp(minDb, maxDb).toDouble();
      final px = t * size.width;
      final py = y(db);
      if (i == 0) {
        line.moveTo(px, py);
        fill.moveTo(px, y(0));
        fill.lineTo(px, py);
      } else {
        line.lineTo(px, py);
        fill.lineTo(px, py);
      }
    }
    fill.lineTo(size.width, y(0));
    fill.close();

    final base = dimmed ? color.withValues(alpha: 0.35) : color;
    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = base.withValues(alpha: 0.15),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = base,
    );

    // A dot on every band so the user sees where the sliders sit.
    final dot = Paint()..color = base;
    for (var i = 0; i < freqs.length; i++) {
      canvas.drawCircle(
        Offset(
          _x(freqs[i], size.width),
          y(gains[i].clamp(minDb, maxDb).toDouble()),
        ),
        freqs.length > 15 ? 1.6 : 2.6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.dimmed != dimmed ||
      old.color != color ||
      old.minDb != minDb ||
      old.maxDb != maxDb ||
      !listEquals(old.gains, gains) ||
      !listEquals(old.freqs, freqs);
}

// -----------------------------------------------------------------------------
// Bands
// -----------------------------------------------------------------------------

class _EqualizerBands extends StatelessWidget {
  final EqualizerController controller;
  final bool isDarkMode;

  const _EqualizerBands({required this.controller, required this.isDarkMode});

  /// Narrowest a band column may get; with 31 bands the row scrolls sideways.
  static const double _minColumnWidth = 46;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _GlassCard(
        isDarkMode: isDarkMode,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Obx(() {
              final count = controller.freqs.length;
              if (count == 0) return const SizedBox.shrink();
              final columnWidth = math.max(
                _minColumnWidth,
                constraints.maxWidth / count,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: columnWidth * count,
                  child: Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        SizedBox(
                          width: columnWidth,
                          child: _EqualizerBand(
                            index: i,
                            controller: controller,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class _EqualizerBand extends StatefulWidget {
  final int index;
  final EqualizerController controller;
  final bool isDarkMode;

  const _EqualizerBand({
    required this.index,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<_EqualizerBand> createState() => _EqualizerBandState();
}

class _EqualizerBandState extends State<_EqualizerBand> {
  bool _isActive = false;

  EqualizerController get _c => widget.controller;

  Future<void> _openFineTune() {
    return showDialog<void>(
      context: context,
      builder: (_) => _FineTuneDialog(controller: _c, index: widget.index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = widget.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Obx(() {
        // Reading these inside Obx keeps the band in sync with presets and
        // with the fine-tune dialog.
        if (widget.index >= _c.gains.length) return const SizedBox.shrink();
        final freq = _c.freqs[widget.index];
        final level = _c.gains[widget.index];
        final min = _c.minDb.value;
        final max = _c.maxDb.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              EqMath.formatFrequency(freq),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: _isActive
                    ? primary
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _isActive
                      ? primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9,
                        elevation: 3,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: primary,
                      inactiveTrackColor: primary.withValues(alpha: 0.2),
                      thumbColor: primary,
                      overlayColor: primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: level.clamp(min, max).toDouble(),
                      min: min,
                      max: max,
                      // No divisions: the slider is continuous, and the
                      // controller rounds to 0.1 dB.
                      onChanged: (value) {
                        setState(() => _isActive = true);
                        _c.setGain(widget.index, value);
                      },
                      onChangeStart: (_) => setState(() => _isActive = true),
                      onChangeEnd: (_) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) setState(() => _isActive = false);
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openFineTune,
              onLongPress: () => _c.setGain(widget.index, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: _isActive
                      ? primary
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  EqMath.formatDb(level),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: _isActive
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// Fine tune dialog
// -----------------------------------------------------------------------------

class _FineTuneDialog extends StatefulWidget {
  final EqualizerController controller;
  final int index;

  const _FineTuneDialog({required this.controller, required this.index});

  @override
  State<_FineTuneDialog> createState() => _FineTuneDialogState();
}

class _FineTuneDialogState extends State<_FineTuneDialog> {
  late final TextEditingController _text;

  EqualizerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: _c.gains[widget.index].toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _setAndShow(double value) {
    _c.setGain(widget.index, value);
    _text.text = _c.gains[widget.index].toStringAsFixed(1);
  }

  void _applyTyped() {
    final parsed = double.tryParse(_text.text.trim().replaceAll(',', '.'));
    if (parsed != null) {
      _setAndShow(parsed);
    } else {
      _text.text = _c.gains[widget.index].toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final freq = EqMath.formatFrequency(_c.freqs[widget.index]);

    return AlertDialog(
      title: Text('$freq Hz'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: '-0.1 dB',
            icon: const Icon(Icons.remove),
            onPressed: () {
              _c.nudge(widget.index, -0.1);
              _text.text = _c.gains[widget.index].toStringAsFixed(1);
            },
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: TextField(
              controller: _text,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(suffixText: 'dB'),
              onSubmitted: (_) => _applyTyped(),
              onTapOutside: (_) => _applyTyped(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: '+0.1 dB',
            icon: const Icon(Icons.add),
            onPressed: () {
              _c.nudge(widget.index, 0.1);
              _text.text = _c.gains[widget.index].toStringAsFixed(1);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => _setAndShow(0), child: const Text('Reset')),
        FilledButton(
          onPressed: () {
            _applyTyped();
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
