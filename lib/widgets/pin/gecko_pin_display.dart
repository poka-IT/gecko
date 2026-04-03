import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

enum PinDisplayMode { normal, error, success }

/// Displays PIN cells as a row of rounded squares with filled dots.
///
/// When [width] is provided (typically by [GeckoPinEntry]), the cells
/// distribute evenly across that width, staying aligned with the numpad.
class GeckoPinDisplay extends StatelessWidget {
  const GeckoPinDisplay({
    super.key,
    required this.filledCount,
    required this.length,
    this.mode = PinDisplayMode.normal,
    this.width,
  });

  final int filledCount;
  final int length;
  final PinDisplayMode mode;

  /// Total width available. Cells distribute evenly within this width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cellGap = scaleSize(8);

    if (width != null) {
      // Sized mode: cells fill the given width evenly
      final cellSize = (width! - cellGap * (length - 1)) / length;
      return SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final isFilled = i < filledCount;
            final isFocused = mode == PinDisplayMode.normal && i == filledCount && filledCount < length;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : cellGap),
              child: _PinCell(isFilled: isFilled, isFocused: isFocused, mode: mode, size: cellSize),
            );
          }),
        ),
      );
    }

    // Fallback: intrinsic sizing
    final cellSize = scaleSize(44);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final isFilled = i < filledCount;
        final isFocused = mode == PinDisplayMode.normal && i == filledCount && filledCount < length;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : cellGap),
          child: _PinCell(isFilled: isFilled, isFocused: isFocused, mode: mode, size: cellSize),
        );
      }),
    );
  }
}

class _PinCell extends StatelessWidget {
  const _PinCell({required this.isFilled, required this.isFocused, required this.mode, required this.size});

  final bool isFilled;
  final bool isFocused;
  final PinDisplayMode mode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor = _borderColor(context);
    final fillColor = context.colorScheme.surfaceContainer;
    final radius = (size * 0.24).clamp(8.0, 14.0);
    final dotFontSize = (size * 0.48).clamp(14.0, 28.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: AnimatedScale(
          scale: isFilled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Text(
            '\u25CF',
            style: scaledTextStyle(fontSize: dotFontSize, fontWeight: FontWeight.w600, color: _dotColor(context)),
          ),
        ),
      ),
    );
  }

  Color _borderColor(BuildContext context) {
    if (mode == PinDisplayMode.error) return context.geckoColors.danger;
    if (mode == PinDisplayMode.success) return context.geckoColors.success;
    if (isFilled) return const Color(0xFFA4B600);
    if (isFocused) return context.colorScheme.primary;
    return Colors.grey[300]!;
  }

  Color _dotColor(BuildContext context) {
    if (mode == PinDisplayMode.error) return context.geckoColors.danger;
    if (mode == PinDisplayMode.success) return context.geckoColors.success;
    return context.colorScheme.onSurface;
  }
}
