import 'package:flutter/material.dart';

class FlowerPowerColors {
  static Color getFlowerPowerColor(double value, {double offset = 0.0}) {
    double minHue = 35; // yellow
    double maxHue = 205; // blue
    double range = maxHue - minHue;

    double progress = (value + offset) % 1.0;
    progress = progress <= 0.5 ? progress : ((0.5 - progress) % 0.5);

    double hue = minHue + 2 * progress * range;

    return HSVColor.fromAHSV(1.0, hue, 0.45, 0.9).toColor();
  }
}
