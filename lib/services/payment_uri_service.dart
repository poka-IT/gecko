/// Service for encoding and decoding payment URIs.
///
/// Supports `g1://` (Ğ1 native), `june://` (Ginkgo-compatible), and
/// `duniter:key/` (legacy) formats.
/// Format: `g1://ADDRESS?amount=AMOUNT&comment=COMMENT`
class PaymentUriService {
  /// Known URI scheme prefixes, in priority order.
  static const _schemePrefixes = ['g1://', 'june://', 'duniter:key/'];

  /// Max age for NFC URIs before they're considered stale (seconds).
  static const nfcMaxAgeSecs = 120;

  /// Encodes a payment URI from an address and optional amount/comment.
  ///
  /// Uses `g1://` as the default scheme. Both `g1://` and `june://` are
  /// accepted on read for backward compatibility with Ginkgo.
  /// If [withTimestamp] is true, adds a `t=UNIX_EPOCH` parameter to prevent
  /// stale NFC reads.
  static String encode(String address, {double? amount, String? comment, bool withTimestamp = false}) {
    final buffer = StringBuffer('g1://$address');
    final params = <String>[];

    if (amount != null && amount > 0) {
      params.add('amount=${amount.toString()}');
    }
    if (comment != null && comment.isNotEmpty) {
      params.add('comment=${Uri.encodeComponent(comment)}');
    }
    if (withTimestamp) {
      params.add('t=${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
    }
    if (params.isNotEmpty) {
      buffer.write('?${params.join('&')}');
    }
    return buffer.toString();
  }

  /// Attempts to decode a payment URI (`g1://`, `june://`, or `duniter:key/`).
  ///
  /// Returns null if the string is not a recognized payment URI.
  static PaymentUriData? decode(String input) {
    final trimmed = input.trim();

    String? addressPart;
    Map<String, String> queryParams = {};

    for (final prefix in _schemePrefixes) {
      if (trimmed.startsWith(prefix)) {
        final withoutScheme = trimmed.substring(prefix.length);
        final parts = withoutScheme.split('?');
        addressPart = parts[0];
        if (parts.length > 1) {
          queryParams = Uri.splitQueryString(parts[1]);
        }
        break;
      }
    }

    if (addressPart == null || addressPart.isEmpty) return null;

    // Strip optional checksum (v1 format: PUBKEY:XXX)
    final colonIndex = addressPart.indexOf(':');
    if (colonIndex > 0) {
      addressPart = addressPart.substring(0, colonIndex);
    }

    double? amount;
    final amountStr = queryParams['amount'];
    if (amountStr != null) {
      // Support both . and , as decimal separators
      final parsed = double.tryParse(amountStr.replaceAll(',', '.'));
      if (parsed != null && parsed > 0 && parsed.isFinite) {
        amount = parsed;
      }
    }

    final comment = queryParams['comment'];

    // Parse optional timestamp
    int? timestamp;
    final tStr = queryParams['t'];
    if (tStr != null) {
      timestamp = int.tryParse(tStr);
    }

    return PaymentUriData(rawAddress: addressPart, amount: amount, comment: comment, timestamp: timestamp);
  }

  /// Returns true if the input looks like a payment URI.
  static bool isPaymentUri(String input) {
    final trimmed = input.trim();
    return _schemePrefixes.any(trimmed.startsWith);
  }
}

/// Parsed payment URI data.
class PaymentUriData {
  final String rawAddress;
  final double? amount;
  final String? comment;
  final int? timestamp;

  const PaymentUriData({required this.rawAddress, this.amount, this.comment, this.timestamp});

  /// Whether this URI has expired (timestamp is too old).
  /// Returns false if no timestamp is present (backward compatible).
  bool get isExpired {
    if (timestamp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - timestamp!) > PaymentUriService.nfcMaxAgeSecs;
  }
}
