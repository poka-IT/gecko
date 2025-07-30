import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

/// Service for generating identicon avatars.
///
/// This service provides functionality to generate SVG identicons
/// from public keys or addresses, typically used for user avatars.
class IdenticonService {
  /// Generates an SVG identicon from a public key or address.
  ///
  /// Takes a [pubkey] (or address) and returns an SVG string
  /// representing a unique visual identicon for that input.
  String generateIdenticon(String pubkey) {
    return Jdenticon.toSvg(pubkey);
  }

  /// Generates an identicon with custom size.
  ///
  /// Provides more control over the generated identicon with optional
  /// size parameter.
  String generateIdenticonWithSize({required String pubkey, int? size}) {
    if (size != null) {
      return Jdenticon.toSvg(pubkey, size: size);
    } else {
      return Jdenticon.toSvg(pubkey);
    }
  }

  /// Validates if the input can be used to generate a valid identicon.
  bool isValidIdenticonInput(String input) {
    return input.isNotEmpty && input.trim().isNotEmpty;
  }

  /// Generates a default identicon for cases where the input is invalid.
  String generateDefaultIdenticon() {
    return Jdenticon.toSvg('default');
  }

  /// Generates an identicon with fallback to default if input is invalid.
  String generateIdenticonSafe(String pubkey) {
    if (!isValidIdenticonInput(pubkey)) {
      return generateDefaultIdenticon();
    }
    return generateIdenticon(pubkey);
  }
}

/// Provider for IdenticonService
final identiconServiceProvider = Provider<IdenticonService>((ref) {
  return IdenticonService();
});
