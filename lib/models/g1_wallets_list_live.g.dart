// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'g1_wallets_list_live.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class G1WalletsListLiveAdapter extends TypeAdapter<G1WalletsListLive> {
  @override
  final int typeId = 4;

  @override
  G1WalletsListLive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return G1WalletsListLive(
      data: fields[0] as Data,
    );
  }

  @override
  void write(BinaryWriter writer, G1WalletsListLive obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is G1WalletsListLiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DataAdapter extends TypeAdapter<Data> {
  @override
  final int typeId = 5;

  @override
  Data read(BinaryReader reader) {
    return Data();
  }

  @override
  void write(BinaryWriter writer, Data obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WalletsAdapter extends TypeAdapter<Wallets> {
  @override
  final int typeId = 6;

  @override
  Wallets read(BinaryReader reader) {
    return Wallets();
  }

  @override
  void write(BinaryWriter writer, Wallets obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EdgesAdapter extends TypeAdapter<Edges> {
  @override
  final int typeId = 7;

  @override
  Edges read(BinaryReader reader) {
    return Edges();
  }

  @override
  void write(BinaryWriter writer, Edges obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NodeAdapter extends TypeAdapter<Node> {
  @override
  final int typeId = 8;

  @override
  Node read(BinaryReader reader) {
    return Node();
  }

  @override
  void write(BinaryWriter writer, Node obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BalanceAdapter extends TypeAdapter<Balance> {
  @override
  final int typeId = 9;

  @override
  Balance read(BinaryReader reader) {
    return Balance();
  }

  @override
  void write(BinaryWriter writer, Balance obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IdtyAdapter extends TypeAdapter<Idty> {
  @override
  final int typeId = 10;

  @override
  Idty read(BinaryReader reader) {
    return Idty();
  }

  @override
  void write(BinaryWriter writer, Idty obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdtyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PageInfoAdapter extends TypeAdapter<PageInfo> {
  @override
  final int typeId = 11;

  @override
  PageInfo read(BinaryReader reader) {
    return PageInfo();
  }

  @override
  void write(BinaryWriter writer, PageInfo obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
