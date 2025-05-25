// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
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
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('manageMembership'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                FutureBuilder(
                  future: sub.isSmith(address),
                  builder: (BuildContext context, AsyncSnapshot<bool> isSmith) {
                    if (isSmith.data ?? false) {
                      return Container(
                        height: scaleSize(64),
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(18)),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/skull_Icon.png',
                              height: scaleSize(24),
                              color: Colors.grey[400],
                            ),
                            ScaledSizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'revokeMyIdentity'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  Text(
                                    "youCannotRevokeThisIdentity".tr(),
                                    style: scaledTextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return revokeMyIdentity(context);
                    }
                  },
                ),
                ScaledSizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget migrateIdentity(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyMigrateIdentity,
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const MigrateIdentityScreen();
            }),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Icon(
                Icons.change_circle_outlined,
                size: scaleSize(24),
                color: context.colorScheme.onSurface,
              ),
              ScaledSizedBox(width: 16),
              Text(
                'Migrer mon identité',
                style: scaledTextStyle(
                  fontSize: 16,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyRevokeIdty,
        onTap: () async {
          final answer = await showConfirmationDialog(
            context: context,
            message: 'areYouSureYouWantToRevokeIdentity'.tr(),
            type: ConfirmationDialogType.warning,
          );

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Image.asset(
                'assets/skull_Icon.png',
                height: scaleSize(24),
              ),
              ScaledSizedBox(width: 16),
              Text(
                'revokeMyIdentity'.tr(),
                style: scaledTextStyle(
                  fontSize: 16,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget renewMembership(BuildContext context, MembershipStatus status) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final info = MembershipRenewal.calculateRenewalInfo(
      status,
      sub.currencyParameters['membershipRenewalPeriod']!,
    );
    if (info.expireDate == null && status.idtyStatus != IdtyStatus.notMember) return const SizedBox.shrink();

    return Container(
      height: scaleSize(64),
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyRenewMembership,
        onTap: info.canRenew ? () => MembershipRenewal.executeRenewal(context, address) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
          child: Row(
            children: [
              Image.asset(
                'assets/medal.png',
                height: scaleSize(24),
                color: info.canRenew ? context.colorScheme.onSurface : Colors.grey[400],
              ),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'renewMembership'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: info.canRenew ? context.colorScheme.onSurface : Colors.grey[500],
                      ),
                    ),
                    MembershipRenewal.buildExpirationText(info),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
