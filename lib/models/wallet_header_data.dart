class WalletHeaderData {
  final bool hasIdentity;
  final bool isOwner;
  final String? walletName;
  final BigInt balance;
  final List<int> certCount;

  WalletHeaderData({
    required this.hasIdentity,
    required this.isOwner,
    this.walletName,
    required this.balance,
    required this.certCount,
  });

  // Pour comparer si les données ont changé
  bool equals(WalletHeaderData other) {
    if (certCount.isEmpty || other.certCount.isEmpty) {
      return hasIdentity == other.hasIdentity && isOwner == other.isOwner && walletName == other.walletName && balance == other.balance;
    }
    return hasIdentity == other.hasIdentity &&
        isOwner == other.isOwner &&
        walletName == other.walletName &&
        balance == other.balance &&
        certCount[0] == other.certCount[0] &&
        certCount[1] == other.certCount[1];
  }
}
