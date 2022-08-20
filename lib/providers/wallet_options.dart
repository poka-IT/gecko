// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/animated_text.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:truncate/truncate.dart';

class WalletOptionsProvider with ChangeNotifier {
  TextEditingController address = TextEditingController();
  final TextEditingController _newWalletName = TextEditingController();
  bool isWalletUnlock = false;
  bool ischangedPin = false;
  TextEditingController newPin = TextEditingController();
  bool isEditing = false;
  bool isBalanceBlur = false;
  FocusNode walletNameFocus = FocusNode();
  TextEditingController nameController = TextEditingController();
  late bool isDefaultWallet;
  bool canValidateNameBool = false;
  Map<String, String> idtyStatusCache = {};
  Future<NewWallet>? get badWallet => null;

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
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    final bool? answer = await (confirmPopup(
        context, 'areYouSureToForgetWallet'.tr(args: [wallet.name!])));

    if (answer ?? false) {
      //Check if balance is null
      final balance = await sub.getBalance(wallet.address!);
      if (balance != {}) {
        MyWalletsProvider myWalletProvider =
            Provider.of<MyWalletsProvider>(context, listen: false);
        final defaultWallet = myWalletProvider.getDefaultWallet();
        log.d(defaultWallet.address);
        sub.pay(
            fromAddress: wallet.address!,
            destAddress: defaultWallet.address!,
            amount: -1,
            password: myWalletProvider.pinCode);
      }

      await walletBox.delete(wallet.key);
      await sub.deleteAccounts([wallet.address!]);

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

  Widget idtyStatus(BuildContext context, String address,
      {bool isOwner = false, Color color = Colors.black}) {
    DuniterIndexer duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    _showText(String text,
        [double size = 18, bool bold = false, bool smooth = true]) {
      log.d('$address $text');
      return AnimatedFadeOutIn<String>(
        data: text,
        duration: Duration(milliseconds: smooth ? 200 : 0),
        builder: (value) => Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: size,
              color: bold ? color : Colors.black,
              fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
        ),
      );
    }

    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus(address),
          initialData: '',
          builder: (context, snapshot) {
            idtyStatusCache[address] = snapshot.data.toString();
            switch (snapshot.data.toString()) {
              case 'noid':
                {
                  return _showText('noIdentity'.tr());
                }
              case 'Created':
                {
                  return _showText('identityCreated'.tr());
                }
              case 'ConfirmedByOwner':
                {
                  return isOwner
                      ? _showText('identityConfirmed'.tr())
                      : duniterIndexer.getNameByAddress(
                          context,
                          address,
                          null,
                          20,
                          true,
                          Colors.grey[700]!,
                          FontWeight.w500,
                          FontStyle.italic);
                }

              case 'Validated':
                {
                  return isOwner
                      ? _showText('memberValidated'.tr(), 18, true)
                      : duniterIndexer.getNameByAddress(
                          context,
                          address,
                          null,
                          20,
                          true,
                          Colors.black,
                          FontWeight.w600,
                          FontStyle.normal);
                }

              case 'expired':
                {
                  return _showText('identityExpired'.tr());
                }
            }
            return SizedBox(
              child: _showText('', 18, false, false),
            );
          });
    });
  }

  Future<bool> isMember(BuildContext context, String address) async {
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    return await sub.idtyStatus(address) == 'Validated';
  }

  Future<String?> confirmIdentityPopup(BuildContext context) async {
    TextEditingController idtyName = TextEditingController();
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

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
                onChanged: (_) => notifyListeners(),
                inputFormatters: <TextInputFormatter>[
                  // FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                  FilteringTextInputFormatter.deny(RegExp(r'^ ')),
                  // FilteringTextInputFormatter.deny(RegExp(r' $')),
                ],
                textAlign: TextAlign.center,
                autofocus: true,
                controller: idtyName,
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
                    key: const Key('infoPopup'),
                    child: Text(
                      "validate".tr(),
                      style: TextStyle(
                        fontSize: 21,
                        color: idtyName.text.length.clamp(3, 64) ==
                                idtyName.text.length
                            ? const Color(0xffD80000)
                            : Colors.grey,
                      ),
                    ),
                    onPressed: () async {
                      idtyName.text = idtyName.text.trim().replaceAll('  ', '');

                      if (idtyName.text.length.clamp(3, 64) ==
                          idtyName.text.length) {
                        WalletData? defaultWallet =
                            myWalletProvider.getDefaultWallet();

                        String? pin;
                        if (myWalletProvider.pinCode == '') {
                          pin = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (homeContext) {
                                return UnlockingWallet(wallet: defaultWallet);
                              },
                            ),
                          );
                        }
                        if (pin != null || myWalletProvider.pinCode != '') {
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
                                fromAddress: getShortPubkey(wallet.address!),
                                toAddress: getShortPubkey(wallet.address!),
                              );
                            }),
                          );
                        }
                      }
                    },
                  );
                })
              ],
            ),
            const SizedBox(height: 20)
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
                    key: const Key('infoPopup'),
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
                        // notifyListeners();
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
                  key: const Key('cancel'),
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
    MyWalletsProvider myWalletProvider =
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

  void reloadBuild() {
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
        addressGet = value.address!;
        return;
      }
    });

    address.text = addressGet ?? '';

    return addressGet;
  }

  Widget walletNameController(BuildContext context, WalletData wallet,
      [double size = 20]) {
    nameController.text = wallet.name!;

    return SizedBox(
      width: 260,
      child: Stack(children: <Widget>[
        TextField(
          key: const Key('walletName'),
          autofocus: false,
          focusNode: walletNameFocus,
          enabled: isEditing,
          controller: nameController,
          minLines: 1,
          maxLines: 3,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.all(15.0),
          ),
          style: TextStyle(
            fontSize: isTall ? size : size * 0.9,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
        Positioned(
          right: 0,
          child: InkWell(
            key: const Key('renameWallet'),
            onTap: () async {
              // _isNewNameValid =
              // walletProvider.editWalletName(wallet.id(), isCesium: false);
              await editWalletName(context, wallet.id());
              await Future.delayed(const Duration(milliseconds: 30));
              walletNameFocus.requestFocus();
            },
            child: ClipRRect(
              child: Image.asset(
                  isEditing
                      ? 'assets/walletOptions/android-checkmark.png'
                      : 'assets/walletOptions/edit.png',
                  width: 25,
                  height: 25),
            ),
          ),
        ),
      ]),
    );
  }

  Widget walletName(BuildContext context, WalletData wallet,
      [double size = 20, Color color = Colors.black]) {
    double newSize = wallet.name!.length <= 15 ? size : size - 2;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Text(
        truncate(wallet.name!, 20),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTall ? newSize : newSize * 0.9,
          color: color,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ]);
  }
}

