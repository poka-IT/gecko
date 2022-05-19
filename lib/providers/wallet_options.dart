import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<NewWallet>? get badWallet => null;

  int getPinLenght(_walletNbr) {
    // TODOo: Get real Dewif lenght
    // String _localDewif;
    // if (_walletNbr is int || _walletNbr == null) {
    //   _localDewif = chestBox.get(configBox.get('currentChest')).dewif;
    // } else {
    //   _localDewif = _walletNbr;
    // }

    // final int _pinLenght = DubpRust.getDewifSecretCodeLen(
    //     dewif: _localDewif, secretCodeType: SecretCodeType.letters);

    return pinLength;
  }

  void _renameWallet(List<int?> _walletID, _newName,
      {required bool isCesium}) async {
    if (isCesium) {
      ChestData _chestTarget = chestBox.get(_walletID[0])!;
      _chestTarget.name = _newName;
      await chestBox.put(_chestTarget.key, _chestTarget);
    } else {
      MyWalletsProvider myWalletClass = MyWalletsProvider();

      WalletData _walletTarget = myWalletClass.getWalletData(_walletID)!;
      _walletTarget.name = _newName;
      await walletBox.put(_walletTarget.key, _walletTarget);
    }

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
    final bool? _answer = await (_confirmDeletingWallet(context, wallet.name));

    if (_answer!) {
      walletBox.delete(wallet.key);

      Navigator.popUntil(
        context,
        ModalRoute.withName('/mywallets'),
      );
    }
    return 0;
  }

  Future<bool?> _confirmDeletingWallet(context, _walletName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Êtes-vous sûr de vouloir supprimer le portefeuille "$_walletName" ?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Vous pourrez restaurer ce portefeuille plus tard.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Non", key: Key('cancelDeleting')),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: const Text("Oui", key: Key('confirmDeleting')),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  snackCopyKey(context) {
    const snackBar = SnackBar(
        content:
            Text("Cette clé publique a été copié dans votre presse-papier."),
        duration: Duration(seconds: 2));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String getShortPubkey(String pubkey) {
    List<int> pubkeyByte = Base58Decode(pubkey);
    Digest pubkeyS256 = sha256.convert(sha256.convert(pubkeyByte).bytes);
    String pubkeyCheksum = Base58Encode(pubkeyS256.bytes);
    String pubkeyChecksumShort = truncate(pubkeyCheksum, 3,
        omission: "", position: TruncatePosition.end);

    String pubkeyShort = truncate(pubkey, 5,
            omission: String.fromCharCode(0x2026),
            position: TruncatePosition.end) +
        truncate(pubkey, 4, omission: "", position: TruncatePosition.start) +
        ':$pubkeyChecksumShort';

    return pubkeyShort;
  }

  void bluringBalance() {
    isBalanceBlur = !isBalanceBlur;
    notifyListeners();
  }

  Future changeAvatar() async {
    File _image;
    final picker = ImagePicker();

    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      log.i(pickedFile.path);
      return _image;
    } else {
      log.w('No image selected.');
    }
  }

  void reloadBuild() {
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
