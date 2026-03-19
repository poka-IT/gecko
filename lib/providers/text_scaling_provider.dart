import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/text_size_mode.dart';
import 'package:gecko/services/config_service.dart';

// Provider for text scaling value
class TextScalingNotifier extends Notifier<double> {
  @override
  double build() => _getInitialScale();

  double _getInitialScale() {
    final savedScale = ref.read(configServiceProvider).textScaleValue;
    if (savedScale != null) {
      return savedScale;
    }
    return TextScaling.defaultScale;
  }

  void setTextScale(double scale) {
    state = scale;
    ref.read(configServiceProvider).textScaleValue = scale;
  }
}

// Provider instance
final textScalingProvider = NotifierProvider<TextScalingNotifier, double>(TextScalingNotifier.new);
