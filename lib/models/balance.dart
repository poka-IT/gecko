class BalanceData {
  final BigInt transferableBalance;
  final BigInt free;
  final BigInt reserved;
  final BigInt unclaimedUds;

  BalanceData({required this.transferableBalance, required this.free, required this.reserved, required this.unclaimedUds});

  @override
  String toString() {
    return 'BalanceData(transferableBalance: $transferableBalance, free: $free, reserved: $reserved, unclaimedUds: $unclaimedUds)';
  }
}
