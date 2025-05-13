import 'package:durt2/durt2.dart' show IdtyStatus;

class MigrateWalletChecks {
  final Map<String, dynamic> fromBalance;
  final IdtyStatus fromIdtyStatus;
  final IdtyStatus toIdtyStatus;
  final String validationStatus;
  final bool canValidate;

  const MigrateWalletChecks({
    required this.fromBalance,
    required this.fromIdtyStatus,
    required this.toIdtyStatus,
    required this.validationStatus,
    required this.canValidate,
  });

  const MigrateWalletChecks.defaultValues({
    this.fromBalance = const {'transferableBalance': 0},
    this.fromIdtyStatus = IdtyStatus.none,
    this.toIdtyStatus = IdtyStatus.none,
    this.validationStatus = '',
    this.canValidate = false,
  });

  @override
  String toString() {
    return {
      'balance': fromBalance,
      'fromIdtyStatus': fromIdtyStatus,
      'toIdtyStatus': toIdtyStatus,
      'validationStatus': validationStatus,
      'canValidate': canValidate,
    }.toString();
  }
}
