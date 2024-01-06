import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
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
    const double avatarSize = 110;
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    return Stack(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        bool isAccountExist = walletOptions.balanceCache[address] != 0;
        return Container(
            height: scaleSize(160),
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
        padding: EdgeInsets.only(left: scaleSize(19), right: scaleSize(19)),
        child: Row(children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 5,
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
                      style: scaledTextStyle(
                        fontSize: 23,
                        fontFamily: 'Monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ]),
                ScaledSizedBox(height: 15),
                Balance(address: address, size: 20),
                ScaledSizedBox(
                  height: 60,
                  child: Column(
                    children: [
                      ScaledSizedBox(height: 5),
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
                            Certifications(address: address, size: 18)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
          const Spacer(),
          // ScaledSizedBox(width: 20),
          Column(children: <Widget>[
            ScaledSizedBox(height: 15),
            DatapodAvatar(address: address, size: avatarSize),
          ]),
        ]),
      ),
      const OfflineInfo(),
    ]);
  }
}
