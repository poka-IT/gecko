import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';

class HeaderProfile extends StatelessWidget {
  const HeaderProfile({
    Key? key,
    required this.address,
    required this.username,
  }) : super(key: key);

  final String address;
  final String? username;

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 140;

    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    return Stack(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        // sub.getBlockchainStart();
        bool isAccountExist = balanceCache[address] != 0;
        return Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isAccountExist ? yellowC : Colors.grey[400]!,
                  isAccountExist ? const Color(0xFFE7811A) : Colors.grey[600]!,
                ],
              ),
            ));
      }),
      Padding(
        padding: const EdgeInsets.only(left: 30, right: 40),
        child: Row(children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 10,
                  color: yellowC, // Colors.grey[400],
                ),
                Row(children: [
                  GestureDetector(
                    key: keyCopyAddress,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: address));
                      snackCopyKey(context);
                    },
                    child: Text(
                      getShortPubkey(address),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 25),
                balance(context, address, 22),
                const SizedBox(height: 10),

                InkWell(
                  onTap: () => duniterIndexer.walletNameIndexer[address] != null
                      ? {
                          Navigator.push(
                            context,
                            PageNoTransit(builder: (context) {
                              return CertificationsScreen(
                                  address: address,
                                  username: duniterIndexer
                                      .walletNameIndexer[address]!);
                            }),
                          ),
                        }
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      walletOptions.idtyStatus(context, address,
                          isOwner: false, color: Colors.black),
                      getCerts(context, address, 14)
                    ],
                  ),
                ),
                // if (username == null &&
                //     g1WalletsBox.get(address)?.username != null)
                //   SizedBox(
                //     width: 230,
                //     child: Text(
                //       g1WalletsBox.get(address)?.username ?? '',
                //       style: const TextStyle(
                //         fontSize: 27,
                //         color: Color(0xff814C00),
                //       ),
                //     ),
                //   ),
                // if (username != null)
                //   SizedBox(
                //     width: 230,
                //     child: Text(
                //       username,
                //       style: const TextStyle(
                //         fontSize: 27,
                //         color: Color(0xff814C00),
                //       ),
                //     ),
                //   ),
                const SizedBox(height: 55),
              ]),
          const Spacer(),
          Column(children: <Widget>[
            ClipOval(
              child: defaultAvatar(avatarSize),
            ),
            const SizedBox(height: 25),
          ]),
        ]),
      ),
      CommonElements().offlineInfo(context),
    ]);
  }
}
