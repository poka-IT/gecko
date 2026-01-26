// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/profile_view.dart';
import 'package:gecko/services/contact_service.dart';
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

/// Provider for QR code scanning functionality
final qrScanProvider = Provider<Future<void> Function(BuildContext)>((ref) {
  return (BuildContext context) async {
    final qrScannerService = ref.read(qrScannerServiceProvider);

    final result = await qrScannerService.scanQrCode();

    if (result.isSuccess && result.address != null) {
      // Navigate to wallet view with the scanned address
      Navigator.popUntil(homeContext, ModalRoute.withName(RouteNames.home));
      Navigator.push(
        homeContext,
        MaterialPageRoute(
          builder: (context) {
            return ProfileViewScreen(address: result.address!, username: null);
          },
        ),
      );
    } else if (result.isInvalidAddress) {
      SnackbarService.showError(context, message: 'qrCodeNotAddress'.tr(), duration: 2);
    } else if (result.isError) {
      SnackbarService.showError(context, message: result.errorMessage ?? 'Scan failed', duration: 2);
    }
    // If cancelled, do nothing
  };
});

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
      SnackbarService.showMessage(context, message: result.message, duration: 4);

      // Invalidate the contact status to trigger UI update
      ref.invalidate(isContactProvider(profile.address));

      // Invalidate the contacts list to trigger refresh
      ref.invalidate(allContactsProvider);
    } else if (result.isError) {
      SnackbarService.showError(context, message: result.errorMessage ?? 'Contact operation failed');
    }
  };
});

/// Provider for all contacts list (unsorted)
final allContactsProvider = Provider<List<G1WalletsList>>((ref) {
  return contactsBox.toMap().values.toList();
});
