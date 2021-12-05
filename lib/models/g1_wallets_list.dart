import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'g1_wallets_list.g.dart';

@HiveType(typeId: 2)
class G1WalletsList {
  @HiveField(0)
  String pubkey;

  @HiveField(1)
  double balance;

  @HiveField(3)
  Id id;

  @HiveField(4)
  Image avatar;

  @HiveField(5)
  String username;

  @HiveField(6)
  String csName;

  @HiveField(7)
  bool isMembre;

  G1WalletsList({
    this.pubkey,
    this.balance,
    this.id,
    this.avatar,
    this.username,
    this.csName,
    this.isMembre,
  });

  G1WalletsList.fromJson(Map<String, dynamic> json) {
    pubkey = json['pubkey'];
    balance = json['balance'];
    id = json['id'] != null ? Id.fromJson(json['id']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pubkey'] = pubkey;
    data['balance'] = balance;
    if (id != null) {
      data['id'] = id.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 3)
class Id {
  bool isMember;
  String username;

  Id({this.isMember, this.username});

  Id.fromJson(Map<String, dynamic> json) {
    isMember = json['isMember'];
    username = json['username'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isMember'] = isMember;
    data['username'] = username;
    return data;
  }
}
