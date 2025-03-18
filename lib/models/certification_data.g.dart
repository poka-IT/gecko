// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certification_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CertificationDataAdapter extends TypeAdapter<CertificationData> {
  @override
  final int typeId = 8;

  @override
  CertificationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CertificationData(
      receivedCount: fields[0] as int,
      sentCount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CertificationData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.receivedCount)
      ..writeByte(1)
      ..write(obj.sentCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CertificationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
