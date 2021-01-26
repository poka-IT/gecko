import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ConfirmStoreWallet extends StatelessWidget with ChangeNotifier {
  ConfirmStoreWallet({
    Key validationKey,
    @required this.generatedMnemonic,
    @required generatedWallet,
  }) : super(key: validationKey);

  String generatedMnemonic;

  // @override
  // void dispose() {
  //   _wordFocus.dispose();
  //   _walletNameFocus.dispose();
  //   super.dispose();
  // }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _inputRestoreWord = new TextEditingController();
  TextEditingController walletName = new TextEditingController();
  FocusNode _wordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    var _generateWalletProvider = Provider.of<GenerateWalletsProvider>(context);

    this._mnemonicController.text = generatedMnemonic;
    this._pubkey.text = _generateWalletProvider.generatedWallet.publicKey;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: SizedBox(
        height: 22,
        child: Text('Confirmez ce portefeuille'),
      )),
      body: Center(
        child: Column(children: <Widget>[
          SizedBox(height: 15),
          Text(
            'Votre clé publique est :',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          TextField(
              enabled: false,
              controller: this._pubkey,
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(
            'Quel est le ${_generateWalletProvider.nbrWord + 1}ème mot de votre phrase de restauration ?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          TextFormField(
              focusNode: _wordFocus,
              autofocus: true,
              enabled: !_generateWalletProvider.isAskedWordValid,
              controller: this._inputRestoreWord,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                _generateWalletProvider.checkAskedWord(
                    value, _mnemonicController.text);
              },
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 30.0,
                  color: _generateWalletProvider.askedWordColor,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 12),
          Text(
            'Choisissez un nom pour votre portefeuille :',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          TextFormField(
              focusNode: _generateWalletProvider.walletNameFocus,
              // autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp('[A-Za-z|0-9|\\-|_| ]')),
              ],
              // enabled: isAskedWordValid,
              controller: this.walletName,
              textInputAction: TextInputAction.next,
              onChanged: (v) {
                _generateWalletProvider.nameChanged();
              },
              maxLines: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w500)),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 12,
                          primary: Colors
                              .green[400], //Color(0xffFFD68E), // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed: (_generateWalletProvider.isAskedWordValid &&
                                this.walletName.text != '')
                            ? () => _generateWalletProvider.storeWallet(
                                walletName.text, _pubkey.text, context)
                            : null,
                        child:
                            Text('Confirmer', style: TextStyle(fontSize: 28))),
                  ))),
          SizedBox(height: 70),
          Text('TRICHE PENDANT ALPHA: ' + this._mnemonicController.text,
              style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.black,
                  fontWeight: FontWeight.normal)),
        ]),
      ),
    );
  }
}
