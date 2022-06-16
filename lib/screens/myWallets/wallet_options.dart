import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
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
        Provider.of<MyWalletsProvider>(context, listen: false);
    HomeProvider _homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    DuniterIndexer _duniterIndexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    log.d(_walletOptions.address.text);

    final int _currentChest = _myWalletProvider.getCurrentChest();

    // final currentWallet = _myWalletProvider.getDefaultWallet();
    // log.d(_walletOptions.getAddress(_currentChest, 3));
    log.d("Wallet options: $_currentChest:${wallet.derivation}");

    return WillPopScope(
      onWillPop: () {
        _walletOptions.isEditing = false;
        _walletOptions.isBalanceBlur = false;
        _myWalletProvider.rebuildWidget();
        Navigator.pop(context);
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                _walletOptions.isEditing = false;
                _walletOptions.isBalanceBlur = false;
                _myWalletProvider.rebuildWidget();
                Navigator.pop(context);
              }),
          title: SizedBox(
            height: 22,
            child: Consumer<WalletOptionsProvider>(
                builder: (context, walletProvider, _) {
              return Text(wallet.name!);
            }),
          ),
        ),
        bottomNavigationBar: _homeProvider.bottomAppBar(context),
        body: Stack(children: [
          Builder(
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
                        backgroundColor,
                      ],
                    )),
                    child: Row(
                        // mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          const Spacer(flex: 1),
                          avatar(walletProvider),
                          const Spacer(flex: 1),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                _duniterIndexer.getNameByAddress(
                                    context,
                                    walletProvider.address.text,
                                    wallet,
                                    27,
                                    false,
                                    Colors.black,
                                    FontWeight.w400,
                                    FontStyle.normal),
                                // SizedBox(height: isTall ? 5 : 0),

                                SizedBox(height: isTall ? 5 : 0),
                                balance(
                                    context, walletProvider.address.text, 21),
                                const SizedBox(width: 30),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _walletOptions.idtyStatus(
                                          context, _walletOptions.address.text,
                                          isOwner: true, color: orangeC),
                                      getCerts(context,
                                          walletProvider.address.text, 15),
                                    ]),
                                SizedBox(height: 10 * ratio),
                              ]),
                          const Spacer(flex: 2),
                        ]),
                  );
                }),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return QrCodeFullscreen(
                                    _walletOptions.address.text,
                                  );
                                }),
                              );
                            },
                            child: QrImageWidget(
                              data: _walletOptions.address.text,
                              version: QrVersions.auto,
                              size: isTall ? 150 : 80,
                            ),
                          ),
                          SizedBox(height: 15 * ratio),
                          Consumer<WalletOptionsProvider>(
                              builder: (context, walletProvider, _) {
                            return Column(children: [
                              pubkeyWidget(walletProvider, ctx),
                              SizedBox(height: 10 * ratio),
                              activityWidget(
                                  context, _historyProvider, walletProvider),
                              SizedBox(height: 12 * ratio),
                              setDefaultWalletWidget(
                                  context,
                                  walletProvider,
                                  _myWalletProvider,
                                  _walletOptions,
                                  _currentChest),
                              SizedBox(height: 17 * ratio),
                              // walletProvider.isMember(context, _walletOptions.address.text)
                              FutureBuilder(
                                  future: walletProvider.isMember(
                                      context, _walletOptions.address.text),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<bool> _isMember) {
                                    if (_isMember.connectionState !=
                                            ConnectionState.done ||
                                        _isMember.hasError) {
                                      return const Text('');
                                    }
                                    return Column(children: [
                                      if (!walletProvider.isDefaultWallet &&
                                          !_isMember.data!)
                                        deleteWallet(context, walletProvider,
                                            _currentChest)
                                      else
                                        const SizedBox(),
                                      if (_isMember.data!)
                                        manageMemberStatus(context)
                                    ]);
                                  }),
                            ]);
                          }),
                        ]),
                  ),
                ),
              ]),
            ),
          ),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }

  Widget avatar(WalletOptionsProvider walletProvider) {
    return Stack(
      children: <Widget>[
        InkWell(
          onTap: () async {
            final _newPath = await (walletProvider.changeAvatar());
            if (_newPath != '') {
              wallet.imageCustomPath = _newPath;
              walletBox.put(wallet.key, wallet);
            }
            walletProvider.reloadBuild();
          },
          child: wallet.imageCustomPath == null || wallet.imageCustomPath == ''
              ? Image.asset(
                  'assets/avatars/${wallet.imageDefaultPath}',
                  width: 110,
                )
              : Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(
                        File(wallet.imageCustomPath!),
                      ),
                    ),
                  ),
                ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () async {
              wallet.imageCustomPath = await (walletProvider.changeAvatar());
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

  Widget pubkeyWidget(WalletOptionsProvider walletProvider, BuildContext ctx) {
    final String shortPubkey = getShortPubkey(walletProvider.address.text);
    return GestureDetector(
      key: const Key('copyPubkey'),
      onTap: () {
        Clipboard.setData(ClipboardData(text: walletProvider.address.text));
        snackCopyKey(ctx);
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
          Text(shortPubkey,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Monospace',
                  color: Colors.black)),
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
                    ClipboardData(text: walletProvider.address.text));
                snackCopyKey(ctx);
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

  Widget activityWidget(
      BuildContext context,
      WalletsProfilesProvider _historyProvider,
      WalletOptionsProvider walletProvider) {
    return InkWell(
      key: const Key('displayActivity'),
      onTap: () {
        // _historyProvider.nPage = 1;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ActivityScreen(
                address: walletProvider.address.text,
                avatar: wallet.imageCustomPath == null
                    ? Image.asset(
                        'assets/avatars/${wallet.imageDefaultPath}',
                        width: 110,
                      )
                    : Image.asset(
                        wallet.imageCustomPath!,
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
          const Text('Activité',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget manageMemberStatus(BuildContext context) {
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    return InkWell(
      key: const Key('manageStatus'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ManageMembership(
              address: _walletOptions.address.text,
            );
          }),
        );
      },
      child: SizedBox(
        height: 40,
        child: Row(children: <Widget>[
          const SizedBox(width: 32),
          Image.asset(
            'assets/medal.png',
            height: 45,
          ),
          const SizedBox(width: 22),
          const Text('Gérer mon adhésion', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Widget setDefaultWalletWidget(
      BuildContext context,
      WalletOptionsProvider walletProvider,
      MyWalletsProvider _myWalletProvider,
      WalletOptionsProvider _walletOptions,
      int _currentChest) {
    return Consumer<MyWalletsProvider>(
        builder: (context, _myWalletProvider, _) {
      WalletData defaultWallet = _myWalletProvider.getDefaultWallet();
      _walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id()[1]);
      return InkWell(
        key: const Key('setDefaultWallet'),
        onTap: !walletProvider.isDefaultWallet
            ? () async {
                await setDefaultWallet(context, _currentChest);
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
    });
  }

  Future setDefaultWallet(BuildContext context, int _currentChest) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    // WalletData defaultWallet = _myWalletProvider.getDefaultWallet()!;
    // defaultWallet = wallet;
    await _sub.setCurrentWallet(wallet);
    _myWalletProvider.readAllWallets(_currentChest);
    _myWalletProvider.rebuildWidget();
  }

  Widget deleteWallet(BuildContext context,
      WalletOptionsProvider walletProvider, int _currentChest) {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final _defaultWallet = _myWalletProvider.getDefaultWallet();
    final bool isDefaultWallet =
        walletProvider.address.text == _defaultWallet.address;
    // return Consumer<MyWalletsProvider>(
    //     builder: (context, _myWalletProvider, _) {
    return FutureBuilder(
        future: _sub.hasAccountConsumers(wallet.address!),
        builder: (BuildContext context, AsyncSnapshot<bool> _hasConsumers) {
          if (_hasConsumers.connectionState != ConnectionState.done ||
              _hasConsumers.hasError) {
            return const Text('');
          }
          final double _balance =
              balanceCache[walletProvider.address.text] ?? -1;
          final bool canDelete = !isDefaultWallet &&
              !_hasConsumers.data! &&
              (_balance > 2 || _balance == 0);
          return InkWell(
            key: const Key('deleteWallet'),
            onTap: canDelete
                ? () async {
                    await walletProvider.deleteWallet(context, wallet);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _myWalletProvider.listWallets =
                          _myWalletProvider.readAllWallets(_currentChest);
                      _myWalletProvider.rebuildWidget();
                    });
                  }
                : null,
            child: canDelete
                ? Row(children: <Widget>[
                    const SizedBox(width: 30),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: 45,
                    ),
                    const SizedBox(width: 19),
                    const Text('Supprimer ce portefeuille',
                        style:
                            TextStyle(fontSize: 20, color: Color(0xffD80000))),
                  ])
                : const SizedBox(width: 30),
          );
        });
  }
}
