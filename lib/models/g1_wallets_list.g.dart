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
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return G1WalletsList(
      pubkey: fields[0] as String?,
      balance: fields[1] as double?,
      id: fields[3] as Id?,
      avatar: fields[4] as Image?,
      username: fields[5] as String?,
      csName: fields[6] as String?,
      isMembre: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, G1WalletsList obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.pubkey)
      ..writeByte(1)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.avatar)
      ..writeByte(5)
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.csName)
      ..writeByte(7)
      ..write(obj.isMembre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is G1WalletsListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
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
      identical(this, other) ||
      other is IdAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
