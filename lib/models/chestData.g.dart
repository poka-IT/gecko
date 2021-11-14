// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chestData.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChestDataAdapter extends TypeAdapter<ChestData> {
  @override
  final int typeId = 1;

  @override
  ChestData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChestData(
      dewif: fields[0] as String,
      name: fields[2] as String,
      defaultWallet: fields[3] as int,
      imageName: fields[4] as String,
      isCesium: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChestData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dewif)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.defaultWallet)
      ..writeByte(4)
      ..write(obj.imageName)
      ..writeByte(5)
      ..write(obj.isCesium);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChestDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
