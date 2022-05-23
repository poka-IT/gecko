// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keystore_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyStoreDataAdapter extends TypeAdapter<KeyStoreData> {
  @override
  final int typeId = 4;

  @override
  KeyStoreData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyStoreData(
      keystore: fields[0] as KeyPairData?,
    );
  }

  @override
  void write(BinaryWriter writer, KeyStoreData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.keystore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyStoreDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
