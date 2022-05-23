import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
part 'wallet_data.g.dart';

@HiveType(typeId: 0)
class WalletData extends HiveObject {
  @HiveField(0)
  int? chest;

  @HiveField(1)
  String? address;

  @HiveField(2)
  int? number;

  @HiveField(3)
  String? name;

  @HiveField(4)
  int? derivation;

  @HiveField(5)
  String? imageName;

  @HiveField(6)
  File? imageFile;

  WalletData(
      {this.chest,
      this.address,
      this.number,
      this.name,
      this.derivation,
      this.imageName,
      this.imageFile});

  // representation of WalletData when debugging
  @override
  String toString() {
    return name!;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "$chest:$number:$name:$derivation:$imageName";
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
