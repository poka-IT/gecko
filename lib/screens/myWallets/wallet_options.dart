// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/membership_status.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/screens/identity/confirm_identity.dart';

class WalletOptions extends StatelessWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet}) : super(key: keyMyWallets);
  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    walletOptions.address.text = wallet.address;

    final currentChest = myWalletProvider.getCurrentChest();
    final isWalletNameIndexed = duniterIndexer.walletNameIndexer[walletOptions.address.text] != null;

    final isAlone = myWalletProvider.listWallets.length == 1;

    final defaultWallet = myWalletProvider.getDefaultWallet();
    walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id[1]);

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        walletOptions.isEditing = false;
        myWalletProvider.reload();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: WalletAppBar(
          address: wallet.address,
          title: isWalletNameIndexed ? duniterIndexer.walletNameIndexer[walletOptions.address.text]! : wallet.name!,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                WalletHeader(
                  address: wallet.address,
                  customImagePath: wallet.imageCustomPath,
                  defaultImagePath: wallet.imageDefaultPath,
                ),
                // Corps avec les options
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ScaledSizedBox(height: 16),
                          Consumer<WalletOptionsProvider>(
                            builder: (context, walletProvider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 8,
                                children: [
                                  buildConfirmIdentitySection(walletProvider),
                                  if (wallet.hasIdentity) buildRenewMembershipSection(walletProvider),
                                  buildOptionsSection(context, walletProvider, historyProvider),
                                  if (!isAlone) buildDefaultWalletSection(context, walletProvider, myWalletProvider, walletOptions, currentChest),
                                  if (!wallet.hasIdentity)
                                    InkWell(
                                      key: keyRenameWallet,
                                      onTap: () async {
                                        await walletProvider.editWalletName(context, [wallet.id[0], wallet.id[1]]);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/walletOptions/edit.png',
                                              height: scaleSize(22),
                                              color: const Color(0xFF4A90E2).withValues(alpha: 0.8),
                                            ),
                                            ScaledSizedBox(width: 18),
                                            Expanded(
                                              child: Text(
                                                "editWalletName".tr(),
                                                style: scaledTextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                                softWrap: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!walletProvider.isDefaultWallet && !wallet.hasIdentity) deleteWallet(context, walletProvider, currentChest),
                                  if (wallet.hasIdentity) const ManageMembershipButton(),
                                  if (isAlone) aloneWalletOptions(),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const OfflineInfo(),
          ],
        ),
        bottomNavigationBar: const GeckoBottomAppBar(),
      ),
    );
  }

  Widget buildAvatarSection(WalletOptionsProvider walletProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: scaleSize(100),
          height: scaleSize(100),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                // Soft ambient shadow
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                // Sharper direct shadow
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: wallet.imageCustomPath == null || wallet.imageCustomPath == ''
                ? Image.asset(
                    'assets/avatars/${wallet.imageDefaultPath}',
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(wallet.imageCustomPath!),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(scaleSize(8)),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: () async {
                wallet.imageCustomPath = await walletProvider.changeAvatar();
                walletProvider.reload();
              },
              child: Icon(
                Icons.camera_alt,
                size: scaleSize(20),
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget activityWidget(BuildContext context, WalletsProfilesProvider historyProvider, WalletOptionsProvider walletProvider) {
    return InkWell(
      key: keyOpenActivity,
      onTap: () {
        Navigator.push(
          context,
          PageNoTransit(builder: (context) => ActivityScreen(address: walletProvider.address.text)),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/walletOptions/clock.png',
              height: scaleSize(24),
              color: const Color(0xFF4A90E2).withValues(alpha: 0.8),
            ),
            ScaledSizedBox(width: 16),
            Expanded(
              child: Text(
                "displayActivity".tr(),
                style: scaledTextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future setDefaultWallet(BuildContext context, int currentChest) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);

    await sub.setCurrentWallet(wallet);
    await myWalletProvider.readAllWallets(currentChest);
    myWalletProvider.reload();
    walletOptions.reload();
  }

  Widget deleteWallet(BuildContext context, WalletOptionsProvider walletOptions, int currentChest) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final defaultWallet = myWalletProvider.getDefaultWallet();
    final bool isDefaultWallet = walletOptions.address.text == defaultWallet.address;
    return FutureBuilder(
        future: sub.hasAccountConsumers(wallet.address),
        builder: (BuildContext context, AsyncSnapshot<bool> hasConsumers) {
          if (hasConsumers.connectionState != ConnectionState.done || hasConsumers.hasError || !hasConsumers.hasData) {
            return const SizedBox.shrink();
          }
          final int balance = walletOptions.balanceCache[walletOptions.address.text] ?? -1;
          final bool canDelete = !isDefaultWallet && !hasConsumers.data! && (balance > 2 || balance == 0) && !wallet.hasIdentity;
          return InkWell(
            key: keyDeleteWallet,
            onTap: canDelete
                ? () async {
                    await walletOptions.deleteWallet(context, wallet);
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      myWalletProvider.listWallets = await myWalletProvider.readAllWallets(currentChest);
                      myWalletProvider.reload();
                    });
                  }
                : null,
            child: canDelete
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/walletOptions/trash.png',
                          height: scaleSize(24),
                          color: const Color(0xffD80000),
                        ),
                        ScaledSizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'deleteThisWallet'.tr(),
                            style: scaledTextStyle(
                              fontSize: 16,
                              color: const Color(0xffD80000),
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          );
        });
  }

  Widget buildRenewMembershipSection(WalletOptionsProvider walletProvider) {
    return Consumer<SubstrateSdk>(
      builder: (context, sub, _) {
        return FutureBuilder<MembershipStatusDeprecated>(
          future: sub.getMembershipStatus(walletProvider.address.text),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox.shrink();
            }

            final info = MembershipRenewal.calculateRenewalInfo(
              snapshot.data!,
              sub.currencyParameters['membershipRenewalPeriod']!,
            );

            final twentyDaysBeforeExpiration = info.expireDate?.subtract(const Duration(days: 20));
            final shouldHideButton = !info.canRenew || (info.expireDate != null && !(twentyDaysBeforeExpiration?.isBefore(DateTime.now()) ?? false));

            if (shouldHideButton) return const SizedBox.shrink();

            return Container(
              margin: EdgeInsets.only(bottom: scaleSize(24)),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: scaleSize(50),
                    child: ElevatedButton(
                      key: keyRenewMembership,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeC,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => MembershipRenewal.executeRenewal(context, walletProvider.address.text),
                      child: Text(
                        'renewMembership'.tr(),
                        style: scaledTextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  ScaledSizedBox(height: 8),
                  MembershipRenewal.buildExpirationText(info, width: 250),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildOptionsSection(BuildContext context, WalletOptionsProvider walletProvider, WalletsProfilesProvider historyProvider) {
    return activityWidget(context, historyProvider, walletProvider);
  }

  Widget buildDefaultWalletSection(
      BuildContext context, WalletOptionsProvider walletProvider, MyWalletsProvider myWalletProvider, WalletOptionsProvider walletOptions, int currentChest) {
    return Consumer<MyWalletsProvider>(
      builder: (context, myWalletProvider, _) {
        return InkWell(
          key: keySetDefaultWallet,
          onTap: !walletProvider.isDefaultWallet
              ? () async {
                  await setDefaultWallet(context, currentChest);
                  walletProvider.isDefaultWallet = true;
                }
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: scaleSize(24),
                  color: walletProvider.isDefaultWallet ? Colors.grey[400] : const Color(0xFF4CAF50).withValues(alpha: 0.8),
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    walletProvider.isDefaultWallet ? 'thisWalletIsDefault'.tr() : 'defineWalletAsDefault'.tr(),
                    style: scaledTextStyle(
                      fontSize: 16,
                      color: walletProvider.isDefaultWallet ? Colors.grey[500] : Colors.black87,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildConfirmIdentitySection(WalletOptionsProvider walletProvider) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
        future: sub.idtyStatusMulti([walletProvider.address.text]),
        initialData: const [IdtyStatus.unknown],
        builder: (BuildContext context, AsyncSnapshot<List<IdtyStatus>> snapshot) {
          return Visibility(
            visible: snapshot.hasData && !snapshot.hasError && snapshot.data!.first == IdtyStatus.unconfirmed,
            child: Column(children: [
              ScaledSizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: scaleSize(50),
                child: ElevatedButton(
                  key: keyConfirmIdentity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeC,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmIdentityScreen(
                          address: walletProvider.address.text,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'confirmMyIdentity'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              ScaledSizedBox(height: 8),
              Text(
                "someoneCreatedYourIdentity".tr(args: [currencyName]),
                style: scaledTextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              ScaledSizedBox(height: 24),
            ]),
          );
        },
      );
    });
  }
}

Widget aloneWalletOptions() {
  return Column(
    children: [
      const ChestOptionsContent(),
      Consumer<SubstrateSdk>(
        builder: (context, sub, _) {
          final myWalletProvider = Provider.of<MyWalletsProvider>(context);
          return InkWell(
            onTap: () async {
              if (!myWalletProvider.isNewDerivationLoading) {
                if (!await myWalletProvider.askPinCode()) return;
                String newDerivationName = '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
                await myWalletProvider.generateNewDerivation(context, newDerivationName);
                Navigator.pushReplacementNamed(context, '/mywallets');
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: scaleSize(24),
                    color: sub.nodeConnected ? Color(0xFF4CAF50).withValues(alpha: 0.8) : Colors.grey[400],
                  ),
                  ScaledSizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'createNewWallet'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: sub.nodeConnected ? Colors.black87 : Colors.grey[500],
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      InkWell(
        onTap: () async {
          Navigator.push(
            homeContext,
            MaterialPageRoute(builder: (context) => const ImportG1v1()),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/cesium_bw2.svg',
                height: scaleSize(24),
              ),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Text(
                  'importIdPasswordAccount'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
