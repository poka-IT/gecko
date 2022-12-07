import 'package:hive_flutter/hive_flutter.dart';
part 'wallet_data.g.dart';

@HiveType(typeId: 0)
class WalletData extends HiveObject {
  @HiveField(0)
  String address;

  @HiveField(1)
  int? chest;

  @HiveField(2)
  int? number;

  @HiveField(3)
  String? name;

  @HiveField(4)
  int? derivation;

  @HiveField(5)
  String? imageDefaultPath;

  @HiveField(6)
  String? imageCustomPath;

  @HiveField(7)
  bool isOwned;

  @HiveField(8)
  bool isMember;

  WalletData(
      {required this.address,
      this.chest,
      this.number,
      this.name,
      this.derivation,
      this.imageDefaultPath,
      this.imageCustomPath,
      this.isOwned = false,
      this.isMember = false});

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
