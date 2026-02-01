import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_name_validation_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/wallet_management_service.dart';

/// Service for showing wallet name editing dialogs
///
/// This service provides a consistent wallet name editing dialog
/// with validation using Riverpod providers.
class WalletNameDialogService {
  /// Show wallet name editing dialog
  ///
  /// Returns the new wallet name if successfully renamed, null if cancelled.
  static Future<String?> showEditWalletNameDialog(BuildContext context, WalletEntity wallet) async {
    final walletName = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ProviderScope(
          child: _WalletNameEditDialog(wallet: wallet, walletNameController: walletName),
        );
      },
    );

    return result;
  }
}

/// Internal dialog widget for wallet name editing
class _WalletNameEditDialog extends ConsumerStatefulWidget {
  final WalletEntity wallet;
  final TextEditingController walletNameController;

  const _WalletNameEditDialog({required this.wallet, required this.walletNameController});

  @override
  ConsumerState<_WalletNameEditDialog> createState() => _WalletNameEditDialogState();
}

class _WalletNameEditDialogState extends ConsumerState<_WalletNameEditDialog> {
  @override
  Widget build(BuildContext context) {
    final validationState = ref.watch(walletNameValidationProvider(widget.wallet));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_rounded, color: context.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'chooseWalletName'.tr(),
              style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Text field
            TextField(
              onChanged: (value) => _validateName(value),
              textAlign: TextAlign.center,
              autofocus: true,
              controller: widget.walletNameController,
              style: scaledTextStyle(fontSize: 16),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'enterWalletName'.tr(),
                hintStyle: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                errorText: validationState.errorMessage,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    key: keyCancel,
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "cancel".tr(),
                      style: scaledTextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Validate button
                Expanded(
                  child: ElevatedButton(
                    key: keyInfoPopup,
                    onPressed: validationState.isValid
                        ? () async {
                            try {
                              await WalletManagementService.renameWallet(
                                widget.wallet,
                                widget.walletNameController.text,
                                ref: ref,
                              );
                              if (context.mounted) {
                                Navigator.pop(context, widget.walletNameController.text);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error renaming wallet: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: validationState.isValid ? context.colorScheme.primary : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("validate".tr(), style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _validateName(String name) {
    // Get existing wallets from Riverpod provider for validation
    final existingWallets = ref.read(walletsListProvider).wallets;

    ref.read(walletNameValidationProvider(widget.wallet).notifier).validateName(name, existingWallets);
  }
}
