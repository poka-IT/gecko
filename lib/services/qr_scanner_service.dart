import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling QR code scanning operations.
///
/// This service encapsulates QR code scanning logic, permission handling,
/// and result processing for wallet addresses and public keys.
class QrScannerService {
  final Ref _ref;

  QrScannerService(this._ref);

  /// Scans a QR code and returns the processed result.
  ///
  /// Returns a [QrScanResult] containing the processed address and scan status.
  /// Handles camera permissions and validates the scanned content.
  Future<QrScanResult> scanQrCode() async {
    // Request camera permission on mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        return QrScanResult.error('Camera permission denied');
      }
    }

    try {
      final scanOptions = ScanOptions(
        strings: {'cancel': 'cancel'.tr(), 'flash_on': 'Flash on', 'flash_off': 'Flash off'},
      );

      final barcode = await BarcodeScanner.scan(options: scanOptions);
      final barcodeContent = barcode.rawContent;

      if (barcodeContent.isEmpty) {
        return QrScanResult.cancelled();
      }

      return _processScannedContent(barcodeContent);
    } catch (e) {
      return QrScanResult.error('Scan failed: $e');
    }
  }

  /// Processes the scanned QR code content and validates it as an address or pubkey.
  QrScanResult _processScannedContent(String content) {
    final utils = _ref.read(utilsProvider);

    if (_isAddressOrPubkey(content)) {
      String finalAddress;

      if (_isAddress(content)) {
        finalAddress = utils.isAddressValidToSs58(content);
      } else {
        // Convert pubkey to address
        final addressTmp = utils.pubkeyV1ToAddress(content);
        finalAddress = utils.isAddressValidToSs58(addressTmp);
      }

      return QrScanResult.success(finalAddress);
    } else {
      return QrScanResult.invalidAddress();
    }
  }

  /// Checks if the input is a valid address or public key.
  bool _isAddressOrPubkey(String input) => _isAddress(input) || _isPubkey(input);

  /// Validates if the input is a valid address.
  bool _isAddress(String address) {
    try {
      final utils = _ref.read(utilsProvider);
      return utils.isAddressValid(address);
    } catch (e) {
      return false;
    }
  }

  /// Validates if the input is a valid public key.
  bool _isPubkey(String pubkey) {
    final cleanPubkey = pubkey.split(':')[0];
    final regExp = RegExp(r'^[a-zA-Z0-9]+$', caseSensitive: false, multiLine: false);
    return regExp.hasMatch(cleanPubkey) && cleanPubkey.length > 42 && cleanPubkey.length < 45;
  }
}

/// Result class for QR code scanning operations.
class QrScanResult {
  final String? address;
  final QrScanStatus status;
  final String? errorMessage;

  const QrScanResult._({this.address, required this.status, this.errorMessage});

  /// Creates a successful scan result with a valid address.
  factory QrScanResult.success(String address) {
    return QrScanResult._(address: address, status: QrScanStatus.success);
  }

  /// Creates an error result with an error message.
  factory QrScanResult.error(String message) {
    return QrScanResult._(status: QrScanStatus.error, errorMessage: message);
  }

  /// Creates a cancelled scan result.
  factory QrScanResult.cancelled() {
    return const QrScanResult._(status: QrScanStatus.cancelled);
  }

  /// Creates an invalid address result.
  factory QrScanResult.invalidAddress() {
    return const QrScanResult._(status: QrScanStatus.invalidAddress);
  }

  bool get isSuccess => status == QrScanStatus.success;
  bool get isError => status == QrScanStatus.error;
  bool get isCancelled => status == QrScanStatus.cancelled;
  bool get isInvalidAddress => status == QrScanStatus.invalidAddress;
}

/// Enum representing the possible states of a QR scan operation.
enum QrScanStatus { success, error, cancelled, invalidAddress }

/// Provider for QrScannerService
final qrScannerServiceProvider = Provider<QrScannerService>((ref) {
  return QrScannerService(ref);
});
