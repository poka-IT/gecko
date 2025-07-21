import 'package:durt2/durt2.dart' as d;

/// Represents identity migration data from Squid GraphQL queries
class MigrationData {
  final String fromAddress;
  final String toAddress;
  final DateTime migrationDate;
  final String? identityName;

  MigrationData({required this.fromAddress, required this.toAddress, required this.migrationDate, this.identityName});

  /// Create MigrationData from a Squid "from" migration node (identity migrated FROM this address)
  static Future<MigrationData?> fromSquidMigrationFromNode(
    d.Query$GetIdentityMigrations$changeOwnerKeyConnection$edges$node node,
    DateTime genesisTime,
  ) async {
    try {
      final migrationDate = _blockNumberToDate(node.blockNumber, genesisTime);

      // Ensure we have both addresses
      if (node.previousId == null || node.nextId == null) {
        return null;
      }

      return MigrationData(
        fromAddress: node.previousId!,
        toAddress: node.nextId!,
        migrationDate: migrationDate,
        identityName: node.identity?.name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create MigrationData from a Squid "to" migration node (identity migrated TO this address)
  static Future<MigrationData?> fromSquidMigrationToNode(
    d.Query$GetIdentityMigrations$changeOwnerKeyConnection$edges$node node,
    DateTime genesisTime,
  ) async {
    try {
      final migrationDate = _blockNumberToDate(node.blockNumber, genesisTime);

      // Ensure we have both addresses
      if (node.previousId == null || node.nextId == null) {
        return null;
      }

      return MigrationData(
        fromAddress: node.previousId!,
        toAddress: node.nextId!,
        migrationDate: migrationDate,
        identityName: node.identity?.name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert block number to DateTime (6 seconds per block)
  static DateTime _blockNumberToDate(int blockNumber, DateTime genesisTime) {
    return genesisTime.add(Duration(seconds: blockNumber * 6));
  }
}
