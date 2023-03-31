import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class IdentityStatus extends StatelessWidget {
  const IdentityStatus(
      {Key? key,
      required this.address,
      this.isOwner = false,
      this.color = Colors.black})
      : super(key: key);
  final String address;
  final bool isOwner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final walletData = walletBox.get(address) ?? WalletData(address: address);

    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus(address),
          initialData: '',
          builder: (context, snapshot) {
            duniterIndexer.idtyStatusCache[address] = snapshot.data.toString();
            switch (snapshot.data.toString()) {
              case 'noid':
                walletData.isMember = false;
                walletBox.put(address, walletData);
                {
                  return showText('noIdentity'.tr());
                }
              case 'Created':
                walletData.isMember = false;
                walletBox.put(address, walletData);
                {
                  return showText('identityCreated'.tr());
                }
              case 'ConfirmedByOwner':
                walletData.isMember = false;
                walletBox.put(address, walletData);
                {
                  return isOwner
                      ? showText('identityConfirmed'.tr())
                      : NameByAddress(
                          wallet: WalletData(address: address),
                          size: 20,
                          color: Colors.grey[700]!,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic);
                }
              case 'Validated':
                walletData.isMember = true;
                walletBox.put(address, walletData);
                {
                  return isOwner
                      ? showText('memberValidated'.tr(), 18, true)
                      : NameByAddress(
                          wallet: WalletData(address: address),
                          size: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.normal);
                }
              case 'expired':
                walletData.isMember = false;
                walletBox.put(address, walletData);
                {
                  return showText('identityExpired'.tr());
                }
            }
            return SizedBox(
              child: showText('', 18, false, false),
            );
          });
    });
  }

  AnimatedFadeOutIn showText(String text,
      [double size = 18, bool bold = false, bool smooth = true]) {
    // log.d('$address $text');
    return AnimatedFadeOutIn<String>(
      data: text,
      duration: Duration(milliseconds: smooth ? 200 : 0),
      builder: (value) => Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: size,
            color: bold ? color : Colors.black,
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
      ),
    );
  }
}
