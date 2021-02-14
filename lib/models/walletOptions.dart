import 'dart:io';
import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sentry/sentry.dart' as sentry;
import 'package:gecko/globals.dart';

class WalletOptionsProvider with ChangeNotifier {
  TextEditingController pubkey = new TextEditingController();
  TextEditingController _newWalletName = new TextEditingController();
  bool isWalletUnlock = false;
  bool ischangedPin = false;
  TextEditingController newPin = new TextEditingController();

  Future<NewWallet> get badWallet => null;

  Future _getPubkeyFromDewif(_dewif, _pin, _pinLenght, {derivation}) async {
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
    try {
      List _pubkeysTmp = await DubpRust.getBip32DewifAccountsPublicKeys(
          dewif: _dewif, secretCode: _pin, accountsIndex: [3]);
      _pubkey = _pubkeysTmp[0];
      this.pubkey.text = _pubkey;
      notifyListeners();

      return _pubkey;
    } catch (e, stack) {
      print('Bad PIN code !');
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      notifyListeners();

      return 'false';
    }
  }

  Future readLocalWallet(
      int _walletNbr, String _name, String _pin, _pinLenght) async {
    isWalletUnlock = false;
    try {
      File _walletFile =
          File('${walletsDirectory.path}/$_walletNbr/wallet.dewif');
      String _localDewif = await _walletFile.readAsString();
      String _localPubkey;

      if ((_localPubkey =
              await _getPubkeyFromDewif(_localDewif, _pin, _pinLenght)) !=
          'false') {
        this.pubkey.text = _localPubkey;
        isWalletUnlock = true;
        notifyListeners();
        print('GET BIP32 accounts publickeys from this dewif');
        List _hdWallets = await DubpRust.getBip32DewifAccountsPublicKeys(
            dewif: _localDewif, secretCode: _pin, accountsIndex: [0, 1, 2]);
        print(_hdWallets);

        return _localDewif;
      } else {
        throw 'Bad pubkey';
      }
    } catch (e) {
      print('ERROR READING FILE: $e');
      this.pubkey.clear();
      return 'bad';
    }
  }

  int getPinLenght(_walletNbr) {
    File _walletFile =
        File('${walletsDirectory.path}/$_walletNbr/wallet.dewif');
    String _localDewif = _walletFile.readAsStringSync();

    final int _pinLenght = DubpRust.getDewifSecretCodeLen(
        dewif: _localDewif, secretCodeType: SecretCodeType.letters);

    return _pinLenght;
  }

  Future _renameWallet(_walletName, _newName) async {
    final _walletFile = Directory('${walletsDirectory.path}/$_walletName');

    try {
      _walletFile.rename('${walletsDirectory.path}/$_newName');
    } catch (e) {
      print('ERREUR lors du renommage du wallet: $e');
    }
  }

  Future<bool> renameWalletAlerte(context, _walletName) async {
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _renameWallet(_walletName, this._newWalletName.text);
                });
                // notifyListeners();
                Navigator.pop(context, true);
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> deleteWallet(context, _name) async {
    try {
      final _walletFile = Directory('${walletsDirectory.path}/$_name');
      print('DELETE THAT ?: $_walletFile');

      final bool _answer = await _confirmDeletingWallet(context, _name);

      if (_answer) {
        await _walletFile.delete(recursive: true);
        Navigator.pop(context);
      }
      return 0;
    } catch (e) {
      return 1;
    }
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
                Text(
                    'Vous pourrez restaurer ce portefeuille à tout moment grace à votre phrase de restauration.'),
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
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
