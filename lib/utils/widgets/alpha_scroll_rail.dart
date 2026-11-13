import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanyoni/utils/helpers/alpha_index.dart';

/// A vertical A–Z strip: tap or drag along it to jump through a long list.
///
/// It only reports the letter (already resolved to one that exists in the
/// list); the screen decides how to scroll. Put it in a `Stack` over the list,
/// e.g. `Positioned(right: 0, top: 8, bottom: 8, width: 28, child: ...)`.
class AlphaScrollRail extends StatefulWidget {
  /// The letters ('#', 'A'..'Z') that have at least one item.
  final Set<String> available;

  /// Called whenever the finger moves onto a different letter.
  final ValueChanged<String> onSelect;

  const AlphaScrollRail({
    super.key,
    required this.available,
    required this.onSelect,
  });

  @override
  State<AlphaScrollRail> createState() => _AlphaScrollRailState();
}

class _AlphaScrollRailState extends State<AlphaScrollRail> {
  String? _active;

  void _handle(double dy, double height) {
    if (height <= 0) return;
    final tapped = AlphaIndex.letterAtFraction(dy / height);
    final resolved = AlphaIndex.resolve(tapped, widget.available);
    if (resolved == null || resolved == _active) return;
    HapticFeedback.selectionClick();
    setState(() => _active = resolved);
    widget.onSelect(resolved);
  }

  void _release() {
    if (_active != null) setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDarkMode = theme.brightness == Brightness.dark;
    final letters = AlphaIndex.letters;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final slot = height / letters.length;
        // Keep the glyphs inside their slot on short screens.
        final fontSize = (slot * 0.78).clamp(6.0, 11.0).toDouble();

        return Semantics(
          label: 'A to Z index',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handle(d.localPosition.dy, height),
            onTapUp: (_) => _release(),
            onTapCancel: _release,
            onVerticalDragStart: (d) => _handle(d.localPosition.dy, height),
            onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, height),
            onVerticalDragEnd: (_) => _release(),
            onVerticalDragCancel: _release,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The strip
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black)
                          .withValues(alpha: _active == null ? 0.05 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        for (final letter in letters)
                          Expanded(
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  height: 1,
                                  fontWeight: letter == _active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: letter == _active
                                      ? primary
                                      : (isDarkMode
                                                ? Colors.white
                                                : Colors.black)
                                            .withValues(
                                              alpha:
                                                  widget.available.contains(
                                                    letter,
                                                  )
                                                  ? 0.75
                                                  : 0.22,
                                            ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // The bubble that follows the finger
                if (_active != null)
                  Positioned(
                    right: constraints.maxWidth + 8,
                    top: ((letters.indexOf(_active!) + 0.5) * slot - 26)
                        .clamp(0.0, height - 52)
                        .toDouble(),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        _active!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
