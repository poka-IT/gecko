// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class GeckoBottomAppBar extends StatelessWidget {
  const GeckoBottomAppBar({Key? key, this.actualRoute = ''}) : super(key: key);
  final String actualRoute;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;
    const bool showBottomBar = true;
    final lockAction = actualRoute == 'safeHome';

    return Visibility(
      visible: showBottomBar,
      child: Container(
        color: yellowC,
        width: size.width,
        height: 80,
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const Spacer(),
          const SizedBox(width: 11),
          IconButton(
            key: keyAppBarSearch,
            iconSize: 55,
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              searchProvider.reload();
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
            },
          ),
          const SizedBox(width: 12),
          const Spacer(),
          IconButton(
            key: keyAppBarQrcode,
            iconSize: 70,
            icon: const Image(image: AssetImage('assets/qrcode-scan.png')),
            onPressed: () async {
              historyProvider.scan(homeContext);
            },
          ),
          const Spacer(),
          const SizedBox(width: 15),
          Stack(
            children: [
              if (lockAction)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: orangeC.withOpacity(0), width: 3),
                        gradient: RadialGradient(
                          radius: 0.5,
                          colors: [
                            yellowC,
                            orangeC.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                key: keyAppBarChest,
                iconSize: 60,
                icon: const Image(image: AssetImage('assets/wallet.png')),
                onPressed: lockAction
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
                                return UnlockingWallet(wallet: defaultWallet);
                              },
                            ),
                          );
                        }
                        if (pin != null || myWalletProvider.pinCode != '') {
                          // log.d(
                          //     isRoutePresentInNavigator(context, '/mywallets'));
                          Navigator.popUntil(context, ModalRoute.withName('/'));
                          //FIXME: Should not have to wait 300 milliseconds when /mywallets exist in navigator...
                          sleep(const Duration(milliseconds: 300));
                          Navigator.pushNamed(context, '/mywallets');
                          // Navigator.pushNamedAndRemoveUntil(
                          //     context, '/mywallets', ModalRoute.withName('/'));
                        }
                      },
              ),
            ],
          ),
          const Spacer(),
        ]),
      ),
    );
  }
}

bool isRoutePresentInNavigator(BuildContext context, String routeName) {
  bool isPresent = false;
  Navigator.popUntil(context, (route) {
    log.d(route.settings.name);
    if (route.settings.name == routeName) {
      isPresent = true;
    }
    return true;
  });
  return isPresent;
}
