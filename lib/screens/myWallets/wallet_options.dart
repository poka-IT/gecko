import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/manage_membership.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';

import 'package:qr_flutter/qr_flutter.dart';

class WalletOptions extends StatelessWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet})
      : super(key: keyMyWallets);
  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    // final sub = Provider.of<SubstrateSdk>(context, listen: false);
    // sub.spawnBlock();
    // sub.spawnBlock(0, 20);

    log.d(walletOptions.address.text);

    final currentChest = myWalletProvider.getCurrentChest();

    // final currentWallet = _myWalletProvider.getDefaultWallet();
    // log.d(_walletOptions.getAddress(_currentChest, 3));
    log.d("Wallet options: $currentChest:${wallet.derivation}");

    return WillPopScope(
      onWillPop: () {
        walletOptions.isEditing = false;
        walletOptions.isBalanceBlur = false;
        myWalletProvider.reload();
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
                walletOptions.isEditing = false;
                walletOptions.isBalanceBlur = false;
                myWalletProvider.reload();
                Navigator.pop(context);
              }),
          title: SizedBox(
            height: 22,
            child: Consumer<WalletOptionsProvider>(
                builder: (context, walletProvider, _) {
              return Text(wallet.name!);
            }),
          ),
          actions: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return QrCodeFullscreen(
                      walletOptions.address.text,
                    );
                  }),
                );
              },
              child: QrImageWidget(
                data: walletOptions.address.text,
                version: QrVersions.auto,
                size: 80,
              ),
            ),
          ],
        ),
        bottomNavigationBar: homeProvider.bottomAppBar(context),
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
                    decoration: const BoxDecoration(
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
                                NameByAddress(
                                    address: walletProvider.address.text,
                                    wallet: wallet,
                                    size: 27,
                                    canEdit: false,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal),
                                SizedBox(height: isTall ? 5 : 0),
                                Balance(
                                    address: walletProvider.address.text,
                                    size: 21),
                                const SizedBox(width: 30),
                                InkWell(
                                  onTap: () => duniterIndexer.walletNameIndexer[
                                              walletProvider.address.text] !=
                                          null
                                      ? {
                                          Navigator.push(
                                            context,
                                            PageNoTransit(builder: (context) {
                                              return CertificationsScreen(
                                                  address: walletProvider
                                                      .address.text,
                                                  username: duniterIndexer
                                                          .walletNameIndexer[
                                                      walletProvider
                                                          .address.text]!);
                                            }),
                                          ),
                                        }
                                      : null,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IdentityStatus(
                                            address: walletOptions.address.text,
                                            isOwner: true,
                                            color: orangeC),
                                        Certifications(
                                            address:
                                                walletProvider.address.text,
                                            size: 15)
                                      ]),
                                ),
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
                          // InkWell(
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(builder: (context) {
                          //         return QrCodeFullscreen(
                          //           _walletOptions.address.text,
                          //         );
                          //       }),
                          //     );
                          //   },
                          //   child: QrImageWidget(
                          //     data: _walletOptions.address.text,
                          //     version: QrVersions.auto,
                          //     size: isTall ? 150 : 80,
                          //   ),
                          // ),
                          SizedBox(height: 30 * ratio),
                          Consumer<WalletOptionsProvider>(
                              builder: (context, walletProvider, _) {
                            return Column(children: [
                              confirmIdentityButton(walletProvider),
                              pubkeyWidget(walletProvider, ctx),
                              SizedBox(height: 10 * ratio),
                              activityWidget(
                                  context, historyProvider, walletProvider),
                              SizedBox(height: 12 * ratio),
                              setDefaultWalletWidget(
                                  context,
                                  walletProvider,
                                  myWalletProvider,
                                  walletOptions,
                                  currentChest),
                              SizedBox(height: 17 * ratio),
                              // walletProvider.isMember(context, _walletOptions.address.text)
                              FutureBuilder(
                                  future: walletProvider.isMember(
                                      context, walletOptions.address.text),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<bool> isMember) {
                                    if (isMember.connectionState !=
                                            ConnectionState.done ||
                                        isMember.hasError) {
                                      return const Text('');
                                    }
                                    return Column(children: [
                                      if (!walletProvider.isDefaultWallet &&
                                          !isMember.data!)
                                        deleteWallet(context, walletProvider,
                                            currentChest)
                                      else
                                        const SizedBox(),
                                      if (isMember.data!)
                                        manageMembership(context)
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
            final newPath = await (walletProvider.changeAvatar());
            if (newPath != '') {
              wallet.imageCustomPath = newPath;
              walletBox.put(wallet.key, wallet);
            }
            walletProvider.reload();
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
              walletProvider.reload();
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

  Widget confirmIdentityButton(WalletOptionsProvider walletProvider) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus(walletProvider.address.text),
          initialData: '',
          builder: (context, snapshot) {
            if (snapshot.data == 'Created') {
              return Column(children: [
                SizedBox(
                  width: 320,
                  height: 60,
                  child: ElevatedButton(
                    key: keyConfirmIdentity,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, elevation: 4,
                      backgroundColor: orangeC, // foreground
                    ),
                    onPressed: () async {
                      walletProvider.confirmIdentityPopup(context);
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) {
                      //     return const SearchResultScreen();
                      //   }),
                      // );
                    },
                    child: Text(
                      'confirmMyIdentity'.tr(),
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "someoneCreatedYourIdentity".tr(args: [currencyName]),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),
              ]);
            } else {
              return const SizedBox();
            }
          });
    });
  }

  Widget pubkeyWidget(WalletOptionsProvider walletProvider, BuildContext ctx) {
    final shortPubkey = getShortPubkey(walletProvider.address.text);
    return GestureDetector(
      key: keyCopyAddress,
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
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: orangeC,
                elevation: 1, // foreground
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
                  'copy'.tr(),
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
      WalletsProfilesProvider historyProvider,
      WalletOptionsProvider walletProvider) {
    return InkWell(
      key: keyOpenActivity,
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
          Text("displayActivity".tr(),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget manageMembership(BuildContext context) {
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    return InkWell(
      key: keyManageMembership,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ManageMembership(
              address: walletOptions.address.text,
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
          Text('manageMembership'.tr(), style: const TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Widget setDefaultWalletWidget(
      BuildContext context,
      WalletOptionsProvider walletProvider,
      final myWalletProvider,
      final walletOptions,
      int currentChest) {
    return Consumer<MyWalletsProvider>(builder: (context, myWalletProvider, _) {
      WalletData defaultWallet = myWalletProvider.getDefaultWallet();
      walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id()[1]);
      return InkWell(
        key: keySetDefaultWallet,
        onTap: !walletProvider.isDefaultWallet
            ? () async {
                await setDefaultWallet(context, currentChest);
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
                    ? 'thisWalletIsDefault'.tr()
                    : 'defineWalletAsDefault'.tr(),
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

  Future setDefaultWallet(BuildContext context, int currentChest) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);

    // WalletData defaultWallet = _myWalletProvider.getDefaultWallet()!;
    // defaultWallet = wallet;
    await sub.setCurrentWallet(wallet);
    myWalletProvider.readAllWallets(currentChest);
    myWalletProvider.reload();
    walletOptions.reload();
  }

  Widget deleteWallet(BuildContext context, WalletOptionsProvider walletOptions,
      int currentChest) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final defaultWallet = myWalletProvider.getDefaultWallet();
    final bool isDefaultWallet =
        walletOptions.address.text == defaultWallet.address;
    // return Consumer<MyWalletsProvider>(
    //     builder: (context, _myWalletProvider, _) {
    return FutureBuilder(
        future: sub.hasAccountConsumers(wallet.address),
        builder: (BuildContext context, AsyncSnapshot<bool> hasConsumers) {
          if (hasConsumers.connectionState != ConnectionState.done ||
              hasConsumers.hasError) {
            return const Text('');
          }
          final double balance =
              walletOptions.balanceCache[walletOptions.address.text] ?? -1;
          final bool canDelete = !isDefaultWallet &&
              !hasConsumers.data! &&
              (balance > 2 || balance == 0);
          return InkWell(
            key: keyDeleteWallet,
            onTap: canDelete
                ? () async {
                    await walletOptions.deleteWallet(context, wallet);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      myWalletProvider.listWallets =
                          myWalletProvider.readAllWallets(currentChest);
                      myWalletProvider.reload();
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
                    Text('deleteThisWallet'.tr(),
                        style: const TextStyle(
                            fontSize: 20, color: Color(0xffD80000))),
                  ])
                : const SizedBox(width: 30),
          );
        });
  }
}
