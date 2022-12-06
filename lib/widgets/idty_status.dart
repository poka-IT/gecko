import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/animated_text.dart';
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

    showText(String text,
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

    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus(address),
          initialData: '',
          builder: (context, snapshot) {
            duniterIndexer.idtyStatusCache[address] = snapshot.data.toString();
            switch (snapshot.data.toString()) {
              case 'noid':
                {
                  return showText('noIdentity'.tr());
                }
              case 'Created':
                {
                  return showText('identityCreated'.tr());
                }
              case 'ConfirmedByOwner':
                {
                  return isOwner
                      ? showText('identityConfirmed'.tr())
                      : duniterIndexer.getNameByAddress(
                          context,
                          address,
                          null,
                          20,
                          true,
                          Colors.grey[700]!,
                          FontWeight.w500,
                          FontStyle.italic);
                }

              case 'Validated':
                {
                  return isOwner
                      ? showText('memberValidated'.tr(), 18, true)
                      : duniterIndexer.getNameByAddress(
                          context,
                          address,
                          null,
                          20,
                          true,
                          Colors.black,
                          FontWeight.w600,
                          FontStyle.normal);
                }

              case 'expired':
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
}
