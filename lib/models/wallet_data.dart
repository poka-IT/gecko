import 'package:hive_flutter/hive_flutter.dart';

part 'wallet_data.g.dart';

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

  @HiveField(4)
  String imageName;

  WalletData(
      {this.chest, this.number, this.name, this.derivation, this.imageName});

  // representation of WalletData when debugging
  @override
  String toString() {
    return name;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "$chest:$number:$name:$derivation:$imageName";
  }

  // returns only the id part of the ':'-separated string
  List id() {
    return [chest, number];
  }
}
