// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity, MembershipStatus, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/widgets/smart_avatar.dart';
import 'package:gecko/screens/identity/confirm_identity.dart';
import 'package:gecko/utils/identity_utils.dart';

class WalletOptions extends ConsumerStatefulWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet}) : super(key: keyMyWallets);
  final WalletEntity wallet;

  @override
  ConsumerState<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends ConsumerState<WalletOptions> {
  late String currentWalletName;

  @override
  void initState() {
    super.initState();
    currentWalletName = widget.wallet.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider = old_provider.Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    walletOptions.address.text = widget.wallet.address;

    final currentSafe = myWalletProvider.getCurrentSafe;
    final isWalletNameIndexed = ref.read(squidServiceProvider).walletNameIndexer[walletOptions.address.text] != null;

    final isAlone = myWalletProvider.listWallets.length == 1;

    final defaultWallet = myWalletProvider.getDefaultWallet();
    walletOptions.isDefaultWallet = defaultWallet.address == widget.wallet.address;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        walletOptions.isEditing = false;
        // Reload wallets from database to catch avatar updates
        myWalletProvider.readAllWallets();
        myWalletProvider.reload();
      },
      child: Scaffold(
        appBar: WalletAppBar(
          address: widget.wallet.address,
          title: isWalletNameIndexed
              ? ref.read(squidServiceProvider).walletNameIndexer[walletOptions.address.text]!
              : currentWalletName,
        ),
        body: Column(
          children: [
            WalletHeader(
              address: widget.wallet.address,
              customImagePath: widget.wallet.imagePath,
              defaultImagePath: widget.wallet.imagePath,
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
                      old_provider.Consumer<WalletOptionsProvider>(
                        builder: (context, walletProvider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              buildConfirmIdentitySection(context, ref, walletProvider),
                              if (IdentityUtils.hasIdentity(ref, widget.wallet.address))
                                buildRenewMembershipSection(context, ref, walletProvider),
                              buildOptionsSection(context, walletProvider, historyProvider),
                              if (!isAlone)
                                buildDefaultWalletSection(
                                  context,
                                  ref,
                                  walletProvider,
                                  myWalletProvider,
                                  walletOptions,
                                  currentSafe,
                                ),
                              if (!IdentityUtils.hasIdentity(ref, widget.wallet.address))
                                InkWell(
                                  key: keyRenameWallet,
                                  onTap: () async {
                                    await walletProvider.editWalletName(context, widget.wallet);
                                    // Reload wallets data to update the UI
                                    await myWalletProvider.readAllWallets(safeBoxNumber: currentSafe);
                                    // Reload the wallet object to get the updated name
                                    final updatedWallet = myWalletProvider.getWalletDataByAddress(
                                      widget.wallet.address,
                                    );
                                    if (updatedWallet != null) {
                                      widget.wallet.name = updatedWallet.name;
                                      // Update the local state to rebuild the UI
                                      setState(() {
                                        currentWalletName = updatedWallet.name!;
                                      });
                                    }
                                    myWalletProvider.reload();
                                    walletProvider.reload();
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
                                            style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!walletProvider.isDefaultWallet &&
                                  !IdentityUtils.hasIdentity(ref, widget.wallet.address))
                                deleteWallet(context, ref, walletOptions, currentSafe),
                              if (IdentityUtils.hasIdentity(ref, widget.wallet.address)) const ManageMembershipButton(),
                              if (isAlone) aloneWalletOptions(context, ref),
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
          child: SmartAvatar(imagePath: widget.wallet.imagePath!),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(scaleSize(8)),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: InkWell(
              onTap: () async {
                widget.wallet.imagePath = await walletProvider.changeAvatar();
                walletProvider.reload();
              },
              child: Icon(Icons.camera_alt, size: scaleSize(20), color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget activityWidget(
    BuildContext context,
    WalletsProfilesProvider historyProvider,
    WalletOptionsProvider walletProvider,
  ) {
    return InkWell(
      key: keyOpenActivity,
      onTap: () async {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ActivityScreen(address: walletProvider.address.text),
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Smooth slide transition from right to left
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
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
                style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future setDefaultWallet(BuildContext context, WidgetRef ref, int currentSafe) async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);

    await ref.read(walletServiceProvider).setDefaultAddress(walletOptions.address.text);
    await myWalletProvider.readAllWallets(safeBoxNumber: currentSafe);
    myWalletProvider.reload();
    walletOptions.reload();
  }

  Widget deleteWallet(BuildContext context, WidgetRef ref, WalletOptionsProvider walletOptions, int currentSafe) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    final defaultWallet = myWalletProvider.getDefaultWallet();
    final bool isDefaultWallet = walletOptions.address.text == defaultWallet.address;

    // Watch providers for account consumers and balance
    final accountConsumersAsync = ref.watch(smartAccountConsumersProvider(widget.wallet.address));
    final balanceAsync = ref.watch(smartBalanceStreamProvider(widget.wallet.address));

    // Use Riverpod .when() to handle loading/error/data states
    return accountConsumersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (hasConsumers) {
        return balanceAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (walletBalance) {
            final BigInt balance = walletBalance.transferableBalance;

            final bool canDelete =
                !isDefaultWallet &&
                !hasConsumers &&
                (balance > BigInt.from(2) || balance == BigInt.zero) &&
                !IdentityUtils.hasIdentity(ref, widget.wallet.address);

            return InkWell(
              key: keyDeleteWallet,
              onTap: canDelete
                  ? () async {
                      await walletOptions.deleteWallet(context, widget.wallet);
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        myWalletProvider.listWallets = await myWalletProvider.readAllWallets(
                          safeBoxNumber: currentSafe,
                        );
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
                              style: scaledTextStyle(fontSize: 16, color: const Color(0xffD80000)),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  Widget buildRenewMembershipSection(BuildContext context, WidgetRef ref, WalletOptionsProvider walletProvider) {
    return FutureBuilder<MembershipStatus>(
      future: ref.read(storageServiceProvider).getMembershipStatus(walletProvider.address.text),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final info = MembershipRenewal.calculateRenewalInfo(snapshot.data!);

        final twentyDaysBeforeExpiration = info.expireDate?.subtract(const Duration(days: 20));
        final shouldHideButton =
            !info.canRenew ||
            (info.expireDate != null && !(twentyDaysBeforeExpiration?.isBefore(DateTime.now()) ?? false));

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
                    backgroundColor: context.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => MembershipRenewal.executeRenewal(context, ref, walletProvider.address.text),
                  child: Text('renewMembership'.tr(), style: scaledTextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              ScaledSizedBox(height: 8),
              MembershipRenewal.buildExpirationText(info, width: 250),
            ],
          ),
        );
      },
    );
  }

  Widget buildOptionsSection(
    BuildContext context,
    WalletOptionsProvider walletProvider,
    WalletsProfilesProvider historyProvider,
  ) {
    return activityWidget(context, historyProvider, walletProvider);
  }

  Widget buildDefaultWalletSection(
    BuildContext context,
    WidgetRef ref,
    WalletOptionsProvider walletProvider,
    MyWalletsProvider myWalletProvider,
    WalletOptionsProvider walletOptions,
    int currentSafe,
  ) {
    return old_provider.Consumer<MyWalletsProvider>(
      builder: (context, myWalletProvider, _) {
        return InkWell(
          key: keySetDefaultWallet,
          onTap: !walletProvider.isDefaultWallet
              ? () async {
                  await setDefaultWallet(context, ref, currentSafe);
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
                  color: walletProvider.isDefaultWallet ? Colors.grey[400] : greenColor.withValues(alpha: 0.8),
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    walletProvider.isDefaultWallet ? 'thisWalletIsDefault'.tr() : 'defineWalletAsDefault'.tr(),
                    style: scaledTextStyle(
                      fontSize: 16,
                      color: walletProvider.isDefaultWallet ? Colors.grey[500] : context.colorScheme.onSurface,
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

  Widget buildConfirmIdentitySection(BuildContext context, WidgetRef ref, WalletOptionsProvider walletProvider) {
    // Use hybrid provider to handle identity creation (same as wallet header)
    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(walletProvider.address.text));

    return idtyStatusAsync.when(
      data: (idtyStatus) => Visibility(
        visible: idtyStatus == IdtyStatus.created,
        child: Column(
          children: [
            ScaledSizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: scaleSize(50),
              child: ElevatedButton(
                key: keyConfirmIdentity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmIdentityScreen(address: walletProvider.address.text),
                    ),
                  );
                },
                child: Text('confirmMyIdentity'.tr(), style: scaledTextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            ScaledSizedBox(height: 8),
            Text(
              "someoneCreatedYourIdentity".tr(args: [Durt.i.network.symbol]),
              style: scaledTextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            ScaledSizedBox(height: 24),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(), // Hide while loading
      error: (_, _) => const SizedBox.shrink(), // Hide on error
    );
  }
}

Widget aloneWalletOptions(BuildContext context, WidgetRef ref) {
  final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
  return Column(
    children: [
      InkWell(
        onTap: () async {
          if (!await myWalletProvider.askPinCode()) return;
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SafeOptions()));
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/safes/config.png', height: scaleSize(24)),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Text(
                  'manageSafe'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[500],
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
      InkWell(
        onTap: () async {
          if (!myWalletProvider.isNewDerivationLoading) {
            if (!await myWalletProvider.askPinCode()) return;
            String newDerivationName = '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number + 2}';
            await myWalletProvider.generateNewDerivation(context, newDerivationName);
            Navigator.pushReplacementNamed(context, RouteNames.myWallets);
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
                color: ref.read(durtProvider).isConnected ? greenColor.withValues(alpha: 0.8) : Colors.grey[400],
              ),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Text(
                  'createNewWallet'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[500],
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
      InkWell(
        onTap: () async {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SwitchSafe()));
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: scaleSize(24), color: context.colorScheme.onSurface.withValues(alpha: 0.8)),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Text(
                  'changeSafe'.tr(),
                  style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
      InkWell(
        onTap: () async {
          Navigator.push(homeContext, MaterialPageRoute(builder: (context) => const ImportG1v1()));
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
          child: Row(
            children: [
              SvgPicture.asset('assets/cesium_bw2.svg', height: scaleSize(24)),
              ScaledSizedBox(width: 16),
              Expanded(
                child: Text(
                  'importIdPasswordAccount'.tr(),
                  style: scaledTextStyle(fontSize: 16, color: homeContext.colorScheme.onSurface),
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
