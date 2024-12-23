class Transaction {
  final DateTime timestamp;
  final String address;
  final String username;
  final double amount;
  final String comment;
  final bool isReceived;

  Transaction({
    required this.timestamp,
    required this.address,
    required this.username,
    required this.amount,
    required this.comment,
    required this.isReceived,
  });
}
