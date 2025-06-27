import 'package:durt2/durt2.dart';
import 'package:gecko/globals.dart';

class SystemService {
  static BigInt get balanceRatio {
    final udValue = Durt.i.storage.udInfoNotifier.value;
    return (configBox.get('isUdUnit') ?? false) ? udValue.currentUd : BigInt.from(1);
  }
}
