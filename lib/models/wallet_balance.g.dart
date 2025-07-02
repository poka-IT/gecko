// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletBalanceAdapter extends TypeAdapter<WalletBalance> {
  @override
  final int typeId = 10;

  @override
  WalletBalance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletBalance(
      transferableBalance: fields[0] as int,
      free: fields[1] as int,
      unclaimedUds: fields[2] as int,
      reserved: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WalletBalance obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.transferableBalance)
      ..writeByte(1)
      ..write(obj.free)
      ..writeByte(2)
      ..write(obj.unclaimedUds)
      ..writeByte(3)
      ..write(obj.reserved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletBalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
