import 'package:gecko/models/wallet_data.dart';

class MigrateWalletChecks {
  final Map balance;
  final IdtyStatus idtyStatus;
  final bool isSmith;
  final String validationStatus;
  final bool canValidate;

  const MigrateWalletChecks(
      {required this.balance,
      required this.idtyStatus,
      required this.isSmith,
      required this.validationStatus,
      required this.canValidate});
}
