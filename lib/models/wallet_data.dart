import 'package:hive_flutter/hive_flutter.dart';
part 'wallet_data.g.dart';

@HiveType(typeId: 0)
class WalletData extends HiveObject {
  @HiveField(0)
  int? version;

  @HiveField(1)
  int? chest;

  @HiveField(2)
  String? address;

  @HiveField(3)
  int? number;

  @HiveField(4)
  String? name;

  @HiveField(5)
  int? derivation;

  @HiveField(6)
  String? imageDefaultPath;

  @HiveField(7)
  String? imageCustomPath;

  WalletData(
      {this.version,
      this.chest,
      this.address,
      this.number,
      this.name,
      this.derivation,
      this.imageDefaultPath,
      this.imageCustomPath});

  // representation of WalletData when debugging
  @override
  String toString() {
    return name!;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "$chest:$number:$name:$derivation:$imageDefaultPath";
  }

  // returns only the id part of the ':'-separated string
  List<int?> id() {
    return [chest, number];
  }
}

class NewWallet {
  final String address;
  final String password;

  NewWallet._(this.address, this.password);
}
