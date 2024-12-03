// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/models/membership_renewal.dart';

class WalletOptions extends StatelessWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet}) : super(key: keyMyWallets);
  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    walletOptions.address.text = wallet.address;

    final currentChest = myWalletProvider.getCurrentChest();
    final isWalletNameIndexed = duniterIndexer.walletNameIndexer[walletOptions.address.text] != null;

    final isAlone = myWalletProvider.listWallets.length == 1;

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        walletOptions.isEditing = false;
        walletOptions.isBalanceBlur = false;
        myWalletProvider.reload();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: headerColor,
          elevation: 0,
          title: Consumer<WalletOptionsProvider>(builder: (context, walletProvider, _) {
            return Text(
              isWalletNameIndexed ? duniterIndexer.walletNameIndexer[walletOptions.address.text]! : wallet.name!,
              style: scaledTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            );
          }),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QrCodeFullscreen(walletOptions.address.text)),
                  );
                },
                child: QrImageView(
                  data: walletOptions.address.text,
                  version: QrVersions.auto,
                  size: scaleSize(45),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // En-tête avec avatar et informations
                Container(
                  color: headerColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: scaleSize(16),
                    vertical: scaleSize(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildAvatarSection(walletOptions),
                      SizedBox(width: scaleSize(20)),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: scaleSize(26),
                                    child: Consumer<WalletOptionsProvider>(
                                      builder: (context, walletProvider, _) {
                                        return Row(
                                          children: [
                                            NameByAddress(
                                              wallet: wallet,
                                              size: 20,
                                              color: Colors.black87,
                                              fontWeight: wallet.identityStatus == IdtyStatus.member ? FontWeight.w600 : FontWeight.w400,
                                            ),
                                            if (duniterIndexer.walletNameIndexer[wallet.address] == null)
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(
                                                  walletProvider.isEditing ? Icons.check : Icons.edit,
                                                  size: scaleSize(18),
                                                ),
                                                onPressed: () async {
                                                  await walletProvider.editWalletName(context, wallet.id);
                                                },
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  if (!wallet.hasIdentity) const SizedBox(height: 16),
                                  Balance(
                                    address: walletOptions.address.text,
                                    size: 24,
                                  ),
                                  if (wallet.hasIdentity) ...[
                                    SizedBox(height: scaleSize(12)),
                                    InkWell(
                                      onTap: () => sub.certsCounterCache[walletOptions.address.text] != null
                                          ? Navigator.push(
                                              context,
                                              PageNoTransit(
                                                builder: (context) => CertificationsScreen(
                                                  address: walletOptions.address.text,
                                                  username: duniterIndexer.walletNameIndexer[walletOptions.address.text] ?? '',
                                                ),
                                              ),
                                            )
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.transparent,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IdentityStatus(
                                              address: walletOptions.address.text,
                                              isOwner: true,
                                              color: orangeC,
                                            ),
                                            SizedBox(width: scaleSize(8)),
                                            Certifications(
                                              address: walletOptions.address.text,
                                              size: 14,
                                            ),
                                            if (sub.certsCounterCache[walletOptions.address.text] != null) ...[
                                              SizedBox(width: scaleSize(4)),
                                              Icon(
                                                Icons.chevron_right,
                                                size: scaleSize(16),
                                                color: orangeC.withOpacity(0.8),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Corps avec les options
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScaledSizedBox(height: 24),
                          Consumer<WalletOptionsProvider>(
                            builder: (context, walletProvider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildConfirmIdentitySection(walletProvider),
                                  if (wallet.isMembre) buildRenewMembershipSection(walletProvider),
                                  buildOptionsSection(context, walletProvider, historyProvider),
                                  if (!isAlone) buildDefaultWalletSection(context, walletProvider, myWalletProvider, walletOptions, currentChest),
                                  buildDangerZone(context, walletProvider, currentChest),
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
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

  Widget pubkeyWidget(WalletOptionsProvider walletProvider, BuildContext ctx) {
    final shortPubkey = getShortPubkey(walletProvider.address.text);
    return Container(
      height: scaleSize(48),
      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
      child: Row(
        children: [
          Image.asset(
            'assets/walletOptions/key.png',
            height: scaleSize(24),
            color: Colors.black87,
          ),
          ScaledSizedBox(width: 16),
          Expanded(
            child: Text(
              shortPubkey,
              style: scaledTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Monospace',
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.copy,
              size: scaleSize(20),
              color: orangeC.withOpacity(0.8),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: walletProvider.address.text));
              snackCopyKey(ctx);
            },
          ),
        ],
      ),
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
        height: scaleSize(48),
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
        child: Row(
          children: [
            Image.asset(
              'assets/walletOptions/clock.png',
              height: scaleSize(24),
              color: const Color(0xFF4A90E2).withOpacity(0.8),
            ),
            ScaledSizedBox(width: 16),
            Text(
              "displayActivity".tr(),
              style: scaledTextStyle(
                fontSize: 16,
                color: Colors.black87,
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
          final double balance = walletOptions.balanceCache[walletOptions.address.text] ?? -1;
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
                    height: scaleSize(48),
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/walletOptions/trash.png',
                          height: scaleSize(24),
                          color: const Color(0xffD80000),
                        ),
                        ScaledSizedBox(width: 16),
                        Text(
                          'deleteThisWallet'.tr(),
                          style: scaledTextStyle(
                            fontSize: 16,
                            color: const Color(0xffD80000),
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
        return FutureBuilder<MembershipStatus>(
          future: sub.getMembershipStatus(walletProvider.address.text),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return const SizedBox.shrink();
            }

            final info = MembershipRenewal.calculateRenewalInfo(
              snapshot.data!,
              sub.currencyParameters['membershipRenewalPeriod']!,
            );

            final twoMonthsBeforeExpiration = info.expireDate?.subtract(const Duration(days: 60));
            final shouldHideButton = !info.canRenew || !(twoMonthsBeforeExpiration?.isBefore(DateTime.now()) ?? false);

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
    return Column(
      children: [
        pubkeyWidget(walletProvider, context),
        ScaledSizedBox(height: 4),
        activityWidget(context, historyProvider, walletProvider),
        ScaledSizedBox(height: 4),
      ],
    );
  }

  Widget buildDefaultWalletSection(
      BuildContext context, WalletOptionsProvider walletProvider, MyWalletsProvider myWalletProvider, WalletOptionsProvider walletOptions, int currentChest) {
    return Consumer<MyWalletsProvider>(
      builder: (context, myWalletProvider, _) {
        WalletData defaultWallet = myWalletProvider.getDefaultWallet();
        walletOptions.isDefaultWallet = (defaultWallet.number == wallet.id[1]);
        return InkWell(
          key: keySetDefaultWallet,
          onTap: !walletProvider.isDefaultWallet
              ? () async {
                  await setDefaultWallet(context, currentChest);
                }
              : null,
          child: Container(
            height: scaleSize(48),
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: scaleSize(24),
                  color: walletProvider.isDefaultWallet ? Colors.grey[400] : const Color(0xFF4CAF50).withOpacity(0.8),
                ),
                ScaledSizedBox(width: 16),
                Text(
                  walletProvider.isDefaultWallet ? 'thisWalletIsDefault'.tr() : 'defineWalletAsDefault'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: walletProvider.isDefaultWallet ? Colors.grey[500] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDangerZone(BuildContext context, WalletOptionsProvider walletProvider, int currentChest) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
      child: Column(
        children: [
          if (!walletProvider.isDefaultWallet && !wallet.hasIdentity) deleteWallet(context, walletProvider, currentChest),
          if (wallet.hasIdentity) const ManageMembershipButton(),
        ],
      ),
    );
  }

  Widget buildConfirmIdentitySection(WalletOptionsProvider walletProvider) {
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return FutureBuilder(
        future: sub.idtyStatus([walletProvider.address.text]),
        initialData: const [IdtyStatus.unknown],
        builder: (BuildContext context, AsyncSnapshot<List<IdtyStatus>> snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const SizedBox.shrink();
          }
          if (snapshot.data!.first == IdtyStatus.unconfirmed) {
            return Column(children: [
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
                  onPressed: () => walletProvider.confirmIdentityPopup(context),
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
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              ScaledSizedBox(height: 24),
            ]);
          }
          return const SizedBox.shrink();
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
              height: scaleSize(48),
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: scaleSize(24),
                    color: sub.nodeConnected ? Color(0xFF4CAF50).withOpacity(0.8) : Colors.grey[400],
                  ),
                  ScaledSizedBox(width: 16),
                  Text(
                    'createNewWallet'.tr(),
                    style: scaledTextStyle(
                      fontSize: 16,
                      color: sub.nodeConnected ? Colors.black87 : Colors.grey[500],
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
          height: scaleSize(48),
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/cesium_bw2.svg',
                height: scaleSize(24),
              ),
              ScaledSizedBox(width: 16),
              Text(
                'importG1v1'.tr(),
                style: scaledTextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
