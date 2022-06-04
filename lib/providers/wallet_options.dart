import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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

  Future<NewWallet>? get badWallet => null;

  int getPinLenght(_walletNbr) {
    return pinLength;
  }

  void _renameWallet(List<int?> _walletID, String _newName,
      {required bool isCesium}) async {
    MyWalletsProvider myWalletClass = MyWalletsProvider();

    WalletData _walletTarget = myWalletClass.getWalletDataById(_walletID)!;
    _walletTarget.name = _newName;
    await walletBox.put(_walletTarget.key, _walletTarget);

    _newWalletName.text = '';
  }

  bool editWalletName(List<int?> _wID, {bool? isCesium}) {
    bool nameState;
    if (isEditing) {
      if (!nameController.text.contains(':') &&
          nameController.text.length <= 39) {
        _renameWallet(_wID, nameController.text, isCesium: isCesium!);
        nameState = true;
      } else {
        nameState = false;
      }
    } else {
      nameState = true;
    }

    isEditing ? isEditing = false : isEditing = true;
    notifyListeners();
    return nameState;
  }

  Future<int> deleteWallet(context, WalletData wallet) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    final bool? _answer = await (confirmPopup(context,
        'Êtes-vous sûr de vouloir oublier le portefeuille "${wallet.name}" ?'));

    if (_answer ?? false) {
      await walletBox.delete(wallet.key);
      await _sub.deleteAccounts([wallet.address!]);

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

      final newPath = "${imageDirectory.path}/${pickedFile.name}";

      await imageFile.copy(newPath);
      // final File newImage = File(newPath);

      // await newImage.writeAsBytes(await pickedFile.readAsBytes());
      // await pickedFile.saveTo(newPath);
      // await Future.delayed(const Duration(milliseconds: 100));

      log.i(newPath);
      return newPath;
    } else {
      log.w('No image selected.');
      return '';
    }
  }

  Widget idtyStatus(BuildContext context, String address,
      {bool isOwner = false}) {
    _showText(String text, [double size = 18, bool _bold = false]) => Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: size,
              color: _bold ? orangeC : Colors.black,
              fontWeight: _bold ? FontWeight.w500 : FontWeight.w400),
        );

    return Consumer<SubstrateSdk>(builder: (context, _sub, _) {
      return FutureBuilder(
          future: _sub.idtyStatus(address),
          initialData: '...',
          builder: (context, snapshot) {
            switch (snapshot.data.toString()) {
              case 'noid':
                {
                  return _showText('Aucune identité');
                }
              case 'Created':
                {
                  return isOwner
                      ? InkWell(
                          child: _showText(
                              'Cliquez ici pour confirmer\nvotre nouvelle identité',
                              18,
                              true),
                          onTap: () async {
                            await validateIdentity(context);
                          },
                        )
                      : _showText('Identité créé');
                }
              case 'ConfirmedByOwner':
                {
                  return _showText('Identité confirmé');
                }

              case 'Validated':
                {
                  return _showText('Membre validé !');
                }

              case 'expired':
                {
                  return _showText('Identité expiré');
                }
            }
            return SizedBox(
              child: _showText('Statut inconnu'),
            );
          });
    });
  }

  Future<String?> validateIdentity(BuildContext context) async {
    TextEditingController idtyName = TextEditingController();
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    return showDialog<String>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmez votre identité',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          content: SizedBox(
            height: 100,
            child: Column(children: [
              const SizedBox(height: 20),
              const Text(
                'Nom:',
                style: TextStyle(fontSize: 19),
              ),
              TextField(
                onChanged: (_) => notifyListeners(),
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
                    builder: (context, _wOptions, _) {
                  return TextButton(
                    key: const Key('infoPopup'),
                    child: Text(
                      "Valider",
                      style: TextStyle(
                        fontSize: 21,
                        color: idtyName.text.length >= 2
                            ? const Color(0xffD80000)
                            : Colors.grey,
                      ),
                    ),
                    onPressed: () async {
                      if (idtyName.text.length >= 2) {
                        final _wallet = _myWalletProvider
                            .getWalletDataByAddress(address.text);
                        await _sub.setCurrentWallet(_wallet!);
                        _sub.confirmIdentity(_walletOptions.address.text,
                            idtyName.text, _myWalletProvider.pinCode);
                        Navigator.pop(context);
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

  void reloadBuild() {
    notifyListeners();
  }

  Future changePinCacheChoice() async {
    bool isCacheChecked = configBox.get('isCacheChecked') ?? false;
    await configBox.put('isCacheChecked', !isCacheChecked);
    notifyListeners();
  }

  String? getAddress(int chest, int derivation) {
    String? _address;
    walletBox.toMap().forEach((key, value) {
      if (value.chest == chest && value.derivation == derivation) {
        _address = value.address!;
        return;
      }
    });

    address.text = _address ?? '';

    return _address;
  }
}

Map<String, String> balanceCache = {};

Widget balance(BuildContext context, String address, double size,
    [Color _color = Colors.black]) {
  return Column(children: <Widget>[
    Consumer<SubstrateSdk>(builder: (context, _sdk, _) {
      return FutureBuilder(
          future: _sdk.getBalance(address),
          builder: (BuildContext context, AsyncSnapshot<num?> _balance) {
            if (_balance.connectionState != ConnectionState.done ||
                _balance.hasError) {
              if (balanceCache[address] != null) {
                return Text(balanceCache[address]!,
                    style: TextStyle(
                        fontSize: isTall ? size : size * 0.9, color: _color));
              } else {
                return SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    color: orangeC,
                    strokeWidth: 2,
                  ),
                );
              }
            }
            balanceCache[address] = "${_balance.data.toString()} $currencyName";
            return Text(
              balanceCache[address]!,
              style: TextStyle(
                fontSize: isTall ? size : size * 0.9,
                color: _color,
              ),
            );
          });
    }),
  ]);
}

Widget getCerts(BuildContext context, String address, double size,
    [Color _color = Colors.black]) {
  return Column(children: <Widget>[
    Consumer<SubstrateSdk>(builder: (context, _sdk, _) {
      return FutureBuilder(
          future: _sdk.getCerts(address),
          builder: (BuildContext context, AsyncSnapshot<List<int>> _certs) {
            // log.d(_certs.data);

            return _certs.data?[0] != 0
                ? Row(
                    children: [
                      Image.asset('assets/medal.png', height: 20),
                      const SizedBox(width: 1),
                      Text(_certs.data?[0].toString() ?? '0',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 5),
                      Text(
                        "(${_certs.data?[1].toString() ?? '0'})",
                        style: const TextStyle(fontSize: 14),
                      )
                    ],
                  )
                : const Text('');
          });
    }),
  ]);
}
