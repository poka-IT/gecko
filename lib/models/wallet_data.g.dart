// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletDataAdapter extends TypeAdapter<WalletData> {
  @override
  final int typeId = 0;

  @override
  WalletData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletData(
      address: fields[0] as String,
      chest: fields[1] as int?,
      number: fields[2] as int?,
      name: fields[3] as String?,
      derivation: fields[4] as int?,
      imageDefaultPath: fields[5] as String?,
      imageCustomPath: fields[6] as String?,
      isOwned: fields[7] as bool,
      isMember: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WalletData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.chest)
      ..writeByte(2)
      ..write(obj.number)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.derivation)
      ..writeByte(5)
      ..write(obj.imageDefaultPath)
      ..writeByte(6)
      ..write(obj.imageCustomPath)
      ..writeByte(7)
      ..write(obj.isOwned)
      ..writeByte(8)
      ..write(obj.isMember);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
