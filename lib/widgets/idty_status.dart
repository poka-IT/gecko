import 'package:durt2/durt2.dart' show Durt, IdtyStatus, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class IdentityStatus extends StatelessWidget {
  const IdentityStatus({super.key, required this.address, this.color});
  final String address;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final walletData = Durt.i.walletService.walletDataBox.get(address) ?? WalletData(address: address);
    final finalColor = color ?? context.colorScheme.onSecondaryContainer;

    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
          future: sub.idtyStatusMulti([address]),
          initialData: [walletData.identityStatus],
          builder: (context, AsyncSnapshot<List<IdtyStatus>> snapshot) {
            if (snapshot.data != null && !snapshot.hasError) {
              final resStatus = snapshot.data!.first;
              walletData.identityStatus = resStatus;
              Durt.i.walletService.walletDataBox.put(address, walletData);
            }

            final resStatus = walletData.identityStatus;

            final nameByAddress = resStatus == IdtyStatus.validated
                ? NameByAddress(wallet: walletData, size: 18, color: finalColor, fontWeight: FontWeight.w500, fontStyle: FontStyle.normal)
                : NameByAddress(
                    wallet: walletData, size: 16, color: homeContext.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic);

            final Map<IdtyStatus, String> statusText = {
              IdtyStatus.none: '',
              IdtyStatus.created: 'identityCreated'.tr(),
              IdtyStatus.confirmed: 'identityConfirmed'.tr(),
              IdtyStatus.validated: 'memberValidated'.tr(),
              IdtyStatus.expired: 'identityExpired'.tr(),
              IdtyStatus.revoked: 'identityRevoked'.tr(),
              IdtyStatus.unknown: ''
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameByAddress,
                showText(context, statusText[resStatus]!, bold: resStatus == IdtyStatus.validated, size: scaleSize(15)),
              ],
            );
          });
    });
  }

  AnimatedFadeOutIn showText(BuildContext context, String text, {double size = 18, bool bold = false}) {
    final finalColor = color ?? context.colorScheme.onSecondaryContainer;
    return AnimatedFadeOutIn<String>(
      data: text,
      duration: const Duration(milliseconds: 150),
      builder: (value) => Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size, color: bold ? finalColor : finalColor, fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
      ),
    );
  }
}
