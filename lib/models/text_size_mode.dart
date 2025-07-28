// Text scaling utility class
class TextScaling {
  // Predefined scale factors with labels
  static const double minScale = 0.85;
  static const double maxScale = 1.60;
  static const double defaultScale = 1.0;

  // Preset values for slider anchors
  static const List<double> presetValues = [0.85, 1.0, 1.30, 1.60];

  // Get the closest preset value to a given scale
  static double snapToPreset(double value) {
    double closest = presetValues.first;
    double minDifference = (value - closest).abs();

    for (double preset in presetValues) {
      double difference = (value - preset).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closest = preset;
      }
    }

    return closest;
  }

  // Get label for a scale value
  static String getLabelKey(double value) {
    if (value <= 0.85) return 'textSizeSmall';
    if (value <= 1.0) return 'textSizeNormal';
    if (value <= 1.30) return 'textSizeLarge';
    return 'textSizeExtraLarge';
  }
}
