import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/nfc_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/services/nfc_hce_service.dart';
import 'package:gecko/services/contact_service.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/services/identicon_service.dart';
import 'package:gecko/services/qr_scanner_service.dart';
import 'package:gecko/services/snackbar_service.dart';

/// State model for profile view (payment form, comments, etc.)
class ProfileViewState {
  final String address;
  final String payAmount;
  final String payComment;
  final bool isCommentVisible;

  const ProfileViewState({this.address = '', this.payAmount = '', this.payComment = '', this.isCommentVisible = false});

  ProfileViewState copyWith({String? address, String? payAmount, String? payComment, bool? isCommentVisible}) {
    return ProfileViewState(
      address: address ?? this.address,
      payAmount: payAmount ?? this.payAmount,
      payComment: payComment ?? this.payComment,
      isCommentVisible: isCommentVisible ?? this.isCommentVisible,
    );
  }
}

/// Notifier for managing profile view state
class ProfileViewNotifier extends Notifier<ProfileViewState> {
  ProfileViewNotifier(this._initialAddress);
  final String? _initialAddress;

  @override
  ProfileViewState build() {
    return ProfileViewState(address: _initialAddress ?? '');
  }

  /// Updates the wallet address
  void setAddress(String address) {
    state = state.copyWith(address: address);
  }

  /// Updates the payment amount
  void setPayAmount(String amount) {
    state = state.copyWith(payAmount: amount);
  }

  /// Updates the payment comment
  void setPayComment(String comment) {
    state = state.copyWith(payComment: comment);
  }

  /// Toggles comment visibility
  void toggleCommentVisibility() {
    state = state.copyWith(
      isCommentVisible: !state.isCommentVisible,
      payComment: !state.isCommentVisible ? state.payComment : '',
    );
  }

  /// Clears all form data
  void clearForm() {
    state = const ProfileViewState();
  }

  /// Resets form but keeps the address
  void resetForm() {
    state = ProfileViewState(address: state.address);
  }
}

/// Provider for profile view state
final profileViewProvider = NotifierProvider.family<ProfileViewNotifier, ProfileViewState, String?>(
  (initialAddress) => ProfileViewNotifier(initialAddress),
);

/// Provider for payment amount controller
final payAmountControllerProvider = Provider.family<TextEditingController, String?>((ref, address) {
  final controller = TextEditingController();

  // Initialize with current state value
  final currentState = ref.read(profileViewProvider(address));
  controller.text = currentState.payAmount;

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Provider for payment comment controller
final payCommentControllerProvider = Provider.family<TextEditingController, String?>((ref, address) {
  final controller = TextEditingController();

  // Initialize with current state value
  final currentState = ref.read(profileViewProvider(address));
  if (currentState.isCommentVisible) {
    controller.text = currentState.payComment;
  }

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// One-shot prefill data for payments initiated via NFC/QR `june://` URIs.
///
/// Set before navigating to profile, consumed and cleared by PaymentPopupWidget.
class PaymentPrefillNotifier extends Notifier<({double amount, String? comment})?> {
  @override
  ({double amount, String? comment})? build() => null;

  void set({required double amount, String? comment}) => state = (amount: amount, comment: comment);
  void clear() => state = null;
}

final paymentPrefillProvider = NotifierProvider<PaymentPrefillNotifier, ({double amount, String? comment})?>(
  PaymentPrefillNotifier.new,
);

/// Provider for scan functionality (QR code + NFC).
///
/// Respects the user's scan preference from settings:
/// - 'qr': directly opens QR scanner
/// - 'nfc': directly opens NFC scanner
/// - 'ask' (default): shows a choice bottom sheet
///
/// If NFC is not supported on the device, always goes to QR.
final qrScanProvider = Provider<Future<void> Function(BuildContext)>((ref) {
  return (BuildContext context) async {
    final nfcAsync = ref.read(nfcAvailabilityProvider);
    final nfcStatus = nfcAsync.whenOrNull(data: (v) => v) ?? NFCAvailability.not_supported;
    final config = ConfigService(configBox);
    final defaultAction = config.scanDefaultAction;

    // If NFC is not supported at all, always QR
    if (nfcStatus == NFCAvailability.not_supported) {
      await _doQrScan(ref, context);
      return;
    }

    // Respect user preference
    if (defaultAction == 'qr') {
      await _doQrScan(ref, context);
      return;
    }
    if (defaultAction == 'nfc') {
      if (nfcStatus == NFCAvailability.disabled) {
        await NfcHceService.openNfcSettings();
        return;
      }
      final scanNfc = ref.read(nfcScanProvider);
      await scanNfc(context);
      return;
    }

    // defaultAction == 'ask': show choice bottom sheet
    final choice = await _showScanChoiceSheet(context, nfcStatus);
    if (choice == null || !context.mounted) return;

    if (choice == _ScanChoice.nfc) {
      final scanNfc = ref.read(nfcScanProvider);
      await scanNfc(context);
      return;
    }
    if (choice == _ScanChoice.enableNfc) {
      await NfcHceService.openNfcSettings();
      return;
    }
    // choice == _ScanChoice.qr
    await _doQrScan(ref, context);
  };
});

/// Performs a QR scan and handles the result.
Future<void> _doQrScan(Ref ref, BuildContext context) async {
  final qrScannerService = ref.read(qrScannerServiceProvider);
  final result = await qrScannerService.scanQrCode(context);
  if (!context.mounted) return;
  _handleScanResult(ref, context, result);
}

enum _ScanChoice { qr, nfc, enableNfc }

/// Shows a bottom sheet with QR and NFC scan options.
Future<_ScanChoice?> _showScanChoiceSheet(BuildContext context, NFCAvailability nfcStatus) {
  return showModalBottomSheet<_ScanChoice>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.qr_code_scanner, size: scaleSize(28)),
              title: Text('scanQRCode'.tr().replaceAll('\n', ' '), style: scaledTextStyle(fontSize: 16)),
              onTap: () => Navigator.pop(ctx, _ScanChoice.qr),
            ),
            if (nfcStatus == NFCAvailability.available)
              ListTile(
                leading: Icon(Icons.nfc_rounded, size: scaleSize(28)),
                title: Text('nfcScan'.tr().replaceAll('\n', ' '), style: scaledTextStyle(fontSize: 16)),
                onTap: () => Navigator.pop(ctx, _ScanChoice.nfc),
              ),
            if (nfcStatus == NFCAvailability.disabled)
              ListTile(
                leading: Icon(Icons.nfc_rounded, size: scaleSize(28), color: Theme.of(ctx).colorScheme.outline),
                title: Text('nfcDisabled'.tr(), style: scaledTextStyle(fontSize: 16)),
                subtitle: Text('nfcEnableHint'.tr(), style: scaledTextStyle(fontSize: 13)),
                trailing: Icon(Icons.settings, size: scaleSize(20)),
                onTap: () => Navigator.pop(ctx, _ScanChoice.enableNfc),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Provider for NFC scanning functionality.
///
/// Shows a dialog on Android during polling (iOS has its own system dialog).
/// Auto-detects both NDEF tags and HCE devices.
final nfcScanProvider = Provider<Future<void> Function(BuildContext)>((ref) {
  return (BuildContext context) async {
    final qrScannerService = ref.read(qrScannerServiceProvider);

    // On Android, show a scanning dialog (iOS has a native system dialog)
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid && context.mounted) {
      _showNfcScanDialog(context);
    }

    QrScanResult result;
    try {
      result = await qrScannerService.readNfc();
    } catch (e) {
      result = QrScanResult.cancelled();
    } finally {
      // Always dismiss the Android dialog, even on unexpected exceptions
      if (isAndroid) {
        final navCtx = Gecko.navigatorContext;
        if (navCtx != null && Navigator.canPop(navCtx)) {
          Navigator.pop(navCtx);
        }
      }
    }

    if (!context.mounted) return;

    if (result.isCancelled) {
      SnackbarService.showMessage(context, message: 'nfcNoTagFound'.tr(), duration: 2);
      return;
    }

    _handleScanResult(ref, context, result);
  };
});

/// Shows a modal dialog during NFC polling on Android.
void _showNfcScanDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaledSizedBox(height: 16),
          Icon(Icons.nfc_rounded, size: scaleSize(48), color: Theme.of(ctx).colorScheme.primary),
          ScaledSizedBox(height: 16),
          Text(
            'nfcReadyToScan'.tr(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          ScaledSizedBox(height: 8),
          SizedBox(width: scaleSize(32), height: scaleSize(32), child: const CircularProgressIndicator(strokeWidth: 2)),
          ScaledSizedBox(height: 16),
        ],
      ),
    ),
  );
}

