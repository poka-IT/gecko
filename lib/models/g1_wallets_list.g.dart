// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'g1_wallets_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class G1WalletsListAdapter extends TypeAdapter<G1WalletsList> {
  @override
  final int typeId = 2;

  @override
  G1WalletsList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return G1WalletsList(
      address: fields[0] as String,
      balance: fields[1] as double?,
      id: fields[2] as Id?,
      username: fields[3] as String?,
      csName: fields[4] as String?,
      isMember: fields[5] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, G1WalletsList obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.balance)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.csName)
      ..writeByte(5)
      ..write(obj.isMember);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is G1WalletsListAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class IdAdapter extends TypeAdapter<Id> {
  @override
  final int typeId = 3;

  @override
  Id read(BinaryReader reader) {
    return Id();
  }

  @override
  void write(BinaryWriter writer, Id obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
