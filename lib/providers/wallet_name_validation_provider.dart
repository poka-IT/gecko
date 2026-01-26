import 'package:durt2/durt2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/services/wallet_management_service.dart';

/// State for wallet name validation
class WalletNameValidationState {
  final bool isValid;
  final String? errorMessage;

  const WalletNameValidationState({required this.isValid, this.errorMessage});

  const WalletNameValidationState.initial() : this(isValid: false);

  const WalletNameValidationState.valid() : this(isValid: true);

  const WalletNameValidationState.invalid(String error) : this(isValid: false, errorMessage: error);
}

/// Provider for wallet name validation state
///
/// This provider manages the reactive validation state for wallet name input fields.
/// It validates names based on length, character constraints, and uniqueness.
final walletNameValidationProvider =
    NotifierProvider.family<WalletNameValidationNotifier, WalletNameValidationState, WalletEntity?>(
      (editingWallet) => WalletNameValidationNotifier(editingWallet),
    );

/// Notifier for wallet name validation
class WalletNameValidationNotifier extends Notifier<WalletNameValidationState> {
  WalletNameValidationNotifier(this._editingWallet);
  final WalletEntity? _editingWallet;

  @override
  WalletNameValidationState build() {
    return const WalletNameValidationState.initial();
  }

  /// Validate wallet name and update state
  ///
  /// Takes the existing wallets list for validation against duplicates.
  void validateName(String name, List<WalletEntity> existingWallets) {
    if (name.isEmpty) {
      state = const WalletNameValidationState.initial();
      return;
    }

    final isValid = WalletManagementService.isWalletNameValid(name, existingWallets, excludeWallet: _editingWallet);

    if (isValid) {
      state = const WalletNameValidationState.valid();
    } else {
      String errorMessage;
      if (name.length < 2) {
        errorMessage = 'Wallet name must be at least 2 characters';
      } else if (name.length > 39) {
        errorMessage = 'Wallet name must be 39 characters or less';
      } else if (name.contains(':')) {
        errorMessage = 'Wallet name cannot contain ":"';
      } else {
        errorMessage = 'Wallet name already exists';
      }
      state = WalletNameValidationState.invalid(errorMessage);
    }
  }

  /// Reset validation state
  void reset() {
    state = const WalletNameValidationState.initial();
  }
}
