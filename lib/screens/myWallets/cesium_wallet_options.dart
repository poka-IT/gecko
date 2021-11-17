import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/chest_provider.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/models/wallet_options.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

int _nbrLinesName = 1;
bool _isNewNameValid = false;

Widget cesiumWalletOptions(BuildContext context, ChestData cesiumWallet) {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  WalletOptionsProvider _walletOptions =
      Provider.of<WalletOptionsProvider>(context);
  ChestProvider _chestProvider = Provider.of<ChestProvider>(context);
  HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);

  final String shortPubkey =
      _walletOptions.getShortPubkey(_walletOptions.pubkey.text);

  if (_walletOptions.nameController.text == null || _isNewNameValid == false) {
    _walletOptions.nameController.text = cesiumWallet.name;
  } else {
    cesiumWallet.name = _walletOptions.nameController.text;
  }

  _walletOptions.nameController.text.length >= 15
      ? _nbrLinesName = 2
      : _nbrLinesName = 1;
  if (_walletOptions.nameController.text.length >= 26 && isTall) {
    _nbrLinesName = 3;
  }

  return Scaffold(
    resizeToAvoidBottomInset: false,
    body: Builder(
      builder: (ctx) => SafeArea(
        child: Column(children: <Widget>[
          Container(
            height: isTall ? 30 : 15,
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
                      cesiumWallet.imageFile = newAvatar;
                    }
                    _walletOptions.reloadBuild();
                  },
                  child: cesiumWallet.imageFile == null
                      ? Image.asset(
                          'assets/chests/${cesiumWallet.imageName}',
                          width: 110,
                        )
                      : Image.file(cesiumWallet.imageFile, width: 110),
                ),
                InkWell(
                    onTap: () async {
                      File newAvatar = await _walletOptions.changeAvatar();
                      if (newAvatar != null) {
                        cesiumWallet.imageFile = newAvatar;
                      }
                      _walletOptions.reloadBuild();
                    },
                    child: Column(children: <Widget>[
                      Image.asset(
                        'assets/walletOptions/camera.png',
                      ),
                      const SizedBox(height: 100)
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
                            int wBalanceG1 = result.data['balance']['amount'];
                            int currentUD = result.data['currentUd']['amount'];
                            double wBalanceUDBrut =
                                wBalanceG1 / currentUD; // .toString();
                            wBalanceUD = double.parse(
                                    (wBalanceUDBrut).toStringAsFixed(2))
                                .toString();
                          }
                          return Row(children: <Widget>[
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                  sigmaX: _walletOptions.isBalanceBlur ? 6 : 0,
                                  sigmaY: _walletOptions.isBalanceBlur ? 5 : 0),
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
                          )),
                    ]),
                    const SizedBox(width: 0),
                    Column(children: <Widget>[
                      InkWell(
                          key: const Key('renameWallet'),
                          onTap: () async {
                            _isNewNameValid = _walletOptions.editWalletName(
                                [cesiumWallet.key, 0],
                                isCesium: cesiumWallet.isCesium);
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
              future: _walletOptions.generateQRcode(_walletOptions.pubkey.text),
              builder: (context, snapshot) {
                return snapshot.data != null
                    ? Image.memory(snapshot.data, height: isTall ? 300 : 270)
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
                    ),
                    const SizedBox(width: 10),
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
                              Clipboard.setData(ClipboardData(
                                  text: _walletOptions.pubkey.text));
                              _walletOptions.snackCopyKey(ctx);
                            },
                            child: Row(children: <Widget>[
                              Image.asset(
                                'assets/walletOptions/copy-white.png',
                              ),
                              const SizedBox(width: 7),
                              Text('Copier',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey[50]))
                            ]))),
                  ]))),
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
                    ),
                    const SizedBox(width: 12),
                    const Text('Historique des transactions',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                  ]))),
          SizedBox(height: 12 * ratio),
          InkWell(
              key: const Key('deleteWallet'),
              onTap: () async {
                await _chestProvider.deleteChest(context, cesiumWallet);
              },
              child: Row(children: <Widget>[
                const SizedBox(width: 33),
                Image.asset(
                  'assets/walletOptions/trash.png',
                ),
                const SizedBox(width: 14),
                const Text('Supprimer ce coffre',
                    style: TextStyle(fontSize: 20, color: Color(0xffD80000))),
              ])),
        ]),
      ),
    ),
  );
}
