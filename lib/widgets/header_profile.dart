import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/cesium_avatar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/idty_status.dart';
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
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    return Stack(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        bool isAccountExist = walletOptions.balanceCache[address] != 0;
        return Container(
            height: 185,
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
        padding: const EdgeInsets.only(left: 30, right: 30),
        child: Row(children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 10,
                  color: yellowC,
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
                const SizedBox(height: 18),
                Balance(address: address, size: 25),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () => sub.certsCounterCache[address] != null
                      ? {
                          Navigator.push(
                            context,
                            PageNoTransit(builder: (context) {
                              return CertificationsScreen(
                                  address: address,
                                  username: duniterIndexer
                                          .walletNameIndexer[address] ??
                                      '');
                            }),
                          ),
                        }
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IdentityStatus(
                          address: address,
                          isOwner: false,
                          color: Colors.black),
                      Certifications(address: address, size: 19)
                    ],
                  ),
                ),
              ]),
          const Spacer(),
          Column(children: <Widget>[
            CesiumAvatar(address: address, size: avatarSize),
          ]),
        ]),
      ),
      const OfflineInfo(),
    ]);
  }
}
