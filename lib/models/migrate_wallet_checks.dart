import 'package:gecko/models/wallet_data.dart';

class MigrateWalletChecks {
  final Map balance;
  final IdtyStatus idtyStatus;
  final String validationStatus;
  final bool canValidate;

  const MigrateWalletChecks({
    required this.balance,
    required this.idtyStatus,
    required this.validationStatus,
    required this.canValidate,
  });

  const MigrateWalletChecks.defaultValues({
    this.balance = const {'transferableBalance': 0},
    this.idtyStatus = IdtyStatus.none,
    this.validationStatus = '',
    this.canValidate = false,
  });

  @override
  String toString() {
    return {
      'balance': balance,
      'idtyStatus': idtyStatus,
      'validationStatus': validationStatus,
      'canValidate': canValidate,
    }.toString();
  }
}
