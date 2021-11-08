import 'package:hive_flutter/hive_flutter.dart';

part 'walletData.g.dart';

@HiveType(typeId: 0)
class WalletData extends HiveObject {
  @HiveField(0)
  int chest;

  @HiveField(1)
  int number;

  @HiveField(2)
  String name;

  @HiveField(3)
  int derivation;

  WalletData({this.chest, this.number, this.name, this.derivation});

  // representation of WalletData when debugging
  @override
  String toString() {
    return this.name;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "${this.chest}:${this.number}:${this.name}:${this.derivation}";
  }

  // returns only the id part of the ':'-separated string
  List id() {
    return [this.chest, this.number];
  }
}
