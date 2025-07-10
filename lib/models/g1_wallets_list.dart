import 'package:hive_flutter/hive_flutter.dart';

part 'g1_wallets_list.g.dart';

@HiveType(typeId: 2)
class G1WalletsList {
  @HiveField(0)
  late String address;

  @HiveField(1)
  double? balance;

  @HiveField(2)
  Id? id;

  @HiveField(3)
  String? username;

  @HiveField(4)
  String? csName;

  @HiveField(5)
  bool? isMember;

  G1WalletsList({required this.address, this.balance, this.id, this.username, this.csName, this.isMember});

  G1WalletsList.fromJson(Map<String, dynamic> json) {
    address = json['pubkey'];
    balance = json['balance'];
    id = json['id'] != null ? Id.fromJson(json['id']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pubkey'] = address;
    data['balance'] = balance;
    if (id != null) {
      data['id'] = id!.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 3)
class Id {
  bool? isMember;
  String? username;

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
