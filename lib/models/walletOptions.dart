import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dubp/dubp.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:truncate/truncate.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class WalletOptionsProvider with ChangeNotifier {
  TextEditingController pubkey = TextEditingController();
  TextEditingController _newWalletName = TextEditingController();
  bool isWalletUnlock = false;
  bool ischangedPin = false;
  TextEditingController newPin = new TextEditingController();
  bool isEditing = false;
  bool isBalanceBlur = true;
  FocusNode walletNameFocus = FocusNode();
  TextEditingController nameController = TextEditingController();
  String walletID;

  Future<NewWallet> get badWallet => null;

  Future _getPubkeyFromDewif(
      String _dewif, _pin, int _pinLenght, int derivation) async {
    String _pubkey;
    RegExp regExp = new RegExp(
      r'^[A-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(_pin) == true && _pin.length == _pinLenght) {
      print("Le format du code PIN est correct.");
    } else {
      print('Format de code PIN invalide');
      return 'false';
    }
    if (derivation != -1) {
      try {
        List _pubkeysTmp = await DubpRust.getBip32DewifAccountsPublicKeys(
            dewif: _dewif, secretCode: _pin, accountsIndex: [derivation]);
        _pubkey = _pubkeysTmp[0];
        this.pubkey.text = _pubkey;
        notifyListeners();

        return _pubkey;
      } catch (e) {
        print('Bad PIN code !');
        print(e);
        notifyListeners();

        return 'false';
      }
    } else {
      try {
        _pubkey = await DubpRust.getDewifPublicKey(dewif: _dewif, pin: _pin);
        this.pubkey.text = _pubkey;
        notifyListeners();
        return _pubkey;
      } catch (e) {
        print('Bad PIN code !');
        print(e);
        notifyListeners();

        return 'false';
      }
    }
  }

  Future readLocalWallet(
      int _walletNbr, String _pin, int _pinLenght, int derivation) async {
    isWalletUnlock = false;
    try {
      File _walletFile = File('${walletsDirectory.path}/0/wallet.dewif');
      String _localDewif = await _walletFile.readAsString();
      String _localPubkey;

      if ((_localPubkey = await _getPubkeyFromDewif(
              _localDewif, _pin, _pinLenght, derivation)) !=
          'false') {
        this.pubkey.text = _localPubkey;
        isWalletUnlock = true;
        // notifyListeners();

        return _localDewif;
      } else {
        throw 'Bad pubkey';
      }
    } catch (e) {
      print('ERROR READING FILE: $e');
      this.pubkey.clear();
      // notifyListeners();
      return 'bad';
    }
  }

  Future checkPinOK(String _createdDewif, String _pin, int _pinLenght) async {
    isWalletUnlock = false;
    try {
      if (await _getPubkeyFromDewif(_createdDewif, _pin, _pinLenght, 3) !=
          'false') {
        return true;
      } else {
        throw false;
      }
    } catch (e) {
      print('ERROR READING FILE: $e');
      return false;
    }
  }

  int getPinLenght(_walletNbr) {
    String _localDewif;
    if (_walletNbr is int) {
      File _walletFile = File('${walletsDirectory.path}/0/wallet.dewif');
      _localDewif = _walletFile.readAsStringSync();
    } else {
      _localDewif = _walletNbr;
    }

    final int _pinLenght = DubpRust.getDewifSecretCodeLen(
        dewif: _localDewif, secretCodeType: SecretCodeType.letters);

    return _pinLenght;
  }

  Future _renameWallet(_walletID, _newName) async {
    final _walletConfig = File('${walletsDirectory.path}/0/list.conf');

    String newConfig =
        await _walletConfig.readAsLines().then((List<String> lines) {
      int nbrLines = lines.length;
      // print(lines);
      // print(nbrLines);
      // int _index = lines.indexOf('0:$_walletNbr:$_walletName:$_derivation');
      if (nbrLines != 1) {
        for (String wLine in lines) {
          String wID = "${wLine.split(':')[0]}:${wLine.split(':')[1]}";
          print(
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
          print(wLine);
          String deri = wLine.split(':')[3];
          print("($wID == $_walletID ???");
          if (wID == _walletID) {
            lines.remove(wLine);
            lines.add('$_walletID:$_newName:$deri');
            // return '$_walletID:$_newName:$deri';
            print('OOUUUUUUUIIIIIIIIIIIIIIIIIII');
          }
        }
        // lines.removeWhere((element) =>
        //     '${element.split(':')[0]}:${element.split(':')[1]}' == _walletID);
        // lines.add('$_walletID:$_newName:$deri');
        return lines.join('\n');
      } else {
        return 'true';
      }
    });

    await _walletConfig.delete();
    await _walletConfig.writeAsString(newConfig);
    _newWalletName.text = '';
  }

  Future<bool> renameWalletAlerte(
      context, _walletName, _walletNbr, _derivation) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez un nouveau nom pour ce portefeuille'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                    controller: this._newWalletName,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(),
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Valider"),
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // await _renameWallet(_walletName, this._newWalletName.text,
                  //     _walletNbr, _derivation);
                });
                // notifyListeners();
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> editWalletName(_wID) async {
    bool nameState;
    if (isEditing) {
      if (!nameController.text.contains(':') &&
          nameController.text.length <= 45) {
        await _renameWallet(_wID, nameController.text);
        nameState = true;
      } else {
        nameState = false;
      }
    } else {
      walletNameFocus.requestFocus();
      nameState = true;
    }

    isEditing ? isEditing = false : isEditing = true;
    notifyListeners();
    return nameState;
  }

  Future<int> deleteWallet(context, _walletNbr, _name, _derivation) async {
    final bool _answer = await _confirmDeletingWallet(context, _name);

    if (_answer) {
      final _walletConfig = File('${walletsDirectory.path}/0/list.conf');

      if (_derivation != -1) {
        String newConfig =
            await _walletConfig.readAsLines().then((List<String> lines) {
          lines.removeWhere((element) =>
              element.contains('0:$_walletNbr:$_name:$_derivation'));

          return lines.join('\n');
        });

        await _walletConfig.delete();
        await _walletConfig.writeAsString(newConfig);
      } else {
        final _walletFile = Directory('${walletsDirectory.path}/$_walletNbr');
        await _walletFile.delete(recursive: true);
      }
      Navigator.popUntil(
        context,
        ModalRoute.withName('/mywallets'),
      );
    }
    return 0;
  }

  Future<bool> _confirmDeletingWallet(context, _walletName) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Êtes-vous sûr de vouloir supprimer le portefeuille "$_walletName" ?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vous pourrez restaurer ce portefeuille plus tard.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Non"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text("Oui"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<NewWallet> changePin(_name, _oldPin) async {
    try {
      final _walletFile = Directory('${walletsDirectory.path}/$_name');
      final _dewif =
          File(_walletFile.path + '/wallet.dewif').readAsLinesSync()[0];

      NewWallet newWalletFile = await DubpRust.changeDewifPin(
        dewif: _dewif,
        oldPin: _oldPin,
      );

      newPin.text = newWalletFile.pin;
      ischangedPin = true;
      // notifyListeners();
      return newWalletFile;
    } catch (e) {
      print('Impossible de changer le code PIN.');
      return badWallet;
    }
  }

  Future storeWallet(context, _name, _newWalletFile) async {
    final Directory walletNameDirectory =
        Directory('${walletsDirectory.path}/$_name');
    final walletFile = File('${walletNameDirectory.path}/wallet.dewif');
    print(_newWalletFile);

    walletFile.writeAsString('${_newWalletFile.dewif}');
    Navigator.pop(context);
    return _name;
  }

  snackCopyKey(context) {
    final snackBar = SnackBar(
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

  Future<Uint8List> generateQRcode(String _pubkey) async {
    return await scanner.generateBarCode(_pubkey);
  }

  void reloadBuild() {
    notifyListeners();
  }
}
