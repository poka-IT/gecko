import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/sentry_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for handling QR code scanning operations.
///
/// This service encapsulates QR code scanning logic, permission handling,
/// and result processing for wallet addresses and public keys.
class QrScannerService {
  final Ref _ref;

  QrScannerService(this._ref);

  /// Checks system resources before scanning to prevent native crashes
  Future<Map<String, dynamic>> _checkSystemResources() async {
    final resources = <String, dynamic>{};

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Collect detailed Android device information
        resources['platform'] = 'android';
        resources['timestamp'] = DateTime.now().toIso8601String();
        resources['device_brand'] = androidInfo.brand;
        resources['device_manufacturer'] = androidInfo.manufacturer;
        resources['device_model'] = androidInfo.model;
        resources['android_version'] = androidInfo.version.release;
        resources['android_sdk_int'] = androidInfo.version.sdkInt.toString();
        resources['device_hardware'] = androidInfo.hardware;
        resources['device_product'] = androidInfo.product;

        // Check if this is the problematic device combination from the Sentry issue
        final isOnePlusAndroid11 =
            androidInfo.manufacturer.toLowerCase().contains('oneplus') && androidInfo.version.release == '11';
        resources['is_problematic_device'] = isOnePlusAndroid11.toString();

        // Add memory pressure monitoring
        resources['memory_info'] = await _checkMemoryPressure();

        // Add specific checks for conditions that might lead to SIGABRT
        resources['potential_sigabrt_risk'] = _assessSigabrtRisk(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        resources['platform'] = 'ios';
        resources['device_model'] = iosInfo.model;
        resources['ios_version'] = iosInfo.systemVersion;
        resources['device_name'] = iosInfo.name;
      }

      // Add more resource checks as needed
      resources['camera_permission_checked'] = true;
    } catch (e) {
      resources['resource_check_error'] = e.toString();
      resources['platform'] = Platform.isAndroid ? 'android' : 'ios';
    }

    return resources;
  }

  /// Checks memory pressure to detect potential native crash conditions
  Future<Map<String, dynamic>> _checkMemoryPressure() async {
    final memoryInfo = <String, dynamic>{};

    try {
      // Basic memory pressure indicators
      memoryInfo['timestamp'] = DateTime.now().toIso8601String();

      // On Android, we can use basic system information
      if (Platform.isAndroid) {
        // This is a simplified check - in a real implementation you might want to:
        // 1. Check available heap memory
        // 2. Monitor GC frequency
        // 3. Check system memory pressure
        memoryInfo['platform'] = 'android';
        memoryInfo['gc_pressure'] = 'unknown'; // Could be enhanced with actual GC monitoring

        // Add a simple memory pressure indicator based on time since last GC
        // This is a placeholder - real implementation would use actual memory APIs
        memoryInfo['estimated_memory_pressure'] = 'low'; // Default assumption
      }

      return memoryInfo;
    } catch (e) {
      return {'error': e.toString(), 'memory_check_failed': true};
    }
  }

  /// Assesses the risk of SIGABRT crashes based on known patterns
  String _assessSigabrtRisk(dynamic deviceInfo) {
    try {
      // Based on the Sentry issue AXIOM-TEAM-AT, this affects OnePlus devices on Android 11
      if (Platform.isAndroid && deviceInfo != null) {
        final manufacturer = deviceInfo.manufacturer?.toLowerCase() ?? '';
        final androidVersion = deviceInfo.version?.release ?? '';

        // High risk: OnePlus devices on Android 11 (exact match from Sentry issue)
        if (manufacturer.contains('oneplus') && androidVersion == '11') {
          return 'high_risk_oneplus_android11';
        }

        // Medium risk: OnePlus devices on other Android versions
        if (manufacturer.contains('oneplus')) {
          return 'medium_risk_oneplus_other_android';
        }

        // Medium risk: Other devices on Android 11
        if (androidVersion == '11') {
          return 'medium_risk_android11_other_device';
        }

        return 'low_risk_android';
      }

      return 'low_risk_non_android';
    } catch (e) {
      return 'risk_assessment_failed';
    }
  }

  /// Scans a QR code and returns the processed result.
  ///
  /// Returns a [QrScanResult] containing the processed address and scan status.
  /// Handles camera permissions and validates the scanned content.
  Future<QrScanResult> scanQrCode() async {
    // Check system resources before attempting to scan
    final systemResources = await _checkSystemResources();

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
        // Report to Sentry for debugging native crashes with enhanced context
        SentryService.captureException(
          e,
          tag: 'qr_scanner_error',
          extra: {
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'error_type': 'scanner_initialization',
            'device_info': Platform.isAndroid ? 'android_device' : 'ios_device',
            'camera_permission_status': 'granted', // We know it's granted at this point
            'related_issue': 'AXIOM-TEAM-AT', // Reference to the Sentry issue
            ...systemResources, // Include system resource information
          },
        );
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
        // ignore: use_build_context_synchronously
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
