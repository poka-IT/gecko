// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletOptions extends StatelessWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet}) : super(key: keyMyWallets);
  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    walletOptions.address.text = wallet.address;

    final currentChest = myWalletProvider.getCurrentChest();
    final isWalletNameIndexed = duniterIndexer.walletNameIndexer[walletOptions.address.text] != null;

    final isAlone = myWalletProvider.listWallets.length == 1;

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        walletOptions.isEditing = false;
        walletOptions.isBalanceBlur = false;
        myWalletProvider.reload();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: scaleSize(57),
          elevation: 0,
          title: Consumer<WalletOptionsProvider>(builder: (context, walletProvider, _) {
            return Text(
              isWalletNameIndexed ? duniterIndexer.walletNameIndexer[walletOptions.address.text]! : wallet.name!,
              style: scaledTextStyle(fontSize: 18),
            );
          }),
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
              child: QrImageView(
                data: walletOptions.address.text,
                version: QrVersions.auto,
                size: scaleSize(70),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
        body: Stack(children: [
          SafeArea(
            child: Column(children: <Widget>[
              Container(
                height: 5,
                color: yellowC,
              ),
              Consumer<WalletOptionsProvider>(builder: (context, walletProvider, _) {
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
                  child: Row(children: <Widget>[
                    const Spacer(flex: 1),
                    ScaledSizedBox(width: 15),
                    avatar(walletProvider),
                    const Spacer(flex: 1),
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                      Stack(children: [
                        ScaledSizedBox(
                          width: 230,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Consumer<WalletOptionsProvider>(builder: (context, walletProvider, _) {
                                return NameByAddress(
                                    wallet: wallet,
                                    size: 24,
                                    color: Colors.black,
                                    fontWeight: wallet.identityStatus == IdtyStatus.member ? FontWeight.w500 : FontWeight.w400,
                                    fontStyle: FontStyle.normal);
                              })
                            ],
                          ),
                        ),
                        ScaledSizedBox(width: 10),
                        if (duniterIndexer.walletNameIndexer[wallet.address] == null)
                          Positioned(
                            right: 0,
                            child: InkWell(
                              key: keyRenameWallet,
                              onTap: () async {
                                await walletOptions.editWalletName(context, wallet.id());
                                await Future.delayed(const Duration(milliseconds: 30));
                              },
                              child: ClipRRect(
                                child: Image.asset(walletOptions.isEditing ? 'assets/walletOptions/android-checkmark.png' : 'assets/walletOptions/edit.png',
                                    width: scaleSize(23), height: scaleSize(23)),
                              ),
                            ),
                          ),
                      ]),
                      ScaledSizedBox(height: 5),
                      Balance(address: walletProvider.address.text, size: 20),
                      ScaledSizedBox(width: 30),
                      InkWell(
                        onTap: () => sub.certsCounterCache[walletProvider.address.text] != null
                            ? {
                                Navigator.push(
                                  context,
                                  PageNoTransit(builder: (context) {
                                    return CertificationsScreen(
                                        address: walletProvider.address.text, username: duniterIndexer.walletNameIndexer[walletProvider.address.text] ?? '');
                                  }),
                                ),
                              }
                            : null,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          IdentityStatus(address: walletOptions.address.text, isOwner: true, color: orangeC),
                          Certifications(address: walletProvider.address.text, size: 17)
                        ]),
                      ),
                      ScaledSizedBox(height: 10),
                    ]),
                    const Spacer(flex: 2),
                  ]),
                );
              }),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                    ScaledSizedBox(height: 25),
                    Consumer<WalletOptionsProvider>(builder: (context, walletProvider, _) {
                      final defaultWallet = myWalletProvider.getDefaultWallet();
                      walletProvider.isDefaultWallet = walletOptions.address.text == defaultWallet.address;
                      return Column(children: [
                        confirmIdentityButton(walletProvider),
                        pubkeyWidget(walletProvider, context),
                        ScaledSizedBox(height: 11),
                        activityWidget(context, historyProvider, walletProvider),
                        ScaledSizedBox(height: 11),
                        if (!isAlone) ...[
                          setDefaultWalletWidget(context, walletProvider, myWalletProvider, walletOptions, currentChest),
                          ScaledSizedBox(height: 11),
                        ],
                        Column(children: [
                          if (!walletProvider.isDefaultWallet && !wallet.isMembre()) deleteWallet(context, walletProvider, currentChest),
                          if (wallet.isMembre()) const ManageMembershipButton()
                        ]),
                        if (isAlone) aloneWalletOptions()
                      ]);
                    }),
                  ]),
                ),
              ),
            ]),
          ),
          const OfflineInfo(),
        ]),
      ),
    );
  }

  Widget avatar(WalletOptionsProvider walletProvider) {
    return Stack(
      children: <Widget>[
        InkWell(
          onTap: () async {
            await (walletProvider.changeAvatar());
          },
          child: wallet.imageCustomPath == null || wallet.imageCustomPath == ''
              ? Image.asset(
                  'assets/avatars/${wallet.imageDefaultPath}',
                  width: scaleSize(122),
                )
              : Container(
                  width: scaleSize(122),
                  height: scaleSize(122),
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
              height: scaleSize(38),
            ),
          ),
        ),
      ],
    );
  }

  Widget confirmIdentityButton(WalletOptionsProvider walletProvider) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus([walletProvider.address.text]),
          initialData: const [IdtyStatus.unknown],
          builder: (BuildContext context, AsyncSnapshot<List<IdtyStatus>> snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox.shrink();
            }
            if (snapshot.data!.first == IdtyStatus.unconfirmed) {
              return Column(children: [
                ScaledSizedBox(
                  width: 310,
                  height: 55,
                  child: ElevatedButton(
                    key: keyConfirmIdentity,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      elevation: 4,
                      backgroundColor: orangeC,
                    ),
                    onPressed: () {
                      walletProvider.confirmIdentityPopup(context);
                    },
                    child: Text(
                      'confirmMyIdentity'.tr(),
                      style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                ScaledSizedBox(height: 7),
                Text(
                  "someoneCreatedYourIdentity".tr(args: [currencyName]),
                  style: scaledTextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                ScaledSizedBox(height: 40),
              ]);
            } else {
              return ScaledSizedBox();
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
      child: ScaledSizedBox(
        height: 50,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 26),
          Image.asset(
            'assets/walletOptions/key.png',
            height: scaleSize(42),
          ),
          ScaledSizedBox(width: 19),
          Text(shortPubkey, style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Monospace', color: Colors.black)),
          const Spacer(),
          ScaledSizedBox(
            height: 35,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: orangeC,
                elevation: 1,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: walletProvider.address.text));
                snackCopyKey(ctx);
              },
              child: Row(children: <Widget>[
                Image.asset(
                  'assets/walletOptions/copy-white.png',
                  height: scaleSize(23),
                ),
              ]),
            ),
          ),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget activityWidget(BuildContext context, WalletsProfilesProvider historyProvider, WalletOptionsProvider walletProvider) {
    return InkWell(
      key: keyOpenActivity,
      onTap: () {
        Navigator.push(
          context,
          PageNoTransit(builder: (context) {
            return ActivityScreen(address: walletProvider.address.text);
          }),
        );
      },
      child: ScaledSizedBox(
        height: 50,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 26),
          Image.asset(
            'assets/walletOptions/clock.png',
            height: scaleSize(42),
          ),
          ScaledSizedBox(width: 20),
          Text("displayActivity".tr(), style: scaledTextStyle(fontSize: 17)),
        ]),
      ),
    );
  }

  Widget setDefaultWalletWidget(BuildContext context, WalletOptionsProvider walletProvider, final myWalletProvider, final walletOptions, int currentChest) {
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
        child: ScaledSizedBox(
          height: 60,
          child: Row(children: <Widget>[
            ScaledSizedBox(width: isTall ? 28 : 23),
            ScaledSizedBox(
              height: 42,
              child: CircleAvatar(
                backgroundColor: Colors.grey[walletProvider.isDefaultWallet ? 300 : 500],
                child: Image.asset(
                  'assets/walletOptions/android-checkmark.png',
                  height: scaleSize(23),
                ),
              ),
            ),
            ScaledSizedBox(width: isTall ? 21 : 18),
            ScaledSizedBox(
              width: 250,
              child: Text(walletProvider.isDefaultWallet ? 'thisWalletIsDefault'.tr() : 'defineWalletAsDefault'.tr(),
                  style: scaledTextStyle(fontSize: 17, color: walletProvider.isDefaultWallet ? Colors.grey[500] : Colors.black)),
            ),
          ]),
        ),
      );
    });
  }

  Future setDefaultWallet(BuildContext context, int currentChest) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);

    await sub.setCurrentWallet(wallet);
    await myWalletProvider.readAllWallets(currentChest);
    myWalletProvider.reload();
    walletOptions.reload();
  }

  Widget deleteWallet(BuildContext context, WalletOptionsProvider walletOptions, int currentChest) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final defaultWallet = myWalletProvider.getDefaultWallet();
    final bool isDefaultWallet = walletOptions.address.text == defaultWallet.address;
    return FutureBuilder(
        future: sub.hasAccountConsumers(wallet.address),
        builder: (BuildContext context, AsyncSnapshot<bool> hasConsumers) {
          if (hasConsumers.connectionState != ConnectionState.done || hasConsumers.hasError || !hasConsumers.hasData) {
            return const Text('');
          }
          final double balance = walletOptions.balanceCache[walletOptions.address.text] ?? -1;
          final bool canDelete = !isDefaultWallet && !hasConsumers.data! && (balance > 2 || balance == 0) && !wallet.hasIdentity();
          return InkWell(
            key: keyDeleteWallet,
            onTap: canDelete
                ? () async {
                    await walletOptions.deleteWallet(context, wallet);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      myWalletProvider.listWallets = await myWalletProvider.readAllWallets(currentChest);
                      myWalletProvider.reload();
                    });
                  }
                : null,
            child: canDelete
                ? Row(children: <Widget>[
                    ScaledSizedBox(width: 27),
                    Image.asset(
                      'assets/walletOptions/trash.png',
                      height: scaleSize(42),
                    ),
                    ScaledSizedBox(width: 19),
                    Text('deleteThisWallet'.tr(), style: scaledTextStyle(fontSize: 17, color: const Color(0xffD80000))),
                  ])
                : ScaledSizedBox(width: 30),
          );
        });
  }
}

