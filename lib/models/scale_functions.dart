import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

double scaleSize(double size) {
  final scale = MediaQuery.of(homeContext).size.width / 375;
  return size * scale;
}

TextStyle scaledTextStyle({
  double fontSize = 16,
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
    Key? key,
    double? width,
    double? height,
    Widget? child,
  }) : super(
          key: key,
          width: width != null ? scaleSize(width) : null,
          height: height != null ? scaleSize(height) : null,
          child: child,
        );
}
