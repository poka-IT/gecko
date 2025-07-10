import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';

class SystemService {
  static BigInt balanceRatioFromContainer(ProviderContainer container) {
    final udValue = container.read(storageServiceProvider).udInfoNotifier.value;
    return (configBox.get('isUdUnit') ?? false) ? udValue.currentUd : BigInt.from(1);
  }

  // Getter pour compatibilité descendante
  static BigInt get balanceRatio {
    final container = ProviderContainer();
    try {
      final udValue = container.read(storageServiceProvider).udInfoNotifier.value;
      return (configBox.get('isUdUnit') ?? false) ? udValue.currentUd : BigInt.from(1);
    } finally {
      container.dispose();
    }
  }
}
