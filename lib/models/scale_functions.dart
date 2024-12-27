import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

double scaleSize(double size) {
  final scale = MediaQuery.of(homeContext).size.width / 375;
  return size * scale.clamp(0.8, 1.3);
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
  ScaledSizedBox({
    super.key,
    double? width,
    double? height,
    super.child,
  }) : super(
          width: width != null ? scaleSize(width) : null,
          height: height != null ? scaleSize(height) : null,
        );
}
