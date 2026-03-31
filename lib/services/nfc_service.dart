import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:gecko/globals.dart';

/// Service for NFC tag read/write and HCE APDU operations.
///
/// All methods are static and include platform guards to prevent
/// calls on unsupported platforms (web, desktop).
class NfcService {
  // G1NKGO AID for HCE device detection (shared with Ginkgo)
  static const _g1nkgoAid = 'F047314E4B474F';
  static final _selectApdu = '00A4040007${_g1nkgoAid}00';

  /// Checks NFC hardware status on this device.
  ///
  /// Returns [NFCAvailability.not_supported] on desktop/web or no hardware,
  /// [NFCAvailability.disabled] if hardware exists but is turned off,
  /// [NFCAvailability.available] if ready to use.
  static Future<NFCAvailability> checkAvailability() async {
    if (!_isMobilePlatform()) return NFCAvailability.not_supported;
    try {
      return await FlutterNfcKit.nfcAvailability;
    } catch (e) {
      log.w('NFC availability check failed: $e');
      return NFCAvailability.not_supported;
    }
  }

  /// Reads an NDEF URI record from a physical NFC tag.
  ///
  /// Polls for [timeout] duration (default 10 seconds).
  /// Returns the URI string, or null if no valid URI was found.
  static Future<String?> readTag({Duration timeout = const Duration(seconds: 10)}) async {
    if (!_isMobilePlatform()) return null;
    try {
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosMultipleTagMessage: 'Multiple NFC tags detected',
        iosAlertMessage: 'Hold your device near the NFC tag',
      );

      HapticFeedback.lightImpact(); // Tag detected feedback

      // Try HCE device first (ISO-DEP tag without NDEF = likely HCE)
      if (tag.ndefAvailable != true && tag.type == NFCTagType.iso7816) {
        final hceResult = await _readFromHceTag();
        if (hceResult != null) {
          HapticFeedback.heavyImpact();
          await FlutterNfcKit.finish(iosAlertMessage: 'Payment received');
          return hceResult;
        }
      }

      // Fall back to NDEF reading
      if (tag.ndefAvailable != true) {
        await FlutterNfcKit.finish(iosErrorMessage: 'Tag not compatible');
        return null;
      }

      final records = await FlutterNfcKit.readNDEFRecords();
      String? result;

      for (final record in records) {
        if (record is ndef.UriRecord) {
          result = record.iriString;
          break;
        }
        if (record is ndef.TextRecord) {
          result = record.text;
          break;
        }
      }

      if (result != null) HapticFeedback.heavyImpact();
      await FlutterNfcKit.finish(iosAlertMessage: result != null ? 'Read successful' : 'No data found');
      return result;
    } catch (e) {
      log.w('NFC read failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Read failed');
      } catch (_) {}
      return null;
    }
  }

  /// Reads a payment URI from an HCE device via APDU commands.
  ///
  /// Polls for an ISO-DEP tag, sends SELECT with G1NKGO AID, reads the response.
  /// Works on both Android and iOS (uses flutter_nfc_kit transceive).
  static Future<String?> readFromHceDevice({Duration timeout = const Duration(seconds: 15)}) async {
    if (!_isMobilePlatform()) return null;
    try {
      await FlutterNfcKit.poll(
        timeout: timeout,
        androidCheckNDEF: false,
        readIso14443A: true,
        readIso14443B: true,
        readIso18092: false,
        iosAlertMessage: 'Hold your device near the payment terminal',
      );

      final result = await _readFromHceTag();
      await FlutterNfcKit.finish(iosAlertMessage: result != null ? 'Payment received' : 'No payment data found');
      return result;
    } catch (e) {
      log.w('HCE read failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Read failed');
      } catch (_) {}
      return null;
    }
  }

  /// Sends SELECT + GET_DATA APDUs to the currently connected tag.
  static Future<String?> _readFromHceTag() async {
    try {
      // Send SELECT with G1NKGO AID
      final selectResponse = await FlutterNfcKit.transceive(_selectApdu);
      if (selectResponse.length < 4) return null; // Need at least "XXXX" (2 bytes hex = 4 chars)

      final sw = selectResponse.substring(selectResponse.length - 4);

      if (sw == '9000' && selectResponse.length > 4) {
        // Single round-trip: URI in SELECT response
        final dataHex = selectResponse.substring(0, selectResponse.length - 4);
        return _hexToString(dataHex);
      }

      if (sw.startsWith('61')) {
        // Fragmented: need GET_DATA commands
        return await _readFragmented();
      }

      return null;
    } catch (e) {
      log.w('APDU exchange failed: $e');
      return null;
    }
  }

  /// Reads fragmented data via GET_DATA commands.
  static Future<String?> _readFragmented() async {
    final buffer = StringBuffer();
    var fragmentIndex = 0;

    while (true) {
      final p2Hex = fragmentIndex.toRadixString(16).padLeft(2, '0');
      final getDataApdu = '00CA00${p2Hex}00';
      final response = await FlutterNfcKit.transceive(getDataApdu);

      if (response.length < 4) break;

      final sw = response.substring(response.length - 4);
      if (response.length > 4) {
        buffer.write(response.substring(0, response.length - 4));
      }

      if (sw == '9000') break; // Last fragment
      if (!sw.startsWith('61')) break; // Unexpected status
      fragmentIndex++;
    }

    final hex = buffer.toString();
    return hex.isNotEmpty ? _hexToString(hex) : null;
  }

  /// Writes a URI as an NDEF record to a physical NFC tag.
  ///
  /// Polls for [timeout] duration (default 10 seconds).
  /// Returns true on success, false on failure.
  static Future<bool> writeTag(String uri, {Duration timeout = const Duration(seconds: 10)}) async {
    if (!_isMobilePlatform()) return false;
    try {
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosMultipleTagMessage: 'Multiple NFC tags detected',
        iosAlertMessage: 'Hold your device near the NFC tag',
      );

      if (tag.ndefAvailable != true) {
        await FlutterNfcKit.finish(iosErrorMessage: 'Tag not compatible');
        return false;
      }

      if (tag.ndefWritable != true) {
        await FlutterNfcKit.finish(iosErrorMessage: 'Tag is read-only');
        return false;
      }

      await FlutterNfcKit.writeNDEFRecords([ndef.UriRecord.fromString(uri)]);
      HapticFeedback.heavyImpact();
      await FlutterNfcKit.finish(iosAlertMessage: 'Written successfully');
      return true;
    } catch (e) {
      log.w('NFC write failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Write failed');
      } catch (_) {}
      return false;
    }
  }

  /// Converts a hex string to a UTF-8 string.
  static String _hexToString(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return utf8.decode(bytes);
  }

  /// Returns true if current platform supports NFC (Android or iOS).
  static bool _isMobilePlatform() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
