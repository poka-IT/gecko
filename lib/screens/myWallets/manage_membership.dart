// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/membership_status.dart';
import 'package:gecko/models/membership_renewal.dart';

class ManageMembership extends StatelessWidget {
  const ManageMembership({super.key, required this.address});
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
          FutureBuilder<MembershipStatus>(
            future: sub.getMembershipStatus(address),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return renewMembership(context, snapshot.data!);
              }
              return const SizedBox.shrink();
            },
          ),
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
                      ScaledSizedBox(width: 25),
                      Image.asset(
                        'assets/skull_Icon.png',
                        color: Colors.grey[500],
                        height: scaleSize(28),
                      ),
                      ScaledSizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('revokeMyIdentity'.tr(), style: scaledTextStyle(fontSize: 17, color: Colors.grey[500])),
                          ScaledSizedBox(height: 2),
                          Text("youCannotRevokeThisIdentity".tr(), style: scaledTextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                return revokeMyIdentity(context);
              }
            },
          ),
        ]),
      ),
    );
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
          ScaledSizedBox(width: 20),
          Icon(Icons.change_circle_outlined, size: scaleSize(32)),
          ScaledSizedBox(width: 16),
          Text('Migrer mon identité', style: scaledTextStyle(fontSize: 17)),
        ]),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context) {
    return InkWell(
      key: keyRevokeIdty,
      onTap: () async {
        final answer = await confirmPopup(context, 'areYouSureYouWantToRevokeIdentity'.tr()) ?? false;

        if (!answer) return;
        final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
        final sub = Provider.of<SubstrateSdk>(context, listen: false);

        if (!await myWalletProvider.askPinCode()) return;

        final transactionId = await sub.revokeIdentity(address, myWalletProvider.pinCode);

        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return TransactionInProgress(
                transactionId: transactionId, transType: 'revokeIdty', fromAddress: getShortPubkey(address), toAddress: getShortPubkey(address));
          }),
        );
      },
      child: ScaledSizedBox(
        height: 55,
        child: Row(children: <Widget>[
          ScaledSizedBox(width: 25),
          Image.asset(
            'assets/skull_Icon.png',
            height: scaleSize(28),
          ),
          ScaledSizedBox(width: 20),
          Text('revokeMyIdentity'.tr(), style: scaledTextStyle(fontSize: 17)),
        ]),
      ),
    );
  }

  Widget renewMembership(BuildContext context, MembershipStatus status) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final info = MembershipRenewal.calculateRenewalInfo(
      status,
      sub.currencyParameters['membershipRenewalPeriod']!,
    );

    if (info.expireDate == null) return const SizedBox.shrink();

    return ScaledSizedBox(
      height: 75,
      child: InkWell(
        key: keyRenewMembership,
        onTap: info.canRenew ? () => MembershipRenewal.executeRenewal(context, address) : null,
        child: Row(
          children: <Widget>[
            ScaledSizedBox(width: 20),
            Image.asset(
              'assets/medal.png',
              height: scaleSize(28),
              color: info.canRenew ? null : Colors.grey[500],
            ),
            ScaledSizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'renewMembership'.tr(),
                  style: scaledTextStyle(
                    fontSize: 17,
                    color: info.canRenew ? null : Colors.grey[500],
                  ),
                ),
                MembershipRenewal.buildExpirationText(info),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
