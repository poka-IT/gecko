import 'package:durt2/durt2.dart' show CsToV2AddressResult, Utils;
import 'package:gecko/globals.dart';

/// Service for handling Cesium to V2 address conversion operations.
///
/// This service provides pure functions for converting Cesium credentials
/// to V2 addresses. It does not manage state directly.
class G1v1MigrationService {
  /// Convert Cesium salt and password to V2 address.
  ///
  /// Returns a [CsToV2AddressResult] containing the converted address and pubkey.
  /// Throws an exception if the conversion fails.
  static Future<CsToV2AddressResult> convertCsToV2Address({
    required Utils utils,
    required String salt,
    required String password,
  }) async {
    try {
      log.d('Converting Cesium credentials to V2 address');

      final result = await utils.csToV2Address(salt, password);

      log.d('Cesium conversion successful: ${result.address}');
      return result;
    } catch (e) {
      log.e('Error converting Cesium credentials: $e');
      rethrow;
    }
  }

  /// Validate Cesium credentials format.
  ///
  /// Returns true if both salt and password are non-empty after trimming.
  static bool isValidCredentials(String salt, String password) {
    return salt.trim().isNotEmpty && password.trim().isNotEmpty;
  }

  /// Clean and validate salt input.
  ///
  /// Removes leading/trailing whitespace and validates format.
  static String cleanSalt(String salt) {
    return salt.trim();
  }

  /// Clean and validate password input.
  ///
  /// Removes leading/trailing whitespace and validates format.
  static String cleanPassword(String password) {
    return password.trim();
  }
}
