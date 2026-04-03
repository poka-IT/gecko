import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

/// A 3x4 virtual numpad for PIN entry.
///
/// Standard telephone layout:
/// ```
/// [1] [2] [3]
/// [4] [5] [6]
/// [7] [8] [9]
/// [?] [0] [⌫]
/// ```
///
/// [buttonSize] controls the diameter of each button.
/// [totalWidth] is the overall width of the numpad (used to space buttons).
/// Both are typically computed by [GeckoPinEntry] to fit the screen.
class GeckoNumpad extends StatelessWidget {
  const GeckoNumpad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onDeleteLongPressed,
    this.bottomLeftWidget,
    this.enabled = true,
    required this.buttonSize,
    required this.totalWidth,
    this.rowGap,
  });

  final ValueChanged<int> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onDeleteLongPressed;
  final Widget? bottomLeftWidget;
  final bool enabled;
  final double buttonSize;
  final double totalWidth;
  final double? rowGap;

  @override
  Widget build(BuildContext context) {
    final gap = rowGap ?? scaleSize(6);

    return SizedBox(
      width: totalWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, [1, 2, 3]),
          SizedBox(height: gap),
          _buildRow(context, [4, 5, 6]),
          SizedBox(height: gap),
          _buildRow(context, [7, 8, 9]),
          SizedBox(height: gap),
          _buildBottomRow(context),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits
          .map(
            (d) => _NumpadButton(
              label: d.toString(),
              size: buttonSize,
              onPressed: enabled ? () => _handleDigitPress(d) : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: buttonSize, height: buttonSize, child: bottomLeftWidget),
        _NumpadButton(label: '0', size: buttonSize, onPressed: enabled ? () => _handleDigitPress(0) : null),
        _NumpadButton(
          icon: Icons.backspace_outlined,
          size: buttonSize,
          onPressed: enabled ? onDeletePressed : null,
          onLongPress: enabled ? onDeleteLongPressed : null,
        ),
      ],
    );
  }

  void _handleDigitPress(int digit) {
    HapticFeedback.lightImpact();
    onDigitPressed(digit);
  }
}

class _NumpadButton extends StatelessWidget {
  const _NumpadButton({this.label, this.icon, required this.size, this.onPressed, this.onLongPress});

  final String? label;
  final IconData? icon;
  final double size;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final buttonColor = _enabled
        ? context.colorScheme.surfaceContainerHighest
        : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final contentColor = _enabled
        ? context.colorScheme.onSurface
        : context.colorScheme.onSurface.withValues(alpha: 0.3);

    final fontSize = (size * 0.38).clamp(16.0, 32.0);
    final iconSize = (size * 0.33).clamp(14.0, 26.0);

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: buttonColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          customBorder: const CircleBorder(),
          child: Center(
            child: icon != null
                ? Icon(icon, size: iconSize, color: contentColor)
                : Text(
                    label ?? '',
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: contentColor),
                  ),
          ),
        ),
      ),
    );
  }
}
