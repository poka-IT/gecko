import 'package:hive_flutter/hive_flutter.dart';

part 'wallet_header_data.g.dart';

class BigIntAdapter extends TypeAdapter<BigInt> {
  @override
  final typeId = 7; // Make sure this ID is unique

  @override
  BigInt read(BinaryReader reader) {
    return BigInt.parse(reader.readString());
  }

  @override
  void write(BinaryWriter writer, BigInt obj) {
    writer.writeString(obj.toString());
  }
}

@HiveType(typeId: 6)
class WalletHeaderData {
  @HiveField(0)
  final bool hasIdentity;

  @HiveField(1)
  final bool isOwner;

  @HiveField(2)
  final String? walletName;

  @HiveField(3)
  final BigInt balance;

  @HiveField(4)
  final int certsReceived;

  @HiveField(5)
  final int certsSent;

  WalletHeaderData({
    required this.hasIdentity,
    required this.isOwner,
    this.walletName,
    required this.balance,
    required this.certsReceived,
    required this.certsSent,
  });

  // Pour comparer si les données ont changé
  bool equals(WalletHeaderData other) {
    if (certsReceived == 0 && certsSent == 0) {
      return hasIdentity == other.hasIdentity &&
          isOwner == other.isOwner &&
          walletName == other.walletName &&
          balance == other.balance;
    }
    return hasIdentity == other.hasIdentity &&
        isOwner == other.isOwner &&
        walletName == other.walletName &&
        balance == other.balance &&
        certsReceived == other.certsReceived &&
        certsSent == other.certsSent;
  }
}
