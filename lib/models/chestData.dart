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

  @HiveField(4)
  String imageName;

  ChestData({this.dewif, this.name, this.defaultWallet, this.imageName});

  @override
  String toString() {
    return this.name;
  }
}
