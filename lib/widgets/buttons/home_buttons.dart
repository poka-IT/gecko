// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/search.dart';
import 'package:provider/provider.dart';

class HomeButtons extends StatelessWidget {
  const HomeButtons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final historyProvider = Provider.of<WalletsProfilesProvider>(context);

    return Column(children: <Widget>[
      const Spacer(),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Column(children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                    blurRadius: 2, offset: Offset(1, 1.5), spreadRadius: 0.5)
              ],
            ),
            child: ClipOval(
              child: Material(
                color: orangeC,
                child: InkWell(
                    key: keyOpenSearch,
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(15)),
                      child: Image(
                          image: const AssetImage('assets/home/loupe.png'),
                          height: scaleSize(58)),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return const SearchScreen();
                        }),
                      );
                    }),
              ),
            ),
          ),
          ScaledSizedBox(height: 10),
          Text(
            "searchWallet".tr(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500),
          )
        ]),
        ScaledSizedBox(width: 95),
        Column(children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                    blurRadius: 2, offset: Offset(1, 1.5), spreadRadius: 0.5)
              ],
            ),
            child: ClipOval(
              key: keyOpenWalletsHomme,
              child: Material(
                color: homeProvider.isWalletBoxInit
                    ? orangeC
                    : Colors.grey[500], // button color
                child: InkWell(
                    onTap: !homeProvider.isWalletBoxInit
                        ? null
                        : () async {
                            WalletData? defaultWallet =
                                myWalletProvider.getDefaultWallet();
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
                            if (pin != null || myWalletProvider.pinCode != '') {
                              Navigator.pushNamed(context, '/mywallets');
                            }
                          },
                    child: Padding(
                        padding: EdgeInsets.all(scaleSize(14.5)),
                        child: Image(
                            image: const AssetImage('assets/home/wallet.png'),
                            height: scaleSize(61)))),
              ),
            ),
          ),
          ScaledSizedBox(height: 10),
          Text(
            "manageWallets".tr(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500),
          )
        ])
      ]),
      Padding(
        padding: EdgeInsets.only(top: scaleSize(30)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Column(children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                      blurRadius: 2, offset: Offset(1, 1.5), spreadRadius: 0.5)
                ],
              ),
              child: ClipOval(
                child: Material(
                  color: orangeC, // button color
                  child: InkWell(
                      child: Padding(
                          padding: EdgeInsets.all(scaleSize(14)),
                          child: Image(
                              image: const AssetImage('assets/home/qrcode.png'),
                              height: scaleSize(62))),
                      onTap: () async {
                        await historyProvider.scan(context);
                      }),
                ),
              ),
            ),
            ScaledSizedBox(height: 10),
            Text(
              "scanQRCode".tr(),
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500),
            )
          ])
        ]),
      ),
      ScaledSizedBox(height: isTall ? 60 : 30)
    ]);
  }
}
