import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final Widget? child;
  final double borderRadius;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 55.0,
    this.child,
    this.borderRadius = 16.0,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return ScaledSizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: context.colorScheme.primary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
        child:
            child ??
            Text(
              label,
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.white),
            ),
      ),
    );
  }
}
