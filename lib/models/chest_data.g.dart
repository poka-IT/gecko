// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chest_data.dart';

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
      name: fields[0] as String?,
      defaultWallet: fields[1] as int?,
      imageName: fields[2] as String?,
      imageFile: fields[3] as File?,
      memberWallet: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ChestData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.defaultWallet)
      ..writeByte(2)
      ..write(obj.imageName)
      ..writeByte(3)
      ..write(obj.imageFile)
      ..writeByte(4)
      ..write(obj.memberWallet);
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
