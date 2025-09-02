import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    // For mobile platforms, use the barcode_scan2 plugin
    if (Platform.isAndroid || Platform.isIOS) {
      // Request camera permission on Android platforms
      if (Platform.isAndroid) {
        final permissionStatus = await Permission.camera.request();
        if (!permissionStatus.isGranted) {
          return QrScanResult.error('Camera permission denied: ${permissionStatus.toString()}');
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
        // Handle native scanner initialization errors (e.g., camera access issues)
        return QrScanResult.error('Scanner failed to initialize: ${e.toString()}');
      }
    } else {
      // For desktop platforms, use the mobile_scanner plugin
      final controller = MobileScannerController();
      QrScanResult? qrResult;
      controller.barcodes.listen((event) {
        if (event.barcodes.first.rawValue != null) {
          controller.pause();
          qrResult = _processScannedContent(event.barcodes.first.rawValue!);
          if (qrResult?.isSuccess == true) {
            controller.stop();
            // ignore: use_build_context_synchronously
            Navigator.pop(homeContext);
          }
        } else {
          controller.start();
        }
      });

      // ignore: use_build_context_synchronously
      await Navigator.push(
        homeContext,
        MaterialPageRoute(
          builder: (context) => MobileScanner(
            controller: controller,
            overlayBuilder: (context, constraints) => Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: () {
                            Navigator.pop(homeContext);
                          },
                          onHover: (isHovering) {
                            // Hover effect handled by InkWell
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7), size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      return qrResult ?? QrScanResult.cancelled();
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
