import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/wallet_options.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class WalletOptions extends StatelessWidget {
  WalletOptions({Key keyMyWallets, @required this.wallet})
      : super(key: keyMyWallets);
  WalletData wallet;
  int _nbrLinesName = 1;
  bool _isNewNameValid = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);

    final int _currentChest = _myWalletProvider.getCurrentChest();
    final String shortPubkey =
        _walletOptions.getShortPubkey(_walletOptions.pubkey.text);

    if (_walletOptions.nameController.text == null ||
        _isNewNameValid == false) {
      _walletOptions.nameController.text = wallet.name;
    } else {
      wallet.name = _walletOptions.nameController.text;
    }

    _walletOptions.nameController.text.length >= 15
        ? _nbrLinesName = 2
        : _nbrLinesName = 1;
    if (_walletOptions.nameController.text.length >= 26 && isTall) {
      _nbrLinesName = 3;
    }

    WalletData defaultWallet =
        _myWalletProvider.getDefaultWallet(_currentChest);

    _walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id()[1]);

    int currentChest = _myWalletProvider.getCurrentChest();

    log.d("Wallet options: $currentChest:${wallet.number}");

    return WillPopScope(
      onWillPop: () {
        _walletOptions.isEditing = false;
        _walletOptions.isBalanceBlur = true;
        Navigator.popUntil(
          context,
          ModalRoute.withName('/mywallets'),
        );
        return Future<bool>.value(true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _walletOptions.isEditing = false;
                  _walletOptions.isBalanceBlur = true;
                  Navigator.popUntil(
                    context,
                    ModalRoute.withName('/mywallets'),
                  );
                }),
            title: SizedBox(
              height: 22,
              child: Text(_walletOptions.nameController.text),
            )),
        body: Builder(
          builder: (ctx) => SafeArea(
            child: Column(children: <Widget>[
              Container(
                height: isTall ? 15 : 0,
                color: yellowC,
              ),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      yellowC,
                      const Color(0xfffafafa),
                    ],
                  )),
                  child: Row(children: <Widget>[
                    const SizedBox(width: 25),
                    InkWell(
                        onTap: () async {
                          File newAvatar = await _walletOptions.changeAvatar();
                          if (newAvatar != null) {
                            wallet.imageFile = newAvatar;
                          }
                          _walletOptions.reloadBuild();
                        },
                        child: wallet.imageFile == null
                            ? Image.asset(
                                'assets/avatars/${wallet.imageName}',
                                width: 110,
                              )
                            : Image.file(
                                wallet.imageFile,
                                width: 110,
                              )),
                    InkWell(
                        onTap: () async {
                          File newAvatar = await _walletOptions.changeAvatar();
                          if (newAvatar != null) {
                            wallet.imageFile = newAvatar;
                          }
                          _walletOptions.reloadBuild();
                        },
                        child: Column(children: <Widget>[
                          Image.asset(
                            'assets/walletOptions/camera.png',
                            height: 40,
                          ),
                          const SizedBox(height: 80)
                        ])),
                    Column(children: <Widget>[
                      Row(children: <Widget>[
                        Column(children: <Widget>[
                          SizedBox(
                            width: 260,
                            child: TextField(
                                key: const Key('walletName'),
                                autofocus: false,
                                focusNode: _walletOptions.walletNameFocus,
                                enabled: _walletOptions.isEditing,
                                controller: _walletOptions.nameController,
                                maxLines: _nbrLinesName,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.all(15.0),
                                ),
                                style: TextStyle(
                                    fontSize: isTall ? 27 : 23,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Monospace')),
                          ),
                          SizedBox(height: isTall ? 5 : 0),
                          Query(
                            options: QueryOptions(
                              document: gql(getBalance),
                              variables: {
                                'pubkey': _walletOptions.pubkey.text,
                              },
                              // pollInterval: Duration(seconds: 1),
                            ),
                            builder: (QueryResult result,
                                {VoidCallback refetch, FetchMore fetchMore}) {
                              if (result.hasException) {
                                return Text(result.exception.toString());
                              }

                              if (result.isLoading) {
                                return const Text('Loading');
                              }

                              // List repositories = result.data['viewer']['repositories']['nodes'];
                              String wBalanceUD;
                              if (result.data['balance'] == null) {
                                wBalanceUD = '0.0';
                              } else {
                                int wBalanceG1 =
                                    result.data['balance']['amount'];
                                int currentUD =
                                    result.data['currentUd']['amount'];
                                double wBalanceUDBrut =
                                    wBalanceG1 / currentUD; // .toString();
                                wBalanceUD = double.parse(
                                        (wBalanceUDBrut).toStringAsFixed(2))
                                    .toString();
                              }
                              return Row(children: <Widget>[
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                      sigmaX:
                                          _walletOptions.isBalanceBlur ? 6 : 0,
                                      sigmaY:
                                          _walletOptions.isBalanceBlur ? 5 : 0),
                                  child: Text(wBalanceUD,
                                      style: TextStyle(
                                          fontSize: isTall ? 20 : 18,
                                          color: Colors.black)),
                                ),
                                Text(' DU',
                                    style: TextStyle(
                                        fontSize: isTall ? 20 : 18,
                                        color: Colors.black))
                              ]);

                              // Text(
                              //   '$wBalanceUD DU',
                              //   style: TextStyle(
                              //       fontSize: 20, color: Colors.black),
                              // );
                            },
                          ),
                          const SizedBox(height: 5),
                          InkWell(
                            key: const Key('displayBalance'),
                            onTap: () {
                              _walletOptions.bluringBalance();
                            },
                            child: Image.asset(
                              _walletOptions.isBalanceBlur
                                  ? 'assets/walletOptions/icon_oeuil.png'
                                  : 'assets/walletOptions/icon_oeuil_close.png',
                              height: 35,
                            ),
                          ),
                        ]),
                        const SizedBox(width: 0),
                        Column(children: <Widget>[
                          InkWell(
                              key: const Key('renameWallet'),
                              onTap: () async {
                                _isNewNameValid = _walletOptions.editWalletName(
                                    wallet.id(),
                                    isCesium: false);
                                await Future.delayed(
                                    const Duration(milliseconds: 30));
                                _walletOptions.walletNameFocus.requestFocus();
                              },
                              child: ClipRRect(
                                child: Image.asset(
                                    _walletOptions.isEditing
                                        ? 'assets/walletOptions/android-checkmark.png'
                                        : 'assets/walletOptions/edit.png',
                                    width: 20,
                                    height: 20),
                              )),
                          const SizedBox(
                            height: 60,
                          )
                        ])
                      ]),
                    ]),
                  ])),
              SizedBox(height: 4 * ratio),
              FutureBuilder(
                  future:
                      _walletOptions.generateQRcode(_walletOptions.pubkey.text),
                  builder: (context, snapshot) {
                    return snapshot.data != null
                        ? Image.memory(snapshot.data,
                            height: isTall ? 300 : 270)
                        : const Text('-', style: TextStyle(fontSize: 20));
                  }),
              SizedBox(height: 15 * ratio),
              GestureDetector(
                key: const Key('copyPubkey'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: _walletOptions.pubkey.text));
                  _walletOptions.snackCopyKey(ctx);
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 30),
                    Image.asset(
                      'assets/walletOptions/key.png',
                      height: 45,
                    ),
                    const SizedBox(width: 20),
                    Text("${shortPubkey.split(':')[0]}:",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Monospace',
                            color: Colors.black)),
                    Text(shortPubkey.split(':')[1],
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Monospace')),
                    const SizedBox(width: 15),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 1,
                          primary: orangeC, // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _walletOptions.pubkey.text));
                          _walletOptions.snackCopyKey(ctx);
                        },
                        child: Row(children: <Widget>[
                          Image.asset(
                            'assets/walletOptions/copy-white.png',
                            height: 25,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Copier',
                            style:
                                TextStyle(fontSize: 15, color: Colors.grey[50]),
                          )
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 10 * ratio),
              InkWell(
                key: const Key('displayHistory'),
                onTap: () {
                  _historyProvider.isPubkey(ctx, _walletOptions.pubkey.text,
                      goHistory: true);
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 30),
                    Image.asset(
                      'assets/walletOptions/clock.png',
                      height: 45,
                    ),
                    const SizedBox(width: 22),
                    const Text('Historique des transactions',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                  ]),
                ),
              ),
              SizedBox(height: 12 * ratio),
              InkWell(
                key: const Key('setDefaultWallet'),
                onTap: !_walletOptions.isDefaultWallet
                    ? () {
                        defaultWallet = wallet;
                        chestBox.get(currentChest).defaultWallet =
                            wallet.number;
                        _myWalletProvider.readAllWallets(_currentChest);
                        _myWalletProvider.rebuildWidget();
                      }
                    : null,
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 31),
                    CircleAvatar(
                      backgroundColor: Colors
                          .grey[_walletOptions.isDefaultWallet ? 300 : 500],
                      child: Image.asset(
                        'assets/walletOptions/android-checkmark.png',
                        height: 25,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Text(
                        _walletOptions.isDefaultWallet
                            ? 'Ce portefeuille est celui par defaut'
                            : 'Définir comme portefeuille par défaut',
                        style: TextStyle(
                            fontSize: 20,
                            color: _walletOptions.isDefaultWallet
                                ? Colors.grey[500]
                                : Colors.black)),
                  ]),
                ),
              ),
              SizedBox(height: 17 * ratio),
              if (!_walletOptions.isDefaultWallet)
                InkWell(
                  key: const Key('deleteWallet'),
                  onTap: !_walletOptions.isDefaultWallet
                      ? () async {
                          await _walletOptions.deleteWallet(context, wallet);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _myWalletProvider.listWallets =
                                _myWalletProvider.readAllWallets(_currentChest);
                            _myWalletProvider.rebuildWidget();
                          });
                        }
                      : null,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 30),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: 45,
                    ),
                    const SizedBox(width: 19),
                    const Text('Supprimer ce portefeuille',
                        style:
                            TextStyle(fontSize: 20, color: Color(0xffD80000))),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
