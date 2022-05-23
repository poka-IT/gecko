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
      chest: fields[0] as int?,
      address: fields[1] as String?,
      number: fields[2] as int?,
      name: fields[3] as String?,
      derivation: fields[4] as int?,
      imageName: fields[5] as String?,
      imageFile: fields[6] as File?,
    );
  }

  @override
  void write(BinaryWriter writer, WalletData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.chest)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.number)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.derivation)
      ..writeByte(5)
      ..write(obj.imageName)
      ..writeByte(6)
      ..write(obj.imageFile);
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
