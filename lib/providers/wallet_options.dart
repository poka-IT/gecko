// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';

class WalletOptionsProvider with ChangeNotifier {
  TextEditingController address = TextEditingController();
  final TextEditingController _newWalletName = TextEditingController();
  bool isWalletUnlock = false;
  bool ischangedPin = false;
  TextEditingController newPin = TextEditingController();
  bool isEditing = false;
  bool isBalanceBlur = false;
  TextEditingController nameController = TextEditingController();
  late bool isDefaultWallet;
  bool canValidateNameBool = false;
  Future<NewWallet>? get badWallet => null;
  Map<String, double> balanceCache = {};

  int getPinLenght(walletNbr) {
    return pinLength;
  }

  void _renameWallet(List<int?> walletID, String newName,
      {required bool isCesium}) async {
    MyWalletsProvider myWalletClass = MyWalletsProvider();

    WalletData walletTarget = myWalletClass.getWalletDataById(walletID)!;
    walletTarget.name = newName;
    await walletBox.put(walletTarget.key, walletTarget);

    _newWalletName.text = '';
  }

  Future<int> deleteWallet(context, WalletData wallet) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final bool? answer = await (confirmPopup(
        context, 'areYouSureToForgetWallet'.tr(args: [wallet.name!])));

    if (answer ?? false) {
      //Check if balance is null
      final balance = await sub.getBalance(wallet.address);
      if (balance != {}) {
        final myWalletProvider =
            Provider.of<MyWalletsProvider>(context, listen: false);
        final defaultWallet = myWalletProvider.getDefaultWallet();
        log.d(defaultWallet.address);
        sub.pay(
            fromAddress: wallet.address,
            destAddress: defaultWallet.address,
            amount: -1,
            password: myWalletProvider.pinCode);
      }

      await walletBox.delete(wallet.key);
      await sub.deleteAccounts([wallet.address]);

      Navigator.pop(context);
    }
    return 0;
  }

  void bluringBalance() {
    isBalanceBlur = !isBalanceBlur;
    notifyListeners();
  }

  Future<String> changeAvatar() async {
    // File _image;
    final picker = ImagePicker();

    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (!await imageDirectory.exists()) {
        log.e("Image folder doesn't exist");
        return '';
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        cropStyle: CropStyle.circle,
        uiSettings: [
          AndroidUiSettings(
              hideBottomControls: true,
              toolbarTitle: 'Personnalisation',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );

      final newPath = "${imageDirectory.path}/${pickedFile.name}";

      if (croppedFile != null) {
        await File(croppedFile.path).rename(newPath);
      } else {
        log.w('No image selected.');
        return '';
      }
      // await imageFile.copy(newPath);

      log.i(newPath);
      return newPath;
    } else {
      log.w('No image selected.');
      return '';
    }
  }

  Future<String?> confirmIdentityPopup(BuildContext context) async {
    TextEditingController idtyName = TextEditingController();
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    bool canValidate = false;
    bool idtyExist = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'confirmYourIdentity'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          content: SizedBox(
            height: 100,
            child: Column(children: [
              const SizedBox(height: 20),
              TextField(
                key: keyEnterIdentityUsername,
                onChanged: (_) async {
                  idtyExist = await isIdtyExist(idtyName.text);
                  canValidate = !idtyExist &&
                      !await isIdtyExist(idtyName.text) &&
                      idtyName.text.length >= 2 &&
                      idtyName.text.length <= 32;
                  log.d('aaaaaaaaaa: $canValidate');

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
                style: const TextStyle(fontSize: 19),
              ),
              const SizedBox(height: 10),
              Consumer<WalletOptionsProvider>(builder: (context, wOptions, _) {
                return Text(idtyExist ? 'Cette identité existe déjà' : '',
                    style: TextStyle(color: Colors.red[500]));
              })
            ]),
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
                            idtyName.text =
                                idtyName.text.trim().replaceAll('  ', '');

                            if (idtyName.text.length.clamp(3, 32) ==
                                idtyName.text.length) {
                              WalletData? defaultWallet =
                                  myWalletProvider.getDefaultWallet();

                              String? pin;
                              if (myWalletProvider.pinCode == '') {
                                pin = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (homeContext) {
                                      return UnlockingWallet(
                                          wallet: defaultWallet);
                                    },
                                  ),
                                );
                              }
                              if (pin != null ||
                                  myWalletProvider.pinCode != '') {
                                final wallet = myWalletProvider
                                    .getWalletDataByAddress(address.text);
                                await sub.setCurrentWallet(wallet!);
                                sub.confirmIdentity(walletOptions.address.text,
                                    idtyName.text, myWalletProvider.pinCode);
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return TransactionInProgress(
                                      transType: 'comfirmIdty',
                                      fromAddress:
                                          getShortPubkey(wallet.address),
                                      toAddress: getShortPubkey(wallet.address),
                                    );
                                  }),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      "validate".tr(),
                      style: TextStyle(
                          fontSize: 21,
                          color: canValidate
                              ? const Color(0xffD80000)
                              : Colors.grey[500]),
                    ),
                  );
                })
              ],
            ),
            const SizedBox(height: 5)
          ],
        );
      },
    );
  }

  Future<String?> editWalletName(BuildContext context, List<int?> wID) async {
    TextEditingController walletName = TextEditingController();
    canValidateNameBool = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'chooseWalletName'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          content: SizedBox(
            height: 100,
            child: Column(children: [
              const SizedBox(height: 20),
              TextField(
                onChanged: (_) => canValidateName(context, walletName),
                textAlign: TextAlign.center,
                autofocus: true,
                controller: walletName,
                style: const TextStyle(fontSize: 19),
              )
            ]),
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
                        fontSize: 21,
                        color: canValidateNameBool
                            ? const Color(0xffD80000)
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      if (canValidateNameBool) {
                        nameController.text = walletName.text;
                        _renameWallet(wID, walletName.text, isCesium: false);
                        notifyListeners();
                        Navigator.pop(context);
                      }
                    },
                  );
                })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  key: keyCancel,
                  child: Text(
                    "cancel".tr(),
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w300),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
            const SizedBox(height: 20)
          ],
        );
      },
    );
  }

  bool canValidateName(BuildContext context, TextEditingController walletName) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    bool isNameValid = walletName.text.length >= 2 &&
        !walletName.text.contains(':') &&
        walletName.text.length <= 39;

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

  String? getAddress(int chest, int derivation) {
    String? addressGet;
    walletBox.toMap().forEach((key, value) {
      if (value.chest == chest && value.derivation == derivation) {
        addressGet = value.address;
        return;
      }
    });

    address.text = addressGet ?? '';

    return addressGet;
  }
}
