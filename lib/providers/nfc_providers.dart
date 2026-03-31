import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/services/nfc_hce_service.dart';
import 'package:gecko/services/nfc_service.dart';

/// NFC hardware status on this device.
///
/// Returns [NFCAvailability.not_supported] on desktop/web,
/// [NFCAvailability.disabled] if turned off in settings,
/// [NFCAvailability.available] if ready.
final nfcAvailabilityProvider = FutureProvider<NFCAvailability>((ref) async {
  return NfcService.checkAvailability();
});

/// NFC operation state for UI feedback.
enum NfcSessionState { idle, polling, reading, emulating, success, error }

/// State for an NFC session.
class NfcSessionData {
  final NfcSessionState state;
  final String? errorMessage;
  final String? paymentUri;

  const NfcSessionData({this.state = NfcSessionState.idle, this.errorMessage, this.paymentUri});

  NfcSessionData copyWith({NfcSessionState? state, String? errorMessage, String? paymentUri}) {
    return NfcSessionData(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentUri: paymentUri ?? this.paymentUri,
    );
  }
}

/// Notifier for managing NFC HCE emulation and reader mode state.
class NfcSessionNotifier extends Notifier<NfcSessionData> {
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  NfcSessionData build() {
    if (!kIsWeb && Platform.isAndroid) {
      _eventSub = NfcHceService.eventStream.listen(_onHceEvent);
      ref.onDispose(() {
        _eventSub?.cancel();
        NfcHceService.stopEmulation();
        NfcHceService.stopReaderMode();
      });
    }
    return const NfcSessionData();
  }

  /// Start HCE emulation (seller mode — phone acts as NFC card).
  Future<void> startEmulation(String uri) async {
    state = state.copyWith(state: NfcSessionState.emulating);
    await NfcHceService.setKeepScreenOn(true);
    final success = await NfcHceService.startEmulation(uri);
    if (!success) {
      state = NfcSessionData(state: NfcSessionState.error, errorMessage: 'HCE not available');
      await NfcHceService.setKeepScreenOn(false);
    }
  }

  /// Stop HCE emulation.
  Future<void> stopEmulation() async {
    await NfcHceService.stopEmulation();
    await NfcHceService.setKeepScreenOn(false);
    state = const NfcSessionData();
  }

  void reset() {
    state = const NfcSessionData();
  }

  void _onHceEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    log.d('HCE event: $type');

    switch (type) {
      case 'emulation_started':
        state = state.copyWith(state: NfcSessionState.emulating);
      case 'emulation_stopped':
        state = const NfcSessionData();
      case 'tag_discovered':
        state = state.copyWith(state: NfcSessionState.reading);
      case 'payment_read':
        final uri = event['paymentUri'] as String?;
        state = NfcSessionData(state: NfcSessionState.success, paymentUri: uri);
      case 'communication_error':
        final msg = event['message'] as String?;
        state = NfcSessionData(state: NfcSessionState.error, errorMessage: msg);
      case 'reader_mode_timeout':
        state = const NfcSessionData();
    }
  }
}

/// Provider for NFC session state (HCE emulation + reader mode).
final nfcSessionProvider = NotifierProvider<NfcSessionNotifier, NfcSessionData>(NfcSessionNotifier.new);
