import 'package:durt2/durt2.dart';
import 'package:flutter_riverpod/legacy.dart';
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
    StateNotifierProvider.family<WalletNameValidationNotifier, WalletNameValidationState, WalletEntity?>(
      (ref, editingWallet) => WalletNameValidationNotifier(editingWallet),
    );

/// Notifier for wallet name validation
class WalletNameValidationNotifier extends StateNotifier<WalletNameValidationState> {
  final WalletEntity? _editingWallet;

  WalletNameValidationNotifier(this._editingWallet) : super(const WalletNameValidationState.initial());

  /// Validate wallet name and update state
  ///
  /// Requires context to access MyWalletsProvider for existing wallets list.
  /// This is a temporary solution until MyWalletsProvider is migrated to Riverpod.
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
