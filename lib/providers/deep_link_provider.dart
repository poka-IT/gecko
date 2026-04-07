import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/services/qr_scanner_service.dart';
import 'package:gecko/services/snackbar_service.dart';

/// Notifier that listens for incoming `g1://` and `june://` deep links.
///
/// Per app_links docs, [AppLinks.uriLinkStream] delivers both the initial
/// cold-start link AND all subsequent links. Must be watched at the root level.
class DeepLinkNotifier extends Notifier<void> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;
  bool _isProcessing = false;

  @override
  void build() {
    _appLinks = AppLinks();
    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
    ref.onDispose(() => _subscription?.cancel());
  }

  void _handleUri(Uri uri) {
    // Concurrency guard - prevents double-navigation from rapid successive links
    if (_isProcessing) {
      log.d('Deep link ignored: already processing another link');
      return;
    }

    final context = Gecko.navigatorContext;
    if (context == null) {
      // Navigator not ready yet (cold start race condition).
      // Queue the URI and retry after the first frame.
      log.d('Deep link queued: navigator not ready');
      _pendingUri = uri;
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPendingUri());
      return;
    }

    _processUri(uri, context);
  }

  /// Retries the queued URI once the navigator is available.
  void _processPendingUri() {
    final uri = _pendingUri;
    _pendingUri = null;
    if (uri == null) return;

    final context = Gecko.navigatorContext;
    if (context == null) {
      // Still not ready - retry once more after next frame
      _pendingUri = uri;
      WidgetsBinding.instance.addPostFrameCallback((_) => _processPendingUri());
      return;
    }

    _processUri(uri, context);
  }

  void _processUri(Uri uri, BuildContext context) {
    _isProcessing = true;

    try {
      final uriString = uri.toString();
      log.i('Deep link received: $uriString');

      // Guard: don't navigate if no wallets exist (e.g. during onboarding)
      final walletsExist = ref.read(isWalletsExistsProvider);
      if (!walletsExist) {
        log.w('Deep link ignored: no wallets configured');
        return;
      }

      // Parse and validate via QrScannerService (same logic as QR/NFC)
      final scannerService = ref.read(qrScannerServiceProvider);
      final result = scannerService.processContent(uriString);

      if (!result.isSuccess || result.address == null) {
        log.w('Deep link address invalid: $uriString');
        if (context.mounted) {
          SnackbarService.showError(context, message: 'qrCodeNotAddress'.tr(), duration: 3);
        }
        return;
      }

      // Store prefill data if amount is present
      if (result.amount != null) {
        ref.read(paymentPrefillProvider.notifier).set(amount: result.amount!, comment: result.comment);
      }

      // Dismiss any open modal/popup before navigating
      Navigator.popUntil(context, (route) => route.settings.name != null);

      // Navigate to profile
      NavigationService.openProfile(context, address: result.address!, autoOpenPayment: result.amount != null);
    } finally {
      _isProcessing = false;
    }
  }
}

/// Provider that monitors incoming deep links. Must be watched at the root level.
final deepLinkProvider = NotifierProvider<DeepLinkNotifier, void>(DeepLinkNotifier.new);
