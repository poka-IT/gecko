// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/trm_data_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';

class WalletOptionsProvider with ChangeNotifier {
  late ProviderContainer _container;

  WalletOptionsProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  final address = TextEditingController();
  bool isDefaultWallet = false;
  bool _canValidateName = false;

  void _renameWallet(WalletEntity wallet, String newName, {required bool isCesium}) async {
    wallet.name = newName;
    _container.read(walletServiceProvider).walletBox.put(wallet);
  }

  Future<int> deleteWallet(BuildContext context, WalletEntity wallet) async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();

    final walletBalance = await _container.read(storageServiceProvider).getBalance(wallet.address);

    // Show confirmation dialog with transfer details
    String confirmationMessage;
    if (walletBalance.transferableBalance > BigInt.zero) {
      confirmationMessage = 'areYouSureToForgetWalletWithBalance'.tr(
        args: [
          wallet.name!,
          '${(walletBalance.transferableBalance.toDouble() / 100).toStringAsFixed(2)} ${Durt.i.network.symbol}',
          defaultWallet.name ?? 'defaultWallet'.tr(),
        ],
      );
    } else {
      confirmationMessage = 'areYouSureToForgetWallet'.tr(args: [wallet.name!]);
    }

    final answer = await showConfirmationDialog(
      context: context,
      message: confirmationMessage,
      type: ConfirmationDialogType.warning,
    );

    if (!answer) return 0;

    // If wallet has balance, transfer funds first
    if (walletBalance.transferableBalance > BigInt.zero) {
      if (!await myWalletProvider.askPinCode()) return 0;

      // Show loading dialog while transaction is processing
      showConfirmationDialog(
        context: context,
        message: 'transferringFundsToDefaultWallet'.tr(args: [defaultWallet.name ?? 'defaultWallet'.tr()]),
        type: ConfirmationDialogType.info,
        customIcon: const CircularProgressIndicator(),
        barrierDismissible: false,
        hideCancelButton: true,
        hideConfirmButton: true,
      );

      final keypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromAddress(address: wallet.address, pinCode: myWalletProvider.pinCode);

      final container = ProviderContainer();
      final displayMode = container.read(currencyDisplayModeProvider);
      final isUdUnit = displayMode == CurrencyDisplayMode.du;
      container.dispose();
      final transactionStatus = _container
          .read(duniterServiceProvider)
          .pay(
            keypair: keypair,
            destAddress: defaultWallet.address,
            amount: -1,
            comment: 'ĞECKO:DELETEWALLET',
            isUd: isUdUnit,
          );

      // Wait for transaction completion and check if successful
      bool transactionSuccessful = false;
      String? errorMessage;

      await for (final status in transactionStatus) {
        switch (status.state) {
          case TransactionState.finalized || TransactionState.inBlock:
            transactionSuccessful = true;
            break;
          case TransactionState.error || TransactionState.timeout || TransactionState.none:
            errorMessage = status.errorMessage ?? 'unknownError'.tr();
            break;
          case TransactionState.pending || TransactionState.futureNonce:
            continue;
        }
        // Exit the loop once we have a final state (success or error)
        break;
      }

      // Close loading dialog
      Navigator.pop(context);

      if (!transactionSuccessful) {
        // Show error dialog
        await showConfirmationDialog(
          context: context,
          message: 'transactionFailedWalletNotDeleted'.tr(args: [errorMessage!]),
          type: ConfirmationDialogType.error,
        );
        return 1; // Return error code
      }
    }

    // Delete wallet files and data only if transaction was successful or wallet was empty
    if (wallet.imagePath != null) {
      final avatarFile = File(wallet.imagePath!);
      if (await avatarFile.exists()) {
        await avatarFile.delete();
      }
    }

    // Delete from database
    await _container.read(walletServiceProvider).deleteWallet(wallet.address);

    // Navigate back
    Navigator.pop(context);
    return 0;
  }

  Future<String> changeAvatar() async {
    // final datapod = Provider.of<V2sDatapodProvider>(homeContext, listen: false);

    final picker = ImagePicker();

    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (!await avatarsDirectory.exists()) {
        log.e("Image folder doesn't exist");
        return '';
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            hideBottomControls: true,
            toolbarTitle: 'cropImage'.tr(),
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.deepOrange,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'cropImage'.tr(),
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [CropAspectRatioPreset.square],
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      final avatarUuid = const Uuid().v4();
      final newPath = "${avatarsDirectory.path}/${address.text}-$avatarUuid";

      if (croppedFile == null) {
        log.w('No image selected.');
        return '';
      }

      await File(croppedFile.path).rename(newPath);

      final walletData = MyWalletsProvider().getWalletDataByAddress(address.text);

      if (walletData!.imagePath != null) {
        final avatarFile = File(walletData.imagePath!);
        if (await avatarFile.exists()) {
          await avatarFile.delete();
        }
      }

      walletData.imagePath = newPath;

      await _container.read(walletServiceProvider).walletBox.putAsync(walletData);
      notifyListeners();

      // Notify MyWalletsProvider to update UI components that depend on wallet data
      old_provider.Provider.of<MyWalletsProvider>(homeContext, listen: false).reload();
      // datapod.setAvatar(address.text, newPath);

      return newPath;
    } else {
      log.w('No image selected.');
      return '';
    }
  }

  Future<String?> editWalletName(BuildContext context, WalletEntity wallet) async {
    final walletName = TextEditingController();
    _canValidateName = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
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
                  onChanged: (_) => canValidateName(context, walletName),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  controller: walletName,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'enterWalletName'.tr(),
                    hintStyle: scaledTextStyle(
                      fontSize: 16,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
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
                      child: old_provider.Consumer<WalletOptionsProvider>(
                        builder: (context, wOptions, _) {
                          return ElevatedButton(
                            key: keyInfoPopup,
                            onPressed: _canValidateName
                                ? () async {
                                    _renameWallet(wallet, walletName.text, isCesium: false);
                                    Navigator.pop(context, walletName.text);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canValidateName ? context.colorScheme.primary : Colors.grey,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "validate".tr(),
                              style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }

  bool canValidateName(BuildContext context, final walletName) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    bool isNameValid = walletName.text.length >= 2 && !walletName.text.contains(':') && walletName.text.length <= 39;

    if (isNameValid) {
      for (var wallet in myWalletProvider.listWallets) {
        if (walletName.text == wallet.name!) {
          _canValidateName = false;
          break;
        }
        _canValidateName = true;
      }
    } else {
      _canValidateName = false;
    }
    notifyListeners();
    return _canValidateName;
  }

  void reload() {
    notifyListeners();
  }

  Future changePinCacheChoice() async {
    bool isCacheChecked = configBox.get('isCacheChecked') ?? false;
    await configBox.put('isCacheChecked', !isCacheChecked);
    notifyListeners();
  }
}
