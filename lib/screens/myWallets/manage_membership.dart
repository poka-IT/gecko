// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus, MembershipStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/models/membership_renewal.dart';

class ManageMembership extends ConsumerWidget {
  const ManageMembership({super.key, required this.address});
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  future: ref.read(storageServiceProvider).getMembershipStatus(address),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return renewMembership(context, ref, snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                FutureBuilder(
                  future: ref.read(storageServiceProvider).isSmith(address),
                  builder: (BuildContext context, AsyncSnapshot<bool> isSmith) {
                    if (isSmith.data ?? false) {
                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                              child: Row(
                                children: [
                                  Icon(Icons.change_circle_outlined, size: scaleSize(24), color: Colors.grey[400]),
                                  ScaledSizedBox(width: 16),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Migrer mon identité',
                                        style: scaledTextStyle(fontSize: 16, color: Colors.grey[500]),
                                      ),
                                      Text(
                                        "youCannotMigrateThisIdentity".tr(),
                                        style: scaledTextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: scaleSize(64),
                            padding: EdgeInsets.symmetric(horizontal: scaleSize(18)),
                            child: Row(
                              children: [
                                Image.asset('assets/skull_Icon.png', height: scaleSize(24), color: Colors.grey[400]),
                                ScaledSizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'revokeMyIdentity'.tr(),
                                        style: scaledTextStyle(fontSize: 16, color: Colors.grey[500]),
                                      ),
                                      Text(
                                        "youCannotRevokeThisIdentity".tr(),
                                        style: scaledTextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(children: [migrateIdentity(context), revokeMyIdentity(context, ref)]);
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
            MaterialPageRoute(
              builder: (context) {
                return MigrateIdentityScreen();
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Icon(Icons.change_circle_outlined, size: scaleSize(24), color: context.colorScheme.onSurface),
              ScaledSizedBox(width: 16),
              Text('Migrer mon identité', style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context, WidgetRef ref) {
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
          final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

          if (!await myWalletProvider.askPinCode()) return;

          final keypair = await ref
              .read(walletServiceProvider)
              .getKeyPairFromAddress(address: address, pinCode: myWalletProvider.pinCode);
          final transactionStatus = ref.read(duniterServiceProvider).revokeIdentity(keypair);

          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return TransactionInProgressScreen(
                  transactionStatus: transactionStatus,
                  transType: 'revokeIdty',
                  fromAddress: getShortPubkey(address),
                  toAddress: getShortPubkey(address),
                );
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              Image.asset('assets/skull_Icon.png', height: scaleSize(24)),
              ScaledSizedBox(width: 16),
              Text('revokeMyIdentity'.tr(), style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget renewMembership(BuildContext context, WidgetRef ref, MembershipStatus status) {
    final info = MembershipRenewal.calculateRenewalInfo(status);
    if (info.expireDate == null && status.idtyStatus != IdtyStatus.expired) return const SizedBox.shrink();

    return Container(
      height: scaleSize(64),
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: InkWell(
        key: keyRenewMembership,
        onTap: info.canRenew ? () => MembershipRenewal.executeRenewal(context, ref, address) : null,
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
