import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/profile_view.dart' show buttonSize;

/// A reusable action button for profile views with icon and label.
/// The entire button (icon + label) is clickable.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.label,
    this.sublabel,
    this.backgroundColor,
    this.labelStyle,
    this.sublabelStyle,
    this.buttonKey,
  });

  /// Callback when the button is tapped
  final VoidCallback onTap;

  /// The content inside the circular button (icon, image, etc.)
  final Widget child;

  /// The main label text below the button
  final String label;

  /// Optional secondary label (e.g., estimated time)
  final String? sublabel;

  /// Background color of the circular button
  final Color? backgroundColor;

  /// Custom style for the main label
  final TextStyle? labelStyle;

  /// Custom style for the sublabel
  final TextStyle? sublabelStyle;

  /// Key for the button (for testing)
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final defaultLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: scaleSize(buttonSize),
            width: scaleSize(buttonSize),
            decoration: BoxDecoration(
              color: backgroundColor ?? Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: buttonKey,
                borderRadius: BorderRadius.circular(buttonSize / 2),
                onTap: onTap,
                child: child,
              ),
            ),
          ),
          ScaledSizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: labelStyle ?? defaultLabelStyle),
          if (sublabel != null)
            Text(
              sublabel!,
              textAlign: TextAlign.center,
              style: sublabelStyle ?? scaledTextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }
}