Widget aloneWalletOptions() {
  return Column(
    children: [
      ChestOptionsContent(),
      Consumer<SubstrateSdk>(
        builder: (context, sub, _) {
          final myWalletProvider = Provider.of<MyWalletsProvider>(context);
          return Column(
            children: [
              InkWell(
                onTap: () async {
                  if (!myWalletProvider.isNewDerivationLoading) {
                    if (!await myWalletProvider.askPinCode()) return;

                    String newDerivationName = '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
                    await myWalletProvider.generateNewDerivation(context, newDerivationName);

                    Navigator.pushReplacementNamed(context, '/mywallets');
                  }
                },
                child: ScaledSizedBox(
                  height: 60,
                  child: Row(
                    children: <Widget>[
                      ScaledSizedBox(width: 37),
                      Icon(
                        Icons.add_circle_outline,
                        size: scaleSize(31),
                        color: sub.nodeConnected ? Colors.black : Colors.grey[500],
                      ),
                      ScaledSizedBox(width: 23),
                      Text(
                        'createNewWallet'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          color: sub.nodeConnected ? Colors.black : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      InkWell(
        onTap: () async {
          Navigator.push(
            homeContext,
            MaterialPageRoute(builder: (context) {
              return const ImportG1v1();
            }),
          );
        },
        child: ScaledSizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              ScaledSizedBox(width: 37),
              SvgPicture.asset(
                'assets/cesium_bw2.svg',
                semanticsLabel: 'CS',
                height: scaleSize(31),
              ),
              ScaledSizedBox(width: 23),
              Text(
                'importG1v1'.tr(),
                style: scaledTextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
