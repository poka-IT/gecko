import 'package:hive_flutter/hive_flutter.dart';

part 'wallet_balance.g.dart';

@HiveType(typeId: 10)
class WalletBalance {
  @HiveField(0)
  final int transferableBalance;

  @HiveField(1)
  final int free;

  @HiveField(2)
  final int unclaimedUds;

  @HiveField(3)
  final int reserved;

  WalletBalance({
    required this.transferableBalance,
    required this.free,
    required this.unclaimedUds,
    required this.reserved,
  });

  factory WalletBalance.empty() {
    return WalletBalance(
      transferableBalance: 0,
      free: 0,
      unclaimedUds: 0,
      reserved: 0,
    );
  }

  factory WalletBalance.fromMap(Map<String, int> map) {
    return WalletBalance(
      transferableBalance: map['transferableBalance'] ?? 0,
      free: map['free'] ?? 0,
      unclaimedUds: map['unclaimedUds'] ?? 0,
      reserved: map['reserved'] ?? 0,
    );
  }

  Map<String, int> toMap() {
    return {
      'transferableBalance': transferableBalance,
      'free': free,
      'unclaimedUds': unclaimedUds,
      'reserved': reserved,
    };
  }
}
