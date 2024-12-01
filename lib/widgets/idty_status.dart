import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class IdentityStatus extends StatelessWidget {
  const IdentityStatus({super.key, required this.address, this.isOwner = false, this.color = Colors.black});
  final String address;
  final bool isOwner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final walletData = walletBox.get(address) ?? WalletData(address: address);

    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatus([address]),
          initialData: [walletData.identityStatus],
          builder: (context, AsyncSnapshot<List<IdtyStatus>> snapshot) {
            if (snapshot.data != null && !snapshot.hasError) {
              final resStatus = snapshot.data!.first;
              walletData.identityStatus = resStatus;
              walletBox.put(address, walletData);
            }

            final resStatus = walletData.identityStatus;

            if (!isOwner) {
              if (resStatus == IdtyStatus.unvalidated) {
                return NameByAddress(wallet: walletData, size: 16, color: Colors.grey[700]!, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic);
              } else if (resStatus == IdtyStatus.member) {
                return NameByAddress(wallet: walletData, size: 18, color: Colors.black, fontWeight: FontWeight.w600, fontStyle: FontStyle.normal);
              }
            }

            final Map<IdtyStatus, String> statusText = {
              IdtyStatus.none: '',
              IdtyStatus.unconfirmed: 'identityCreated'.tr(),
              IdtyStatus.unvalidated: 'identityConfirmed'.tr(),
              IdtyStatus.member: 'memberValidated'.tr(),
              IdtyStatus.notMember: 'identityExpired'.tr(),
              IdtyStatus.revoked: 'identityRevoked'.tr(),
              IdtyStatus.unknown: ''
            };

            return SizedBox(
              child: showText(statusText[resStatus]!, bold: resStatus == IdtyStatus.member, size: scaleSize(15)),
            );
          });
    });
  }

  AnimatedFadeOutIn showText(String text, {double size = 18, bool bold = false}) {
    return AnimatedFadeOutIn<String>(
      data: text,
      duration: const Duration(milliseconds: 150),
      builder: (value) => Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size, color: bold ? color : Colors.black, fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
      ),
    );
  }
}
