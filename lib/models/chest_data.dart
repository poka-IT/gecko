import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
part 'chest_data.g.dart';

@HiveType(typeId: 1)
class ChestData extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  int? defaultWallet;

  @HiveField(2)
  String? imageName;

  @HiveField(3)
  File? imageFile;

  @HiveField(4)
  int? memberWallet;

  ChestData({
    this.name,
    this.defaultWallet,
    this.imageName,
    this.imageFile,
    this.memberWallet,
  });

  @override
  String toString() {
    return name!;
  }
}
