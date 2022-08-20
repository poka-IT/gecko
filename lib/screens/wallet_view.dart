// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/choose_wallet.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletViewScreen extends StatelessWidget {
  const WalletViewScreen(
      {required this.pubkey, this.username, this.avatar, Key? key})
      : super(key: key);
  final String? pubkey;
  final String? username;
  final Image? avatar;
  final double buttonSize = 100;
  final double buttonFontSize = 18;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WalletsProfilesProvider walletProfile =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    CesiumPlusProvider cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    walletProfile.address = pubkey!;
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);

    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
    sub.setCurrentWallet(defaultWallet);

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
                        if (key == pubkey) newContact = value;
                      });
                      // G1WalletsList(pubkey: pubkey!, username: username);
                      await walletProfile.addContact(
                          newContact ?? G1WalletsList(pubkey: pubkey!));
                    },
                    icon: Icon(
                      walletProfile.isContact(pubkey!)
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
                          walletProfile.address!,
                        );
                      }),
                    );
                  },
                  child: QrImageWidget(
                    data: walletProfile.address!,
                    version: QrVersions.auto,
                    size: 80,
                  ),
                ),
              ],
            )
          ],
          title: SizedBox(
            height: 22,
            child: Text('seeAWallet'.tr()),
          ),
        ),
        bottomNavigationBar: homeProvider.bottomAppBar(context),
        body: SafeArea(
          child: Column(children: <Widget>[
            walletProfile.headerProfileView(context, pubkey!, username),
            SizedBox(height: isTall ? 10 : 0),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: <Widget>[
                SizedBox(
                  height: buttonSize,
                  child: ClipOval(
                    child: Material(
                      color: yellowC, //const Color(0xffFFD58D), // button color
                      child: InkWell(
                          key: const Key('viewHistory'),
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(13),
                              child: Image(
                                  image: AssetImage(
                                      'assets/walletOptions/clock.png'),
                                  height: 90)),
                          onTap: () {
                            // _historyProvider.nPage = 1;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return ActivityScreen(
                                    address: pubkey,
                                    avatar:
                                        cesiumPlusProvider.defaultAvatar(50));
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
                  future: sub.certState(defaultWallet.address!,
                      pubkey!), // .canCertify(_defaultWallet.address!, pubkey!),
                  builder: (context, AsyncSnapshot<Map<String, int>> snapshot) {
                    if (snapshot.data == null) return const SizedBox();
                    String duration = '';
                    log.d('certDelay ${snapshot.data!['certDelay']}');
                    log.d('certRenewable ${snapshot.data!['certRenewable']}');

                    if (snapshot.data!['certDelay'] != null ||
                        snapshot.data!['certRenewable'] != null) {
                      final Duration durationSeconds = Duration(
                          seconds: snapshot.data!['certDelay'] ??
                              snapshot.data!['certRenewable']!);
                      final int seconds = durationSeconds.inSeconds;
                      final int minutes = durationSeconds.inMinutes;

                      if (seconds <= 0) {
                        duration = 'seconds'.tr(args: ['0']);
                      } else if (seconds <= 60) {
                        duration = 'seconds'.tr(args: [seconds.toString()]);
                      } else if (seconds <= 3600) {
                        duration = 'minutes'.tr(args: [minutes.toString()]);
                      } else if (seconds <= 86400) {
                        final int hours = durationSeconds.inHours;
                        final int minutesLeft = minutes - hours * 60;
                        String showMinutes = '';
                        if (minutesLeft < 60) {}
                        showMinutes =
                            'minutes'.tr(args: [minutesLeft.toString()]);
                        duration =
                            'hours'.tr(args: [hours.toString(), showMinutes]);
                      } else if (seconds <= 2592000) {
                        final int days = durationSeconds.inDays;
                        duration = 'days'.tr(args: [days.toString()]);
                      } else {
                        final int months =
                            (durationSeconds.inDays / 30).round();
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
                                  color:
                                      const Color(0xffFFD58D), // button color
                                  child: InkWell(
                                      key: const Key('certify'),
                                      splashColor: orangeC, // inkwell color
                                      child: const Padding(
                                        padding: EdgeInsets.only(bottom: 0),
                                        child: Image(
                                            image: AssetImage(
                                                'assets/gecko_certify.png')),
                                      ),
                                      onTap: () async {
                                        final bool? result = await confirmPopup(
                                            context,
                                            "areYouSureYouWantToCertify".tr(
                                                args: [
                                                  getShortPubkey(pubkey!)
                                                ]));

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
                                                pin ?? myWalletProvider.pinCode,
                                                walletViewProvider.address!);

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
                              "certify".tr(),
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
                      color: const Color(0xffFFD58D), // button color
                      child: InkWell(
                          key: const Key('copyKey'),
                          splashColor: orangeC, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Image(
                                  image: AssetImage('assets/copy_key.png'),
                                  height: 90)),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: pubkey));
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
                      color: orangeC, // button color
                      child: InkWell(
                          key: const Key('pay'),
                          splashColor: yellowC,
                          onTap: sub.nodeConnected
                              ? () {
                                  paymentPopup(context, walletProfile);
                                }
                              : null, // inkwell color
                          child: const Padding(
                              padding: EdgeInsets.all(14),
                              child: Image(
                                image: AssetImage('assets/vector_white.png'),
                              ))),
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

  void paymentPopup(
      BuildContext context, WalletsProfilesProvider walletViewProvider) {
    // WalletsProfilesProvider _walletViewProvider =
    //     Provider.of<WalletsProfilesProvider>(context, listen: false);

    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    const double shapeSize = 20;
    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
    log.d(defaultWallet.address);

    bool canValidate = false;

    showModalBottomSheet<void>(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(shapeSize),
            topLeft: Radius.circular(shapeSize),
          ),
        ),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            if (walletViewProvider.payAmount.text != '' &&
                (double.parse(walletViewProvider.payAmount.text) + 2) <=
                    (balanceCache[defaultWallet.address] ?? 0) &&
                walletViewProvider.address != defaultWallet.address) {
              if ((balanceCache[pubkey] == 0 || balanceCache[pubkey] == null) &&
                  double.parse(walletViewProvider.payAmount.text) < 5) {
                canValidate = false;
              } else {
                canValidate = true;
              }
            } else {
              canValidate = false;
            }
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: 400,
                decoration: const ShapeDecoration(
                  color: Color(0xffffeed1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(shapeSize),
                      topLeft: Radius.circular(shapeSize),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 24, bottom: 0, left: 24, right: 24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'executeATransfer'.tr(),
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ]),
                        const SizedBox(height: 20),
                        Text(
                          'from'.tr(),
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        Consumer<SubstrateSdk>(builder: (context, sub, _) {
                          return InkWell(
                            onTap: () async {
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return ChooseWalletScreen(
                                        pin: pin ?? myWalletProvider.pinCode);
                                  }),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.blueAccent.shade200,
                                    width: 2),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                Text(defaultWallet.name!),
                                const Spacer(),
                                FutureBuilder(
                                    future:
                                        sub.getBalance(defaultWallet.address!),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<Map<String, double>>
                                            globalBalance) {
                                      if (globalBalance.connectionState !=
                                              ConnectionState.done ||
                                          globalBalance.hasError) {
                                        if (balanceCache[
                                                defaultWallet.address!] !=
                                            null) {
                                          return Text(
                                              "${balanceCache[defaultWallet.address!]} $currencyName",
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ));
                                        } else {
                                          return SizedBox(
                                            height: 15,
                                            width: 15,
                                            child: CircularProgressIndicator(
                                              color: orangeC,
                                              strokeWidth: 2,
                                            ),
                                          );
                                        }
                                      }
                                      balanceCache[defaultWallet.address!] =
                                          globalBalance
                                              .data!['transferableBalance']!;
                                      return Text(
                                        "${balanceCache[defaultWallet.address!]} $currencyName",
                                        style: const TextStyle(
                                          fontSize: 20,
                                        ),
                                      );
                                    }),
                              ]),
                            ),
                          );
                        }),
                        const Spacer(),

                        // const SizedBox(height: 10),
                        Text(
                          'amount'.tr(),
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: walletViewProvider.payAmount,
                          autofocus: true,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            // _walletViewProvider.reload();
                          }),
                          inputFormatters: <TextInputFormatter>[
                            // FilteringTextInputFormatter.digitsOnly,
                            FilteringTextInputFormatter.deny(',',
                                replacementString: '.'),
                            FilteringTextInputFormatter.allow(
                                RegExp(r'(^\d+\.?\d{0,2})')),
                          ],
                          // onChanged: (v) => _searchProvider.rebuildWidget(),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            suffix: Text(currencyName),
                            filled: true,
                            fillColor: Colors.transparent,
                            // border: OutlineInputBorder(
                            //     borderSide:
                            //         BorderSide(color: Colors.grey[500], width: 2),
                            //     borderRadius: BorderRadius.circular(8)),

                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey[500]!, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // const SizedBox(height: 40),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              primary: orangeC, // background
                              onPrimary: Colors.white, // foreground
                            ),
                            onPressed: canValidate
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
                                    log.d(pin);
                                    if (pin != null ||
                                        myWalletProvider.pinCode != '') {
                                      // Payment workflow !
                                      WalletsProfilesProvider
                                          walletViewProvider =
                                          Provider.of<WalletsProfilesProvider>(
                                              context,
                                              listen: false);
                                      SubstrateSdk sub =
                                          Provider.of<SubstrateSdk>(context,
                                              listen: false);
                                      final acc = sub.getCurrentWallet();
                                      log.d(
                                          "fromAddress: ${acc.address!},destAddress: ${walletViewProvider.address!}, amount: ${double.parse(walletViewProvider.payAmount.text)},  password: $pin");
                                      sub.pay(
                                          fromAddress: acc.address!,
                                          destAddress:
                                              walletViewProvider.address!,
                                          amount: double.parse(
                                              walletViewProvider
                                                  .payAmount.text),
                                          password:
                                              pin ?? myWalletProvider.pinCode);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) {
                                          return const TransactionInProgress();
                                        }),
                                      );
                                    }
                                  }
                                : null,
                            child: Text(
                              'executeTheTransfer'.tr(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ]),
                ),
              ),
            );
          });
        }).then((value) => walletViewProvider.payAmount.text = '');
  }
}
