import 'package:hive_flutter/hive_flutter.dart';
part 'g1_wallets_list_live.g.dart';

@HiveType(typeId: 4)
class G1WalletsListLive {
  @HiveField(0)
  Data data;

  G1WalletsListLive({this.data});

  G1WalletsListLive.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 5)
class Data {
  Wallets wallets;

  Data({this.wallets});

  Data.fromJson(Map<String, dynamic> json) {
    wallets =
        json['wallets'] != null ? Wallets.fromJson(json['wallets']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (wallets != null) {
      data['wallets'] = wallets.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 6)
class Wallets {
  List<Edges> edges;
  PageInfo pageInfo;

  Wallets({this.edges, this.pageInfo});

  Wallets.fromJson(Map<String, dynamic> json) {
    if (json['edges'] != null) {
      edges = <Edges>[];
      json['edges'].forEach((v) {
        edges.add(Edges.fromJson(v));
      });
    }
    pageInfo =
        json['pageInfo'] != null ? PageInfo.fromJson(json['pageInfo']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (edges != null) {
      data['edges'] = edges.map((v) => v.toJson()).toList();
    }
    if (pageInfo != null) {
      data['pageInfo'] = pageInfo.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 7)
class Edges {
  Node node;

  Edges({this.node});

  Edges.fromJson(Map<String, dynamic> json) {
    node = json['node'] != null ? Node.fromJson(json['node']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (node != null) {
      data['node'] = node.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 8)
class Node {
  Balance balance;
  Idty idty;
  String script;

  Node({this.balance, this.idty, this.script});

  Node.fromJson(Map<String, dynamic> json) {
    balance =
        json['balance'] != null ? Balance.fromJson(json['balance']) : null;
    idty = json['idty'] != null ? Idty.fromJson(json['idty']) : null;
    script = json['script'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (balance != null) {
      data['balance'] = balance.toJson();
    }
    if (idty != null) {
      data['idty'] = idty.toJson();
    }
    data['script'] = script;
    return data;
  }
}

@HiveType(typeId: 9)
class Balance {
  int amount;
  int base;

  Balance({this.amount, this.base});

  Balance.fromJson(Map<String, dynamic> json) {
    amount = json['amount'];
    base = json['base'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['base'] = base;
    return data;
  }
}

@HiveType(typeId: 10)
class Idty {
  bool isMember;
  String username;

  Idty({this.isMember, this.username});

  Idty.fromJson(Map<String, dynamic> json) {
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

@HiveType(typeId: 11)
class PageInfo {
  String endCursor;
  bool hasNextPage;

  PageInfo({this.endCursor, this.hasNextPage});

  PageInfo.fromJson(Map<String, dynamic> json) {
    endCursor = json['endCursor'];
    hasNextPage = json['hasNextPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['endCursor'] = endCursor;
    data['hasNextPage'] = hasNextPage;
    return data;
  }
}
