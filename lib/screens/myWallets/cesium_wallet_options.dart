import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/queries.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/history.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

bool _isNewNameValid = false;

class CesiumWalletOptions extends StatelessWidget {
  const CesiumWalletOptions(
      {Key? key, Key? keyMyWallets, required this.cesiumWallet})
      : super(key: key);

  final ChestData cesiumWallet;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    ChestProvider _chestProvider =
        Provider.of<ChestProvider>(context, listen: false);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final String shortPubkey =
        _walletOptions.getShortPubkey(_walletOptions.pubkey.text);

    if (_isNewNameValid == false) {
      _walletOptions.nameController.text = cesiumWallet.name!;
    } else {
      cesiumWallet.name = _walletOptions.nameController.text;
    }

    return WillPopScope(
      onWillPop: () {
        _walletOptions.isEditing = false;
        _walletOptions.isBalanceBlur = true;
        Navigator.popUntil(
          context,
          ModalRoute.withName('/'),
        );
        return Future<bool>.value(true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                _walletOptions.isEditing = false;
                _walletOptions.isBalanceBlur = true;
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              }),
          title: SizedBox(
            height: 22,
            child: Consumer<WalletOptionsProvider>(
                builder: (context, walletProvider, _) {
              return Text(_walletOptions.nameController.text);
            }),
          ),
        ),
        body: Builder(
          builder: (ctx) => SafeArea(
            child: Column(children: <Widget>[
              Consumer<WalletOptionsProvider>(
                  builder: (context, walletProvider, _) {
                return Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      yellowC,
                      const Color(0xfffafafa),
                    ],
                  )),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        const Spacer(flex: 1),
                        InkWell(
                          onTap: () async {
                            File newAvatar =
                                await (_walletOptions.changeAvatar());
                            cesiumWallet.imageFile = newAvatar;
                            _walletOptions.reloadBuild();
                          },
                          child: cesiumWallet.imageFile == null
                              ? Image.asset(
                                  'assets/chests/${cesiumWallet.imageName}',
                                  width: 110,
                                )
                              : Image.file(cesiumWallet.imageFile!, width: 110),
                        ),
                        InkWell(
                            onTap: () async {
                              File newAvatar =
                                  await (_walletOptions.changeAvatar());
                              cesiumWallet.imageFile = newAvatar;
                              _walletOptions.reloadBuild();
                            },
                            child: Column(children: <Widget>[
                              Image.asset(
                                'assets/walletOptions/camera.png',
                                height: 40,
                              ),
                              const SizedBox(height: 80)
                            ])),
                        const Spacer(flex: 1),
                        Column(children: <Widget>[
                          SizedBox(
                            width: 260,
                            child: TextField(
                                key: const Key('walletName'),
                                autofocus: false,
                                focusNode: _walletOptions.walletNameFocus,
                                enabled: _walletOptions.isEditing,
                                controller: _walletOptions.nameController,
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
                                  fontSize: isTall ? 27 : 23,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                )),
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
                                {VoidCallback? refetch, FetchMore? fetchMore}) {
                              if (result.hasException) {
                                return Text(result.exception.toString());
                              }

                              if (result.isLoading) {
                                return const Text('Loading');
                              }

                              // List repositories = result.data['viewer']['repositories']['nodes'];
                              String wBalanceUD;
                              if (result.data!['balance'] == null) {
                                wBalanceUD = '0.0';
                              } else {
                                int wBalanceG1 =
                                    result.data!['balance']['amount'];
                                int currentUD =
                                    result.data!['currentUd']['amount'];
                                double wBalanceUDBrut =
                                    wBalanceG1 / currentUD; // .toString();
                                wBalanceUD = double.parse(
                                        (wBalanceUDBrut).toStringAsFixed(2))
                                    .toString();
                              }
                              return Row(children: <Widget>[
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                      sigmaX: _walletOptions.isBalanceBlur
                                          ? 6
                                          : 0.001,
                                      sigmaY: _walletOptions.isBalanceBlur
                                          ? 5
                                          : 0.001),
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
                        ]),
                        const Spacer(flex: 3),
                      ]),
                );
              }),
              SizedBox(height: 4 * ratio),
              QrImageWidget(
                data: _walletOptions.pubkey.text,
                version: QrVersions.auto,
                size: isTall ? 300 : 270,
              ),
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
                                  Clipboard.setData(ClipboardData(
                                      text: _walletOptions.pubkey.text));
                                  _walletOptions.snackCopyKey(ctx);
                                },
                                child: Row(children: <Widget>[
                                  Image.asset(
                                    'assets/walletOptions/copy-white.png',
                                    height: 25,
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
                    _historyProvider.nPage = 1;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return HistoryScreen(
                            pubkey: _walletOptions.pubkey.text);
                      }),
                    );
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
                            style:
                                TextStyle(fontSize: 20, color: Colors.black)),
                      ]))),
              SizedBox(height: 7 * ratio),
              InkWell(
                key: const Key('changePin'),
                onTap: () async {
                  // await _chestProvider.changePin(context, cesiumWallet);
                  String? newPin = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ChangePinScreen(
                          walletName: cesiumWallet.name,
                          walletProvider: _myWalletProvider,
                        );
                      },
                    ),
                  );

                  if (newPin != null) _myWalletProvider.pinCode = newPin;
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 31),
                    Image.asset(
                      'assets/chests/secret_code.png',
                      height: 24,
                    ),
                    const SizedBox(width: 20),
                    const Text('Changer mon code secret',
                        style: TextStyle(fontSize: 20, color: Colors.black)),
                  ]),
                ),
              ),
              SizedBox(height: 7 * ratio),
              InkWell(
                key: const Key('deleteWallet'),
                onTap: () async {
                  await _chestProvider.deleteChest(context, cesiumWallet);
                },
                child: SizedBox(
                  height: 50,
                  child: Row(children: <Widget>[
                    const SizedBox(width: 33),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: 45,
                    ),
                    const SizedBox(width: 21),
                    const Text(
                      'Supprimer ce coffre',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xffD80000),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
