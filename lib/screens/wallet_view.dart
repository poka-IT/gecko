// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
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

const double buttonSize = 83;
const double buttonFontSize = 14;

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen(
      {required this.address, required this.username, Key? key})
      : super(key: key);
  final String address;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final walletProfile =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();

    walletProfile.address = address;
    sub.setCurrentWallet(defaultWallet);

    return Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: scaleSize(57),
          titleSpacing: 10,
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
                      await walletProfile.addContact(
                          newContact ?? G1WalletsList(address: address));
                    },
                    icon: Icon(
                      walletProfile.isContact(address)
                          ? Icons.add_reaction_rounded
                          : Icons.add_reaction_outlined,
                      size: scaleSize(33),
                    ),
                  );
                }),
                ScaledSizedBox(width: isTall ? 10 : 0),
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
                  child: QrImageView(
                    data: walletProfile.address,
                    version: QrVersions.auto,
                    size: scaleSize(65),
                  ),
                ),
              ],
            )
          ],
          title: Text(
            duniterIndexer.walletNameIndexer[walletProfile.address] == null
                ? 'seeAWallet'.tr()
                : 'memberAccountOf'.tr(args: [
                    duniterIndexer.walletNameIndexer[walletProfile.address] ??
                        '?'
                  ]),
            style: scaledTextStyle(fontSize: 18),
          ),
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
        body: SafeArea(
          child: Column(children: <Widget>[
            HeaderProfile(address: address, username: username),
            ScaledSizedBox(height: 25),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                ScaledSizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: yellowC,
                      child: InkWell(
                          key: keyViewActivity,
                          splashColor: orangeC,
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(10)),
                            child:
                                Image.asset('assets/walletOptions/clock.png'),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              PageNoTransit(builder: (context) {
                                return ActivityScreen(address: address);
                              }),
                            );
                          }),
                    ),
                  ),
                ),
                ScaledSizedBox(height: 6),
                Text(
                  "displayNActivity".tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
              Consumer<SubstrateSdk>(builder: (context, sub, _) {
                WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
                return FutureBuilder(
                  future: sub.certState(defaultWallet.address, address),
                  builder: (context, AsyncSnapshot<Map<String, int>> snapshot) {
                    if (snapshot.data == null) return const SizedBox.shrink();
                    final certStateData = snapshot.data!;
                    String duration = '';

                    if (certStateData['certDelay'] != null ||
                        certStateData['certRenewable'] != null) {
                      final Duration durationSeconds = Duration(
                          seconds: certStateData['certDelay'] ??
                              certStateData['certRenewable']!);
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

                    final toStatus = certStateData['toStatus'];

                    return Visibility(
                      visible: (snapshot.data != {}),
                      child: Column(children: <Widget>[
                        if (certStateData['canCert'] != null ||
                            duration == 'seconds'.tr(args: ['0']))
                          Column(children: <Widget>[
                            ScaledSizedBox(
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
                                        final result =
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
                                                    getShortPubkey(address)) ??
                                                false;

                                        if (!result) return;
                                        if (myWalletProvider.pinCode == '') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (homeContext) {
                                                return UnlockingWallet(
                                                    wallet: defaultWallet);
                                              },
                                            ),
                                          );
                                        }
                                        if (myWalletProvider.pinCode == '') {
                                          return;
                                        }
                                        WalletsProfilesProvider
                                            walletViewProvider = Provider.of<
                                                    WalletsProfilesProvider>(
                                                context,
                                                listen: false);
                                        final acc = sub.getCurrentWallet();
                                        final transactionId = await sub.certify(
                                            acc.address!,
                                            walletViewProvider.address,
                                            myWalletProvider.pinCode);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return TransactionInProgress(
                                                transactionId: transactionId,
                                                transType: 'cert');
                                          }),
                                        );
                                      }),
                                ),
                              ),
                            ),
                            ScaledSizedBox(height: 6),
                            Text(
                              toStatus == null
                                  ? "certify".tr()
                                  : "createIdentity".tr(),
                              textAlign: TextAlign.center,
                              style: scaledTextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w500),
                            ),
                          ])
                        else if (toStatus == 1)
                          waitToCert('mustConfirmHisIdentity', duration)
                        else if (certStateData['certRenewable'] != null &&
                            duration != 'seconds'.tr(args: ['0']))
                          waitToCert('canRenewCertInX', duration)
                        else if (certStateData['certDelay'] != null)
                          waitToCert('mustWaitXBeforeCertify', duration)
                      ]),
                    );
                  },
                );
              }),
              Column(children: <Widget>[
                ScaledSizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: const Color(0xffFFD58D),
                      child: InkWell(
                          key: keyCopyAddress,
                          splashColor: orangeC,
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(17)),
                            child: const Image(
                              image: AssetImage('assets/copy_key.png'),
                            ),
                          ),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: address));
                            snackCopyKey(context);
                          }),
                    ),
                  ),
                ),
                ScaledSizedBox(height: 6),
                Text(
                  "copyAddress".tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(
                      fontSize: buttonFontSize, fontWeight: FontWeight.w500),
                ),
              ]),
            ]),
            const Spacer(),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return Opacity(
                opacity: sub.nodeConnected ? 1 : 0.5,
                child: Container(
                  height: scaleSize(buttonSize),
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
                                  if (myWalletProvider.pinCode == '') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (homeContext) {
                                          return UnlockingWallet(
                                              wallet: defaultWallet);
                                        },
                                      ),
                                    );
                                  }
                                  if (myWalletProvider.pinCode == '') return;
                                  paymentPopup(context, address, username);
                                }
                              : null,
                          child: Padding(
                            padding: EdgeInsets.all(scaleSize(10)),
                            child: const Image(
                                image: AssetImage('assets/vector_white.png')),
                          )),
                    ),
                  ),
                ),
              );
            }),
            ScaledSizedBox(height: 6),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return Text(
                'doATransfer'.tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(
                    color: sub.nodeConnected ? Colors.black : Colors.grey[500],
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w500),
              );
            }),
            ScaledSizedBox(height: isTall ? 50 : 7)
          ]),
        ));
  }

  Widget waitToCert(String status, String duration) {
    return Column(children: <Widget>[
      ScaledSizedBox(
        height: buttonSize,
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
      Text(
        status.tr(args: [duration]),
        textAlign: TextAlign.center,
        style: scaledTextStyle(
            fontSize: buttonFontSize - 4,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600]),
      ),
    ]);
  }
}
