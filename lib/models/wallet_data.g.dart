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
      version: fields[1] as int?,
      chest: fields[2] as int?,
      number: fields[3] as int?,
      name: fields[4] as String?,
      derivation: fields[5] as int?,
      imageDefaultPath: fields[6] as String?,
      imageCustomPath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WalletData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.version)
      ..writeByte(2)
      ..write(obj.chest)
      ..writeByte(3)
      ..write(obj.number)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.derivation)
      ..writeByte(6)
      ..write(obj.imageDefaultPath)
      ..writeByte(7)
      ..write(obj.imageCustomPath);
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
