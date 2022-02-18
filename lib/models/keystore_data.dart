import 'package:hive_flutter/hive_flutter.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
part 'keystore_data.g.dart';

@HiveType(typeId: 4)
class KeyStoreData extends HiveObject {
  @HiveField(0)
  KeyPairData? keystore;

  KeyStoreData({this.keystore});

  @override
  String toString() {
    return keystore!.address!;
  }

  String name() {
    return keystore!.name!;
  }

  String pubkey() {
    return keystore!.pubKey!;
  }

  Map indexInfo() {
    return keystore!.indexInfo!;
  }
}
