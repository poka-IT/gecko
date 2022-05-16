import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/history.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletOptions extends StatelessWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet})
      : super(key: keyMyWallets);
  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    log.d(_walletOptions.pubkey.text);

    final int _currentChest = _myWalletProvider.getCurrentChest()!;

    log.d("Wallet options: $_currentChest:${wallet.number}");

    return WillPopScope(
      onWillPop: () {
        _walletOptions.isEditing = false;
        _walletOptions.isBalanceBlur = true;
        Navigator.pop(context);
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
                Navigator.pop(context);
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
              Container(
                height: isTall ? 5 : 0,
                color: yellowC,
              ),
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
                        avatar(walletProvider),
                        const Spacer(flex: 1),
                        Column(children: <Widget>[
                          walletName(walletProvider, _walletOptions),
                          SizedBox(height: isTall ? 5 : 0),
                          balance(walletProvider),
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
              Consumer<WalletOptionsProvider>(
                  builder: (context, walletProvider, _) {
                return Column(children: [
                  pubkeyWidget(walletProvider, ctx),
                  SizedBox(height: 10 * ratio),
                  historyWidget(context, _historyProvider, walletProvider),
                  SizedBox(height: 12 * ratio),
                  setDefaultWallet(walletProvider, _myWalletProvider,
                      _walletOptions, _currentChest),
                  SizedBox(height: 17 * ratio),
                  if (!walletProvider.isDefaultWallet)
                    deleteWallet(context, walletProvider, _myWalletProvider,
                        _currentChest)
                ]);
              }),
            ]),
          ),
        ),
      ),
    );
  }

  Widget avatar(WalletOptionsProvider walletProvider) {
    return Stack(
      children: <Widget>[
        InkWell(
          onTap: () async {
            File newAvatar = await (walletProvider.changeAvatar());
            wallet.imageFile = newAvatar;
            walletProvider.reloadBuild();
          },
          child: wallet.imageFile == null
              ? Image.asset(
                  'assets/avatars/${wallet.imageName}',
                  width: 110,
                )
              : Image.file(
                  wallet.imageFile!,
                  width: 110,
                ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () async {
              File newAvatar = await (walletProvider.changeAvatar());
              wallet.imageFile = newAvatar;
              walletProvider.reloadBuild();
            },
            child: Image.asset(
              'assets/walletOptions/camera.png',
              height: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget walletName(WalletOptionsProvider walletProvider,
      WalletOptionsProvider _walletOptions) {
    bool _isNewNameValid = false;
    if (_isNewNameValid == false) {
      _walletOptions.nameController.text = wallet.name!;
    } else {
      wallet.name = _walletOptions.nameController.text;
    }

    return SizedBox(
      width: 260,
      child: Stack(children: <Widget>[
        TextField(
          key: const Key('walletName'),
          autofocus: false,
          focusNode: walletProvider.walletNameFocus,
          enabled: walletProvider.isEditing,
          controller: walletProvider.nameController,
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
          ),
        ),
        Positioned(
          right: 0,
          child: InkWell(
            key: const Key('renameWallet'),
            onTap: () async {
              _isNewNameValid =
                  walletProvider.editWalletName(wallet.id(), isCesium: false);
              await Future.delayed(const Duration(milliseconds: 30));
              walletProvider.walletNameFocus.requestFocus();
            },
            child: ClipRRect(
              child: Image.asset(
                  walletProvider.isEditing
                      ? 'assets/walletOptions/android-checkmark.png'
                      : 'assets/walletOptions/edit.png',
                  width: 20,
                  height: 20),
            ),
          ),
        ),
      ]),
    );
  }

  Widget balance(WalletOptionsProvider walletProvider) {
    return Column(children: <Widget>[
      FutureBuilder(
          future: walletProvider.getBalance(walletProvider.pubkey.text),
          builder: (BuildContext context, AsyncSnapshot<num?> _balance) {
            if (_balance.connectionState != ConnectionState.done ||
                _balance.hasError) {
              return Text('',
                  style: TextStyle(
                    fontSize: isTall ? 20 : 18,
                  ));
            }
            return ImageFiltered(
              imageFilter: ImageFilter.blur(
                  sigmaX: walletProvider.isBalanceBlur ? 6 : 0,
                  sigmaY: walletProvider.isBalanceBlur ? 5 : 0),
              child: Text(
                _balance.data.toString() + ' Ğ1',
                style: TextStyle(
                  fontSize: isTall ? 20 : 18,
                ),
              ),
            );
          }),
      const SizedBox(height: 5),
      InkWell(
        key: const Key('displayBalance'),
        onTap: () {
          walletProvider.bluringBalance();
        },
        child: Image.asset(
          walletProvider.isBalanceBlur
              ? 'assets/walletOptions/icon_oeuil.png'
              : 'assets/walletOptions/icon_oeuil_close.png',
          height: 35,
        ),
      ),
    ]);
  }

  Widget pubkeyWidget(WalletOptionsProvider walletProvider, BuildContext ctx) {
    final String shortPubkey =
        walletProvider.getShortPubkey(walletProvider.pubkey.text);
    return GestureDetector(
      key: const Key('copyPubkey'),
      onTap: () {
        Clipboard.setData(ClipboardData(text: walletProvider.pubkey.text));
        walletProvider.snackCopyKey(ctx);
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
                    ClipboardData(text: walletProvider.pubkey.text));
                walletProvider.snackCopyKey(ctx);
              },
              child: Row(children: <Widget>[
                Image.asset(
                  'assets/walletOptions/copy-white.png',
                  height: 25,
                ),
                const SizedBox(width: 7),
                Text(
                  'Copier',
                  style: TextStyle(fontSize: 15, color: Colors.grey[50]),
                )
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget historyWidget(
      BuildContext context,
      WalletsProfilesProvider _historyProvider,
      WalletOptionsProvider walletProvider) {
    return InkWell(
      key: const Key('displayHistory'),
      onTap: () {
        _historyProvider.nPage = 1;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return HistoryScreen(
                pubkey: walletProvider.pubkey.text,
                avatar: wallet.imageFile == null
                    ? Image.asset(
                        'assets/avatars/${wallet.imageName}',
                        width: 110,
                      )
                    : Image.file(
                        wallet.imageFile!,
                        width: 110,
                      ));
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
              style: TextStyle(fontSize: 20, color: Colors.black)),
        ]),
      ),
    );
  }

  Widget setDefaultWallet(
      WalletOptionsProvider walletProvider,
      MyWalletsProvider _myWalletProvider,
      WalletOptionsProvider _walletOptions,
      int _currentChest) {
    WalletData defaultWallet =
        _myWalletProvider.getDefaultWallet(_currentChest)!;

    _walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id()[1]);

    return InkWell(
      key: const Key('setDefaultWallet'),
      onTap: !walletProvider.isDefaultWallet
          ? () {
              defaultWallet = wallet;
              chestBox.get(_currentChest)!.defaultWallet = wallet.number;
              _myWalletProvider.readAllWallets(_currentChest);
              _myWalletProvider.rebuildWidget();
            }
          : null,
      child: SizedBox(
        height: 50,
        child: Row(children: <Widget>[
          const SizedBox(width: 31),
          CircleAvatar(
            backgroundColor:
                Colors.grey[walletProvider.isDefaultWallet ? 300 : 500],
            child: Image.asset(
              'assets/walletOptions/android-checkmark.png',
              height: 25,
            ),
          ),
          const SizedBox(width: 22),
          Text(
              walletProvider.isDefaultWallet
                  ? 'Ce portefeuille est celui par defaut'
                  : 'Définir comme portefeuille par défaut',
              style: TextStyle(
                  fontSize: 20,
                  color: walletProvider.isDefaultWallet
                      ? Colors.grey[500]
                      : Colors.black)),
        ]),
      ),
    );
  }

  Widget deleteWallet(
      BuildContext context,
      WalletOptionsProvider walletProvider,
      MyWalletsProvider _myWalletProvider,
      int _currentChest) {
    return InkWell(
      key: const Key('deleteWallet'),
      onTap: !walletProvider.isDefaultWallet
          ? () async {
              await walletProvider.deleteWallet(context, wallet);
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
            style: TextStyle(fontSize: 20, color: Color(0xffD80000))),
      ]),
    );
  }
}
