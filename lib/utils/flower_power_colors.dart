import 'package:flutter/material.dart';

class FlowerPowerColors {
  static Color getFlowerPowerColor(double value, {double offset = 0.0}) {
    // Create smooth flower power color transitions with soft, pastel tones
    // Avoid pink/magenta range (300-340 degrees) by mapping to other colors
    double hue = ((value + offset) * 360) % 360;

    // Skip pink/magenta range (300-340 degrees)
    if (hue >= 300 && hue <= 340) {
      // Map pink range to green/yellow range (60-120 degrees)
      hue = 60 + ((hue - 300) / 40) * 60;
    }

    return HSVColor.fromAHSV(1.0, hue, 0.45, 0.9).toColor();
  }
}
