// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_header_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletHeaderDataAdapter extends TypeAdapter<WalletHeaderData> {
  @override
  final int typeId = 6;

  @override
  WalletHeaderData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return WalletHeaderData(
      hasIdentity: fields[0] as bool,
      isOwner: fields[1] as bool,
      walletName: fields[2] as String?,
      balance: fields[3] as BigInt,
      certCount: fields[4] as CertificationData,
    );
  }

  @override
  void write(BinaryWriter writer, WalletHeaderData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.hasIdentity)
      ..writeByte(1)
      ..write(obj.isOwner)
      ..writeByte(2)
      ..write(obj.walletName)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.certCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletHeaderDataAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
