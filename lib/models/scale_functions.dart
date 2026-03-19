import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';

double scaleSize(double size) {
  // Use the platform's primary view to get screen dimensions without requiring a BuildContext.
  // This is equivalent to View.of(context) in a single-window app.
  final view = PlatformDispatcher.instance.views.first;
  final viewSize = view.physicalSize / view.devicePixelRatio;
  // Cap the reference width to prevent oversized elements on desktop/wide screens
  final effectiveWidth = viewSize.width.clamp(0.0, 500.0);
  final scale = effectiveWidth / 375;
  // On desktop (>= 900px), cap scale at 1.0 to keep elements at base size
  final maxScale = viewSize.width >= 900 ? 1.0 : 1.3;
  return size * scale.clamp(0.8, maxScale);
}

TextStyle scaledTextStyle({
  double fontSize = 14,
  double? height,
  FontStyle? fontStyle,
  FontWeight? fontWeight,
  Color? color,
  List<Shadow>? shadows,
  String? fontFamily,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: scaleSize(fontSize),
    height: height,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    shadows: shadows,
    fontFamily: fontFamily,
    letterSpacing: letterSpacing,
  );
}

class ScaledSizedBox extends SizedBox {
  ScaledSizedBox({super.key, double? width, double? height, super.child})
    : super(width: width != null ? scaleSize(width) : null, height: height != null ? scaleSize(height) : null);
}
