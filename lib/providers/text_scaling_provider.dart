import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/text_size_mode.dart';

// Provider for text scaling value
class TextScalingNotifier extends Notifier<double> {
  @override
  double build() => _getInitialScale();

  static double _getInitialScale() {
    final savedScale = configBox.get('textScaleValue');
    if (savedScale != null && savedScale is double) {
      return savedScale;
    }
    return TextScaling.defaultScale;
  }

  void setTextScale(double scale) {
    state = scale;
    configBox.put('textScaleValue', scale);
  }
}

// Provider instance
final textScalingProvider = NotifierProvider<TextScalingNotifier, double>(TextScalingNotifier.new);
