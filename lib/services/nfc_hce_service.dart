import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';

/// Flutter-side wrapper for the native NFC HCE (Host Card Emulation) plugin.
///
/// Provides seller-mode (emulate NFC card) and buyer-mode (read HCE device)
/// via platform channels. Android only — returns graceful fallbacks on other platforms.
class NfcHceService {
  static const _channel = MethodChannel('gecko.axiomteam.gecko/nfc_hce');
  static const _eventChannel = EventChannel('gecko.axiomteam.gecko/nfc_hce_events');

  static Stream<Map<String, dynamic>>? _eventStream;

  /// Stream of NFC HCE events from native code.
  ///
  /// Event types: `emulation_started`, `emulation_stopped`, `tag_discovered`,
  /// `payment_read` (with `paymentUri`), `communication_error`,
  /// `reader_mode_started`, `reader_mode_stopped`, `reader_mode_timeout`.
  static Stream<Map<String, dynamic>> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) return Map<String, dynamic>.from(event);
      return <String, dynamic>{'type': 'unknown'};
    });
    return _eventStream!;
  }

  /// Whether the device supports HCE (Android with NFC enabled).
  static Future<bool> isSupported() async {
    if (!_isAndroid()) return false;
    try {
      return await _channel.invokeMethod<bool>('isHceSupported') ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      log.w('HCE support check failed: $e');
      return false;
    }
  }

  /// Starts HCE emulation with the given payment URI (seller mode).
  ///
  /// The phone will act as an NFC card, responding with [uri] when
  /// a reader sends a SELECT with the G1NKGO AID.
  static Future<bool> startEmulation(String uri) async {
    if (!_isAndroid()) return false;
    try {
      return await _channel.invokeMethod<bool>('startEmulation', {'uri': uri}) ?? false;
    } catch (e) {
      log.w('HCE start emulation failed: $e');
      return false;
    }
  }

  /// Stops HCE emulation.
  static Future<void> stopEmulation() async {
    if (!_isAndroid()) return;
    try {
      await _channel.invokeMethod('stopEmulation');
    } catch (e) {
      log.w('HCE stop emulation failed: $e');
    }
  }

  /// Whether HCE emulation is currently active.
  static Future<bool> isEmulating() async {
    if (!_isAndroid()) return false;
    try {
      return await _channel.invokeMethod<bool>('isEmulating') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Starts native reader mode to detect HCE devices (buyer mode).
  ///
  /// Uses `NfcAdapter.enableReaderMode()` for optimized ISO-DEP detection.
  /// On tag discovery, sends SELECT with G1NKGO AID and reads payment URI.
  /// Results come via [eventStream] as `payment_read` or `communication_error`.
  static Future<bool> startReaderMode({int timeoutMs = 15000}) async {
    if (!_isAndroid()) return false;
    try {
      return await _channel.invokeMethod<bool>('startReaderMode', {'timeoutMs': timeoutMs}) ?? false;
    } catch (e) {
      log.w('HCE start reader mode failed: $e');
      return false;
    }
  }

  /// Stops native reader mode.
  static Future<void> stopReaderMode() async {
    if (!_isAndroid()) return;
    try {
      await _channel.invokeMethod('stopReaderMode');
    } catch (e) {
      log.w('HCE stop reader mode failed: $e');
    }
  }

  /// Keeps the screen on during HCE emulation.
  static Future<void> setKeepScreenOn(bool keepOn) async {
    if (!_isAndroid()) return;
    try {
      await _channel.invokeMethod('setKeepScreenOn', {'keepOn': keepOn});
    } catch (e) {
      log.w('setKeepScreenOn failed: $e');
    }
  }

  /// Opens the Android NFC settings page so the user can enable NFC.
  static Future<void> openNfcSettings() async {
    if (!_isAndroid()) return;
    try {
      await _channel.invokeMethod('openNfcSettings');
    } catch (e) {
      log.w('openNfcSettings failed: $e');
    }
  }

  static bool _isAndroid() => !kIsWeb && Platform.isAndroid;
}