Map<String, double> balanceCache = {};

Widget balance(BuildContext context, String address, double size,
    [Color color = Colors.black,
    Color loadingColor = const Color(0xffd07316)]) {
  return Column(children: <Widget>[
    Consumer<SubstrateSdk>(builder: (context, sdk, _) {
      return FutureBuilder(
          future: sdk.getBalance(address),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, double>> globalBalance) {
            if (globalBalance.connectionState != ConnectionState.done ||
                globalBalance.hasError) {
              if (balanceCache[address] != null &&
                  balanceCache[address] != -1) {
                return Text(
                    "${balanceCache[address]!.toString()} $currencyName",
                    style: TextStyle(
                        fontSize: isTall ? size : size * 0.9, color: color));
              } else {
                return SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    color: loadingColor,
                    strokeWidth: 2,
                  ),
                );
              }
            }
            balanceCache[address] = globalBalance.data!['transferableBalance']!;
            if (balanceCache[address] != -1) {
              return Text(
                "${balanceCache[address]!.toString()} $currencyName",
                style: TextStyle(
                  fontSize: isTall ? size : size * 0.9,
                  color: color,
                ),
              );
            } else {
              return const Text('');
            }
          });
    }),
  ]);
}

Widget getCerts(BuildContext context, String address, double size,
    [Color color = Colors.black]) {
  return Column(children: <Widget>[
    Consumer<SubstrateSdk>(builder: (context, sdk, _) {
      return FutureBuilder(
          future: sdk.getCerts(address),
          builder: (BuildContext context, AsyncSnapshot<List<int>> certs) {
            // log.d(_certs.data);

            return certs.data?[0] != 0 && certs.data != null
                ? Row(
                    children: [
                      Image.asset('assets/medal.png', height: 20),
                      const SizedBox(width: 1),
                      Text(certs.data?[0].toString() ?? '0',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 5),
                      Text(
                        "(${certs.data?[1].toString() ?? '0'})",
                        style: const TextStyle(fontSize: 14),
                      )
                    ],
                  )
                : const Text('');
          });
    }),
  ]);
}
