// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:durt2/durt2.dart' show Durt, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
// import 'package:gecko/providers/v2s_datapod.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';

class WalletOptionsProvider with ChangeNotifier {
  final address = TextEditingController();
  final _newWalletName = TextEditingController();
  bool isWalletUnlock = false;
  bool ischangedPin = false;
  final newPin = TextEditingController();
  bool isEditing = false;
  final nameController = TextEditingController();
  bool isDefaultWallet = false;
  bool canValidateNameBool = false;
  Map<String, BigInt> balanceCache = {};

  int getPinLenght() {
    return pinLength;
  }

  void _renameWallet(String address, String newName, {required bool isCesium}) async {
    MyWalletsProvider myWalletClass = MyWalletsProvider();

    WalletData walletTarget = myWalletClass.getWalletDataByAddress(address)!;
    walletTarget.name = newName;
    await Durt.i.wallets.walletDataBox.put(walletTarget.address, walletTarget);

    _newWalletName.text = '';
  }

  Future<int> deleteWallet(BuildContext context, WalletData wallet) async {
    // final datapod = Provider.of<V2sDatapodProvider>(context, listen: false);
    final answer = await showConfirmationDialog(
      context: context,
      message: 'areYouSureToForgetWallet'.tr(args: [wallet.name!]),
      type: ConfirmationDialogType.warning,
    );

    if (answer) {
      //Check if balance is null
      if (balanceCache[wallet.address] != BigInt.zero) {
        final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
        final defaultWallet = myWalletProvider.getDefaultWallet();
        final keypair = await Durt.i.wallets.getKeyPairFromAddress(
          address: wallet.address,
          pinCode: myWalletProvider.pinCode,
        );
        Durt.i.duniter.pay(
          keypair: keypair,
          destAddress: defaultWallet.address,
          amount: -1,
          comment: 'ĞECKO:DELETEWALLET',
        );
      }

      if (wallet.imagePath != null) {
        final avatarFile = File(wallet.imagePath!);
        if (await avatarFile.exists()) {
          await avatarFile.delete();
        }
      }

      // datapod.deleteProfile(address: wallet.address);
      await Durt.i.wallets.deleteWallet(wallet.address);

      Navigator.pop(context);
    }
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
            toolbarTitle: 'Personnalisation',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Cropper',
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [CropAspectRatioPreset.square],
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
        await avatarFile.delete();
      }

      walletData.imagePath = newPath;

      await Durt.i.wallets.walletDataBox.put(address.text, walletData);
      notifyListeners();
      // datapod.setAvatar(address.text, newPath);

      return newPath;
    } else {
      log.w('No image selected.');
      return '';
    }
  }

  Future<String?> confirmIdentityPopup(BuildContext context) async {
    final idtyName = TextEditingController();
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    bool canValidate = false;
    bool idtyExist = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'confirmYourIdentity'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          content: SizedBox(
            height: 100,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextField(
                  key: keyEnterIdentityUsername,
                  onChanged: (_) async {
                    idtyExist = await duniterIndexer.isIdtyExist(idtyName.text);
                    canValidate =
                        !idtyExist &&
                        !await duniterIndexer.isIdtyExist(idtyName.text) &&
                        idtyName.text.length >= 2 &&
                        idtyName.text.length <= 32;

                    notifyListeners();
                  },
                  inputFormatters: <TextInputFormatter>[
                    // FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                    FilteringTextInputFormatter.deny(RegExp(r'^ ')),
                    // FilteringTextInputFormatter.deny(RegExp(r' $')),
                  ],
                  textAlign: TextAlign.center,
                  autofocus: true,
                  controller: idtyName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Consumer<WalletOptionsProvider>(
                  builder: (context, wOptions, _) {
                    return Text(
                      idtyExist ? "thisIdentityAlreadyExist".tr() : '',
                      style: TextStyle(color: Colors.red[500]),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<WalletOptionsProvider>(
                  builder: (context, wOptions, _) {
                    return TextButton(
                      key: keyConfirm,
                      onPressed: canValidate
                          ? () async {
                              idtyName.text = idtyName.text.trim().replaceAll('  ', '');

                              if (idtyName.text.length.clamp(3, 32) != idtyName.text.length) {
                                return;
                              }

                              if (!await myWalletProvider.askPinCode()) return;

                              final wallet = myWalletProvider.getWalletDataByAddress(address.text);
                              await Durt.i.wallets.setDefaultAddress(wallet!.address);
                              final keypair = await Durt.i.wallets.getKeyPairFromAddress(
                                address: wallet.address,
                                pinCode: myWalletProvider.pinCode,
                              );
                              final transactionStatus = Durt.i.duniter.confirmIdentity(
                                keypair: keypair,
                                name: idtyName.text,
                              );
                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return TransactionInProgressScreen(
                                      transactionStatus: transactionStatus,
                                      transType: 'comfirmIdty',
                                      fromAddress: getShortPubkey(wallet.address),
                                      toAddress: getShortPubkey(wallet.address),
                                    );
                                  },
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        "validate".tr(),
                        style: TextStyle(fontSize: 20, color: canValidate ? const Color(0xffD80000) : Colors.grey[500]),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        );
      },
    );
  }

  Future<String?> editWalletName(BuildContext context, String address) async {
    final walletName = TextEditingController();
    canValidateNameBool = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'chooseWalletName'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
          ),
          content: SizedBox(
            height: 100,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextField(
                  onChanged: (_) => canValidateName(context, walletName),
                  textAlign: TextAlign.center,
                  autofocus: true,
                  controller: walletName,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<WalletOptionsProvider>(
                  builder: (context, wOptions, _) {
                    return TextButton(
                      key: keyInfoPopup,
                      child: Text(
                        "validate".tr(),
                        style: TextStyle(
                          fontSize: 20,
                          color: canValidateNameBool ? const Color(0xffD80000) : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        if (canValidateNameBool) {
                          nameController.text = walletName.text;
                          _renameWallet(address, walletName.text, isCesium: false);
                          notifyListeners();
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: keyCancel,
                  child: Text(
                    "cancel".tr(),
                    style: TextStyle(fontSize: 17, color: Colors.grey[800], fontWeight: FontWeight.w300),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  bool canValidateName(BuildContext context, final walletName) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    bool isNameValid = walletName.text.length >= 2 && !walletName.text.contains(':') && walletName.text.length <= 39;

    if (isNameValid) {
      for (var wallet in myWalletProvider.listWallets) {
        if (walletName.text == wallet.name!) {
          canValidateNameBool = false;
          break;
        }
        canValidateNameBool = true;
      }
    } else {
      canValidateNameBool = false;
    }
    notifyListeners();
    return canValidateNameBool;
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
