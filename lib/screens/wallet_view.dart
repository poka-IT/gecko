// ignore_for_file: use_build_context_synchronously
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/header_profile.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen(
      {required this.address, required this.username, this.avatar, Key? key})
      : super(key: key);
  final String address;
  final String username;
  final Image? avatar;
  final double buttonSize = 100;
  final double buttonFontSize = 18;

  @override
  Widget build(BuildContext context) {
    WalletsProfilesProvider walletProfile =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();

    walletProfile.address = address;
    sub.setCurrentWallet(defaultWallet);

    log.d("username: $username");

    return Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 60 * ratio,
          actions: [
            Row(
              children: [
                Consumer<WalletsProfilesProvider>(
                    builder: (context, walletProfile, _) {
                  return IconButton(
                    onPressed: () async {
                      G1WalletsList? newContact;
                      g1WalletsBox.toMap().forEach((key, value) {
                        if (key == address) newContact = value;
                      });
                      // G1WalletsList(pubkey: pubkey!, username: username);
                      await walletProfile.addContact(
                          newContact ?? G1WalletsList(address: address));
                    },
                    icon: Icon(
                      walletProfile.isContact(address)
                          ? Icons.add_reaction_rounded
                          : Icons.add_reaction_outlined,
                      size: 35,
                    ),
                  );
                }),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return QrCodeFullscreen(
                          walletProfile.address,
                        );
                      }),
                    );
                  },
                  child: QrImageWidget(
                    data: walletProfile.address,
                    version: QrVersions.auto,
                    size: 80,
                  ),
                ),
              ],
            )
          ],
          title: SizedBox(
              height: 22,
              child: Text(duniterIndexer
                          .walletNameIndexer[walletProfile.address] ==
                      null
                  ? 'seeAWallet'.tr()
                  : 'memberAccountOf'.tr(args: [
                      duniterIndexer.walletNameIndexer[walletProfile.address] ??
                          '?'
                    ]))),
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
        body: SafeArea(
          child: Column(children: <Widget>[
            HeaderProfile(address: address, username: username),
            SizedBox(height: isTall ? 30 : 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: yellowC,
                      child: InkWell(
                          key: keyViewActivity,
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(13),
                              child: Image(
                                  image: AssetImage(
                                      'assets/walletOptions/clock.png'),
                                  height: 90)),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageNoTransit(builder: (context) {
                                return ActivityScreen(
                                    address: address,
                                    avatar: defaultAvatar(50));
                              }),
                            );
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "displayNActivity".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
                WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
                return FutureBuilder(
                  future: sub.certState(defaultWallet.address, address),
                  builder: (context, AsyncSnapshot<Map<String, int>> snapshot) {
                    if (snapshot.data == null) return const SizedBox();
                    String duration = '';
                    log.d(
                        '${getShortPubkey(address)} --- certDelay ${snapshot.data!['certDelay']} --- certRenewable ${snapshot.data!['certRenewable']}');

                    if (snapshot.data!['certDelay'] != null ||
                        snapshot.data!['certRenewable'] != null) {
                      final Duration durationSeconds = Duration(
                          seconds: snapshot.data!['certDelay'] ??
                              snapshot.data!['certRenewable']!);
                      final seconds = durationSeconds.inSeconds;
                      final minutes = durationSeconds.inMinutes;

                      if (seconds <= 0) {
                        duration = 'seconds'.tr(args: ['0']);
                      } else if (seconds <= 60) {
                        duration = 'seconds'.tr(args: [seconds.toString()]);
                      } else if (seconds <= 3600) {
                        duration = 'minutes'.tr(args: [minutes.toString()]);
                      } else if (seconds <= 86400) {
                        final hours = durationSeconds.inHours;
                        final minutesLeft = minutes - hours * 60;
                        String showMinutes = '';
                        if (minutesLeft < 60) {}
                        showMinutes =
                            'minutes'.tr(args: [minutesLeft.toString()]);
                        duration =
                            'hours'.tr(args: [hours.toString(), showMinutes]);
                      } else if (seconds <= 2592000) {
                        final days = durationSeconds.inDays;
                        duration = 'days'.tr(args: [days.toString()]);
                      } else {
                        final months = (durationSeconds.inDays / 30).round();
                        duration = 'months'.tr(args: [months.toString()]);
                      }
                    }

                    final toStatus = snapshot.data!['toStatus'] ?? 0;

                    return Visibility(
                      visible: (snapshot.data != {}),
                      child: Column(children: <Widget>[
                        if (snapshot.data!['canCert'] != null ||
                            duration == 'seconds'.tr(args: ['0']))
                          Column(children: <Widget>[
                            SizedBox(
                              height: buttonSize,
                              child: ClipOval(
                                child: Material(
                                  color: const Color(0xffFFD58D),
                                  child: InkWell(
                                      key: keyCertify,
                                      splashColor: orangeC,
                                      child: const Padding(
                                        padding: EdgeInsets.only(bottom: 0),
                                        child: Image(
                                            image: AssetImage(
                                                'assets/gecko_certify.png')),
                                      ),
                                      onTap: () async {
                                        final bool? result =
                                            await confirmPopupCertification(
                                                context,
                                                'areYouSureYouWantToCertify1'
                                                    .tr(),
                                                duniterIndexer
                                                            .walletNameIndexer[
                                                        address] ??
                                                    "noIdentity".tr(),
                                                'areYouSureYouWantToCertify2'
                                                    .tr(),
                                                getShortPubkey(address));

                                        if (result ?? false) {
                                          String? pin;
                                          if (myWalletProvider.pinCode == '') {
                                            pin = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (homeContext) {
                                                  return UnlockingWallet(
                                                      wallet: defaultWallet);
                                                },
                                              ),
                                            );
                                          }
                                          if (pin != null ||
                                              myWalletProvider.pinCode != '') {
                                            WalletsProfilesProvider
                                                walletViewProvider = Provider
                                                    .of<WalletsProfilesProvider>(
                                                        context,
                                                        listen: false);
                                            final acc = sub.getCurrentWallet();
                                            sub.certify(
                                                acc.address!,
                                                walletViewProvider.address,
                                                pin ??
                                                    myWalletProvider.pinCode);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                                return const TransactionInProgress(
                                                    transType: 'cert');
                                              }),
                                            );
                                          }
                                        }
                                      }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              toStatus == 0
                                  ? "certify".tr()
                                  : "createIdentity".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w500),
                            ),
                          ])
                        else if (toStatus == 1)
                          waitToCert('mustConfirmHisIdentity', duration)
                        else if (snapshot.data!['certRenewable'] != null &&
                            duration != 'seconds'.tr(args: ['0']))
                          waitToCert('canRenewCertInX', duration)
                        else if (snapshot.data!['certDelay'] != null)
                          waitToCert('mustWaitXBeforeCertify', duration)
                      ]),
                    );
                  },
                );
              }),
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: const Color(0xffFFD58D),
                      child: InkWell(
                          key: keyCopyAddress,
                          splashColor: orangeC,
                          child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Image(
                                  image: AssetImage('assets/copy_key.png'),
                                  height: 90)),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: address));
                            snackCopyKey(context);
                          }),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "copyAddress".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
            ]),
            const Spacer(),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return Opacity(
                opacity: sub.nodeConnected ? 1 : 0.5,
                child: Container(
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: const Color(0xff7c94b6),
                    borderRadius: const BorderRadius.all(Radius.circular(100)),
                    border: Border.all(
                      color: const Color(0xFF6c4204),
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: Material(
                      color: orangeC,
                      child: InkWell(
                          key: keyPay,
                          splashColor: yellowC,
                          onTap: sub.nodeConnected
                              ? () async {
                                  String? pin;
                                  if (myWalletProvider.pinCode == '') {
                                    pin = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (homeContext) {
                                          return UnlockingWallet(
                                              wallet: defaultWallet);
                                        },
                                      ),
                                    );
                                  }
                                  if (pin != null ||
                                      myWalletProvider.pinCode != '') {
                                    paymentPopup(context, address, username);
                                  }
                                }
                              : null,
                          child: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Image(
                                image: AssetImage('assets/vector_white.png')),
                          )),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 9),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return Text(
                'doATransfer'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sub.nodeConnected ? Colors.black : Colors.grey[500],
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500),
              );
            }),
            SizedBox(height: isTall ? 50 : 20)
          ]),
        ));
  }

  Widget waitToCert(String status, String duration) {
    return Column(children: <Widget>[
      SizedBox(
        height: buttonSize,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Container(
            foregroundDecoration: const BoxDecoration(
              color: Colors.grey,
              backgroundBlendMode: BlendMode.saturation,
            ),
            child: const Opacity(
              opacity: 0.5,
              child: Image(image: AssetImage('assets/gecko_certify.png')),
            ),
          ),
        ),
      ),
      Text(
        status.tr(args: [duration]),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: buttonFontSize - 4,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600]),
      ),
    ]);
  }
}
