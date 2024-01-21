// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/wallet_data.dart';
// import 'package:gecko/providers/my_wallets.dart';
// import 'package:gecko/providers/substrate_sdk.dart';
// import 'package:gecko/screens/common_elements.dart';
// import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
// import 'package:gecko/screens/transaction_in_progress.dart';
// import 'package:provider/provider.dart';

class ManageMembership extends StatelessWidget {
  const ManageMembership({Key? key, required this.address}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('manageMembership'.tr()),
        body: SafeArea(
          child: Column(children: <Widget>[
            ScaledSizedBox(height: 20),
            migrateIdentity(context),
            ScaledSizedBox(height: 10),
            FutureBuilder(
                future: sub.isSmith(address),
                builder: (BuildContext context, AsyncSnapshot<bool> isSmith) {
                  if (isSmith.data ?? false) {
                    return ScaledSizedBox(
                        height: 75,
                        child: Row(
                          children: <Widget>[
                            ScaledSizedBox(width: 17),
                            Image.asset(
                              'assets/skull_Icon.png',
                              color: Colors.grey[500],
                              height: scaleSize(28),
                            ),
                            ScaledSizedBox(width: 12),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('revokeMyIdentity'.tr(),
                                      style: scaledTextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[500])),
                                  ScaledSizedBox(height: 2),
                                  Text("youCannotRevokeThisIdentity".tr(),
                                      style: scaledTextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500])),
                                ]),
                          ],
                        ));
                  } else {
                    return revokeMyIdentity(context);
                  }
                })
          ]),
        ));
  }

  Widget migrateIdentity(BuildContext context) {
    return InkWell(
      key: keyMigrateIdentity,
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const MigrateIdentityScreen();
          }),
        );
      },
      child: ScaledSizedBox(
        height: 55,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 16),
          Icon(Icons.change_circle_outlined, size: scaleSize(32)),
          ScaledSizedBox(width: 11.5),
          Text('Migrer mon identité', style: scaledTextStyle(fontSize: 18)),
        ]),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context) {
    return InkWell(
      key: keyRevokeIdty,
      onTap: () async {
        final answer = await confirmPopup(context,
                'Êtes-vous certains de vouloir révoquer définitivement cette identité ?') ??
            false;

        if (!answer) return;
        final myWalletProvider =
            Provider.of<MyWalletsProvider>(context, listen: false);
        final sub = Provider.of<SubstrateSdk>(context, listen: false);

        if (!await myWalletProvider.askPinCode()) return;

        final transactionId =
            await sub.revokeIdentity(address, myWalletProvider.pinCode);

        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return TransactionInProgress(
                transactionId: transactionId,
                transType: 'revokeIdty',
                fromAddress: getShortPubkey(address),
                toAddress: getShortPubkey(address));
          }),
        );
      },
      child: ScaledSizedBox(
        height: 55,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 20),
          Image.asset(
            'assets/skull_Icon.png',
            height: scaleSize(28),
          ),
          ScaledSizedBox(width: 16),
          Text('Révoquer mon adhésion', style: scaledTextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}