/// Shared handler for QR and NFC scan results.
void _handleScanResult(Ref ref, BuildContext context, QrScanResult result) {
  if (result.isSuccess && result.address != null) {
    // Store prefill data for the payment popup (consumed after popup opens)
    if (result.amount != null) {
      ref.read(paymentPrefillProvider.notifier).set(amount: result.amount!, comment: result.comment);
    }

    Navigator.popUntil(Gecko.navigatorContext!, ModalRoute.withName(RouteNames.home));
    NavigationService.openProfile(
      Gecko.navigatorContext!,
      address: result.address!,
      autoOpenPayment: result.amount != null,
    );
  } else if (result.isInvalidAddress) {
    if (!context.mounted) return;
    SnackbarService.showError(context, message: 'qrCodeNotAddress'.tr(), duration: 2);
  } else if (result.isError) {
    if (!context.mounted) return;
    SnackbarService.showError(context, message: result.errorMessage ?? 'Scan failed', duration: 2);
  }
  // If cancelled, do nothing
}

/// Provider for identicon generation
final identiconProvider = Provider.family<String, String>((ref, pubkey) {
  final identiconService = ref.read(identiconServiceProvider);
  return identiconService.generateIdenticonSafe(pubkey);
});

/// Provider for checking if an address is a contact
final isContactProvider = Provider.family<bool, String>((ref, address) {
  final contactService = ref.read(contactServiceProvider);
  return contactService.isContact(address);
});

/// Provider for adding/removing contacts
final toggleContactProvider = Provider<Future<void> Function(G1WalletsList, BuildContext)>((ref) {
  return (G1WalletsList profile, BuildContext context) async {
    final contactService = ref.read(contactServiceProvider);

    final result = await contactService.toggleContact(profile);

    if (result.isSuccess) {
      if (!context.mounted) return;
      SnackbarService.showMessage(context, message: result.message, duration: 4);

      // Invalidate the contact status to trigger UI update
      ref.invalidate(isContactProvider(profile.address));

      // Invalidate the contacts list to trigger refresh
      ref.invalidate(allContactsProvider);
    } else if (result.isError) {
      if (!context.mounted) return;
      SnackbarService.showError(context, message: result.errorMessage ?? 'Contact operation failed');
    }
  };
});

/// Provider for all contacts list (unsorted)
final allContactsProvider = Provider<List<G1WalletsList>>((ref) {
  return contactsBox.toMap().values.toList();
});
