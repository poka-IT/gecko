import 'package:hive_flutter/hive_flutter.dart';

part 'chestData.g.dart';

@HiveType(typeId: 1)
class ChestData extends HiveObject {
  @HiveField(0)
  String dewif;

  @HiveField(2)
  String name;

  @HiveField(3)
  int defaultWallet;

  ChestData({this.dewif, this.name, this.defaultWallet});

  // representation of WalletData when debugging
  @override
  String toString() {
    return this.name;
  }
}
