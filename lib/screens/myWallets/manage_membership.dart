// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
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
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: SizedBox(
              height: 22,
              child: const Text('manageMembership').tr(),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 20),
            migrateIdentity(context),
            const SizedBox(height: 10),
            FutureBuilder(
                future: sub.isSmith(address),
                builder: (BuildContext context, AsyncSnapshot<bool> isSmith) {
                  if (isSmith.data ?? false) {
                    return SizedBox(
                        height: 70,
                        child: Row(
                          children: <Widget>[
                            const SizedBox(width: 20),
                            Image.asset(
                              'assets/skull_Icon.png',
                              color: Colors.grey[500],
                              height: 30,
                            ),
                            const SizedBox(width: 16),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('revokeMyIdentity'.tr(),
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.grey[500])),
                                  const SizedBox(height: 5),
                                  Text("youCannotRevokeThisIdentity".tr(),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500])),
                                ]),
                          ],
                        ));
                  } else {
                    return revokeMyIdentity(context);
                  }
                })
            // const SizedBox(height: 20),
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
      child: const SizedBox(
        height: 60,
        child: Row(children: <Widget>[
          SizedBox(width: 16),
          Icon(Icons.change_circle_outlined, size: 35),
          SizedBox(width: 11.5),
          Text('Migrer mon identité', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context) {
    return InkWell(
      key: keyRevokeIdty,
      onTap: () async {
        // TODOO: Generate revoke document, and understand extrinsic identity.revokeIdentity options
        final answer = await confirmPopup(context,
                'Êtes-vous certains de vouloir révoquer définitivement cette identité ?') ??
            false;

        if (answer) {
          final myWalletProvider =
              Provider.of<MyWalletsProvider>(context, listen: false);
          final sub = Provider.of<SubstrateSdk>(context, listen: false);

          // MyWalletsProvider mw = MyWalletsProvider();
          // final wallet = mw.getWalletDataByAddress(address);
          // await sub.setCurrentWallet(wallet!);

          WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
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
            sub.revokeIdentity(address, myWalletProvider.pinCode);
          }
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return TransactionInProgress(
                  transType: 'revokeIdty',
                  fromAddress: getShortPubkey(address),
                  toAddress: getShortPubkey(address));
            }),
          );
        }
      },
      child: SizedBox(
        height: 60,
        child: Row(children: <Widget>[
          const SizedBox(width: 20),
          Image.asset(
            'assets/skull_Icon.png',
            height: 30,
          ),
          const SizedBox(width: 16),
          const Text('Révoquer mon adhésion', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }
}
