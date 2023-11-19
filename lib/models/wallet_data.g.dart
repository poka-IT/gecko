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
      identityStatus: fields[8] as IdtyStatus,
      balance: fields[9] as double,
      certs: (fields[10] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, WalletData obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.identityStatus)
      ..writeByte(9)
      ..write(obj.balance)
      ..writeByte(10)
      ..write(obj.certs);
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

class IdtyStatusAdapter extends TypeAdapter<IdtyStatus> {
  @override
  final int typeId = 5;

  @override
  IdtyStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return IdtyStatus.none;
      case 1:
        return IdtyStatus.created;
      case 2:
        return IdtyStatus.confirmed;
      case 3:
        return IdtyStatus.validated;
      case 4:
        return IdtyStatus.expired;
      case 5:
        return IdtyStatus.unknown;
      default:
        return IdtyStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, IdtyStatus obj) {
    switch (obj) {
      case IdtyStatus.none:
        writer.writeByte(0);
        break;
      case IdtyStatus.created:
        writer.writeByte(1);
        break;
      case IdtyStatus.confirmed:
        writer.writeByte(2);
        break;
      case IdtyStatus.validated:
        writer.writeByte(3);
        break;
      case IdtyStatus.expired:
        writer.writeByte(4);
        break;
      case IdtyStatus.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdtyStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
