import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

part 'chest_data.g.dart';

@HiveType(typeId: 1)
class ChestData extends HiveObject {
  @HiveField(0)
  String? dewif;

  @HiveField(2)
  String? name;

  @HiveField(3)
  int? defaultWallet;

  @HiveField(4)
  String? imageName;

  @HiveField(5)
  File? imageFile;

  @HiveField(6)
  bool? isCesium;

  ChestData({
    this.dewif,
    this.name,
    this.defaultWallet,
    this.imageName,
    this.imageFile,
    this.isCesium,
  });

  @override
  String toString() {
    return name!;
  }
}
