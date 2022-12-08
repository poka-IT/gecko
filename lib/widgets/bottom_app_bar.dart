// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/search.dart';
import 'package:provider/provider.dart';

class GeckoBottomAppBar extends StatelessWidget {
  const GeckoBottomAppBar({Key? key, this.actualRoute = ''}) : super(key: key);
  final String actualRoute;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);

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
            iconSize: 40,
            icon: const Image(image: AssetImage('assets/loupe-noire.png')),
            onPressed: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (homeContext) {
                  return const SearchScreen();
                }),
              );
            },
          ),
          const SizedBox(width: 22),
          const Spacer(),
          IconButton(
            key: keyAppBarQrcode,
            iconSize: 70,
            icon: const Image(image: AssetImage('assets/qrcode-scan.png')),
            onPressed: () async {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
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
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName('/'),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const WalletsHome();
                            }),
                          );
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
