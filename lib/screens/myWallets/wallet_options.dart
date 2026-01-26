// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity, Durt, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_management_service.dart';
import 'package:gecko/services/wallet_deletion_service.dart';
import 'package:gecko/services/wallet_name_dialog_service.dart';
// import 'package:gecko/providers_deprecated/wallets_profiles.dart'; // Removed - no longer needed
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/myWallets/migrate_g1v1_screen.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/screens/identity/confirm_identity.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/routes.dart';

class WalletOptions extends ConsumerStatefulWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet, this.onDerivationCreated}) : super(key: keyMyWallets);
  final WalletEntity wallet;
  final VoidCallback? onDerivationCreated;

  @override
  ConsumerState<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends ConsumerState<WalletOptions> {
  late String currentWalletName;

  bool get isLegacyWallet => widget.wallet.safe.target?.safeType == SafeType.legacy;

  @override
  void initState() {
    super.initState();
    currentWalletName = widget.wallet.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsListProvider);
    final currentSafe = walletsState.currentSafeNumber;
    final isWalletNameIndexed = ref.read(squidServiceProvider).walletNameIndexer[widget.wallet.address] != null;

    final isAlone = walletsState.wallets.length == 1;

    final defaultWallet = ref.watch(defaultWalletProvider);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        // Reload wallets from database to catch avatar updates
        ref.read(walletsListProvider.notifier).loadWallets();
      },
      child: Scaffold(
        appBar: WalletAppBar(
          address: widget.wallet.address,
          title: isWalletNameIndexed
              ? ref.read(squidServiceProvider).walletNameIndexer[widget.wallet.address]!
              : currentWalletName,
        ),
        body: CustomScrollView(
          slivers: [
            // Wallet header as a sliver
            SliverToBoxAdapter(
              child: WalletHeader(
                address: widget.wallet.address,
                customImagePath: widget.wallet.imagePath,
                defaultImagePath: widget.wallet.imagePath,
              ),
            ),
            // Content as a sliver with proper padding
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScaledSizedBox(height: 16), // Add some top spacing
                    if (isLegacyWallet)
                      // Warning about legacy wallet
                      Container(
                        margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                        padding: EdgeInsets.all(scaleSize(12)),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange, size: scaleSize(20)),
                            ScaledSizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'legacyWalletWarning'.tr(),
                                style: scaledTextStyle(fontSize: 13, color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildWalletOptionsContent(context, ref, isAlone, currentSafe, defaultWallet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAvatarSection() {
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
          child: CachedAvatarImage(imagePath: widget.wallet.imagePath!, fit: BoxFit.cover, isCircular: true),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(scaleSize(8)),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: InkWell(
              onTap: () async {
                // Ask for PIN code first if needed
                final pinCodeValid = await PinCodeService.askPinCode();

                if (pinCodeValid) {
                  final newPath = await WalletManagementService.changeAvatar(
                    widget.wallet.address,
                    pinCode: PinCodeService.pinCode,
                  );
                  if (newPath.isNotEmpty) {
                    setState(() {
                      widget.wallet.imagePath = newPath;
                    });
                    // Refresh wallets list to update UI components
                    ref.read(walletsListProvider.notifier).refresh();
                  }
                }
              },
              child: Icon(Icons.camera_alt, size: scaleSize(20), color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget activityWidget(BuildContext context) {
    return InkWell(
      key: keyOpenActivity,
      onTap: () async {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ActivityScreen(address: widget.wallet.address),
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
    await ref.read(walletServiceProvider).setDefaultAddress(widget.wallet.address);
    await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);

    // Invalidate the default wallet provider to trigger reactive updates
    ref.invalidate(defaultWalletProvider);
  }

  Widget deleteWallet(BuildContext context, WidgetRef ref, int currentSafe) {
    // Use the reactive provider for consistency
    final defaultWallet = ref.watch(defaultWalletProvider);
    final bool isDefaultWallet = defaultWallet.address == widget.wallet.address;

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
                      final result = await WalletDeletionService.deleteWallet(context, widget.wallet);
                      if (result == 0) {
                        // Success - wallet was deleted, navigation handled by service
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
                        });
                      }
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

  Widget buildOptionsSection(BuildContext context) {
    return activityWidget(context);
  }

  Widget buildDefaultWalletSection(
    BuildContext context,
    WidgetRef ref,
    int currentSafe,
    WalletEntity defaultWallet,
  ) {
    return InkWell(
      key: keySetDefaultWallet,
      onTap: defaultWallet.address != widget.wallet.address
          ? () async {
              await setDefaultWallet(context, ref, currentSafe);
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
              color: defaultWallet.address == widget.wallet.address
                  ? Colors.grey[400]
                  : greenColor.withValues(alpha: 0.8),
            ),
            ScaledSizedBox(width: 16),
            Expanded(
              child: Text(
                defaultWallet.address == widget.wallet.address
                    ? 'thisWalletIsDefault'.tr()
                    : 'defineWalletAsDefault'.tr(),
                style: scaledTextStyle(
                  fontSize: 16,
                  color: defaultWallet.address == widget.wallet.address
                      ? Colors.grey[500]
                      : context.colorScheme.onSurface,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the wallet options content with reactive identity checks
  Widget _buildWalletOptionsContent(
    BuildContext context,
    WidgetRef ref,
    bool isAlone,
    int currentSafe,
    WalletEntity defaultWallet,
  ) {
    // Watch the identity status to rebuild when it changes
    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(widget.wallet.address));

    return idtyStatusAsync.when(
      data: (idtyStatus) {
        final hasIdentity = idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            buildConfirmIdentitySection(context, ref),
            buildOptionsSection(context),
            if (!isAlone) buildDefaultWalletSection(context, ref, currentSafe, defaultWallet),
            if (!hasIdentity)
              InkWell(
                key: keyRenameWallet,
                onTap: () async {
                  final newName = await WalletNameDialogService.showEditWalletNameDialog(context, widget.wallet);
                  if (newName != null) {
                    // Reload wallets data to update the UI
                    await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
                    // Reload the wallet object to get the updated name
                    final updatedWallet = ref.read(walletByAddressProvider(widget.wallet.address));
                    if (updatedWallet != null) {
                      widget.wallet.name = updatedWallet.name;
                      // Update the local state to rebuild the UI
                      setState(() {
                        currentWalletName = updatedWallet.name!;
                      });
                    }
                  }
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
            // Cesium+ Profile button
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, RouteNames.cesiumProfile, arguments: widget.wallet.address);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: scaleSize(22),
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.8),
                    ),
                    ScaledSizedBox(width: 18),
                    Expanded(
                      child: Text(
                        "cesiumProfile".tr(),
                        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (defaultWallet.address != widget.wallet.address && !hasIdentity && !isAlone)
              deleteWallet(context, ref, currentSafe),
            if (hasIdentity) ManageMembershipButton(address: widget.wallet.address),
            if (isAlone)
              isLegacyWallet
                  ? _buildLegacyWalletOptions()
                  : aloneWalletOptions(context, ref, onDerivationCreated: widget.onDerivationCreated),
            ScaledSizedBox(height: 32), // Add bottom padding for better scrolling
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          buildConfirmIdentitySection(context, ref),
          buildOptionsSection(context),
          if (!isAlone) buildDefaultWalletSection(context, ref, currentSafe, defaultWallet),
          // Show Cesium+ Profile button while loading
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, RouteNames.cesiumProfile, arguments: widget.wallet.address);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: scaleSize(22),
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.8),
                  ),
                  ScaledSizedBox(width: 18),
                  Expanded(
                    child: Text(
                      "cesiumProfile".tr(),
                      style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAlone)
            isLegacyWallet
                ? _buildLegacyWalletOptions()
                : aloneWalletOptions(context, ref, onDerivationCreated: widget.onDerivationCreated),
          ScaledSizedBox(height: 32),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          buildConfirmIdentitySection(context, ref),
          buildOptionsSection(context),
          if (!isAlone) buildDefaultWalletSection(context, ref, currentSafe, defaultWallet),
          // Show Cesium+ Profile button on error
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, RouteNames.cesiumProfile, arguments: widget.wallet.address);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: scaleSize(22),
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.8),
                  ),
                  ScaledSizedBox(width: 18),
                  Expanded(
                    child: Text(
                      "cesiumProfile".tr(),
                      style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isAlone)
            isLegacyWallet
                ? _buildLegacyWalletOptions()
                : aloneWalletOptions(context, ref, onDerivationCreated: widget.onDerivationCreated),
          ScaledSizedBox(height: 32),
        ],
      ),
    );
  }

  Widget buildConfirmIdentitySection(BuildContext context, WidgetRef ref) {
    // Check if user has identity but not confirmed yet
    // Use hybridIdtyStatusProvider to ensure real-time detection of identity creation
    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(widget.wallet.address));

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
                    MaterialPageRoute(builder: (context) => ConfirmIdentityScreen(address: widget.wallet.address)),
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

  Future<void> _migrateToNewSafeSimplified(BuildContext context, WidgetRef ref) async {
    try {
      // Check identity status of the legacy wallet
      final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(widget.wallet.address);
      final hasIdentity = idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown;

      // Show migration confirmation dialog for new safe
      final confirmMessage = hasIdentity
          ? 'migrationConfirmWithIdentity'.tr(args: [Durt.i.network.symbol, 'newWallet'.tr()])
          : 'migrationConfirmBalanceOnly'.tr(args: [Durt.i.network.symbol, 'newWallet'.tr()]);

      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'migrationConfirmTitle'.tr(),
        message: confirmMessage,
        type: ConfirmationDialogType.info,
      );

      if (confirmed != true) return;

      // Ask for PIN code
      if (!await PinCodeService.askPinCode()) return;

      // Get legacy wallet information for migration
      final rawSeed = await ref
          .read(walletServiceProvider)
          .getLegacyRawSeed(address: widget.wallet.address, pinCode: PinCodeService.pinCode);

      // Store migration data in provider for onboarding to pick up
      ref.read(pendingLegacyMigrationProvider.notifier).set(LegacyMigrationData(
        fromAddress: widget.wallet.address,
        rawSeed: rawSeed,
        hasIdentity: hasIdentity,
      ));

      // Navigate to safe creation - the onboarding will handle migration automatically
      Navigator.pushNamed(context, RouteNames.onboardingStepOne);
    } catch (e) {
      log.e('Migration to new safe error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('migrationError'.tr(args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _migrateToExistingSafeSimplified(BuildContext context, WidgetRef ref) async {
    try {
      // Check identity status of the legacy wallet
      final idtyStatus = await ref.read(storageServiceProvider).getIdtyStatus(widget.wallet.address);
      final hasIdentity = idtyStatus != IdtyStatus.none && idtyStatus != IdtyStatus.unknown;

      // Show migration confirmation dialog for existing safe
      final confirmMessage = hasIdentity
          ? 'migrationConfirmWithIdentity'.tr(args: [Durt.i.network.symbol, 'existingSafe'.tr()])
          : 'migrationConfirmBalanceOnly'.tr(args: [Durt.i.network.symbol, 'existingSafe'.tr()]);

      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'migrationConfirmTitle'.tr(),
        message: confirmMessage,
        type: ConfirmationDialogType.info,
      );

      if (confirmed != true) return;

      // Ask for PIN code
      if (!await PinCodeService.askPinCode()) return;

      // Get legacy wallet information for migration
      final rawSeed = await ref
          .read(walletServiceProvider)
          .getLegacyRawSeed(address: widget.wallet.address, pinCode: PinCodeService.pinCode);

      // Create migration data
      final migrationData = LegacyMigrationData(
        fromAddress: widget.wallet.address,
        rawSeed: rawSeed,
        hasIdentity: hasIdentity,
        isToExistingSafe: true,
      );

      // Check if there are existing non-legacy safes
      final walletService = ref.read(walletServiceProvider);
      final allSafes = walletService.safeBox.getAll();
      final existingSafes = allSafes.where((safe) {
        return safe.safeType == SafeType.mnemonic && safe.number >= 0;
      }).toList();

      if (context.mounted) {
        if (existingSafes.isNotEmpty) {
          // Navigate to safe selection screen
          Navigator.pushNamed(
            context,
            RouteNames.safeSelection,
            arguments: SafeSelectionArguments(migrationData: migrationData, pinCode: PinCodeService.pinCode),
          );
        } else {
          // No existing safes, go directly to import flow
          ref.read(pendingLegacyMigrationProvider.notifier).set(migrationData);
          Navigator.pushNamed(context, RouteNames.restoreSafe, arguments: RestoreSafeArguments(skipIntro: true));
        }
      }
    } catch (e) {
      log.e('Migration to existing safe error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('migrationError'.tr(args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePinCode(BuildContext context, WidgetRef ref) async {
    // For legacy wallets, we need to handle PIN change differently
    // because we need to re-encrypt the salt and password with the new PIN

    // Ask for current PIN first
    if (!await PinCodeService.askPinCode(force: true)) return;

    // Navigate to change PIN screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangePinScreen(walletName: widget.wallet.name ?? 'legacyWallet'.tr()),
      ),
    );
  }

  Widget _buildLegacyWalletOptions() {
    return Column(
      children: [
        // Migrate to new safe option
        InkWell(
          onTap: () async {
            await _migrateToNewSafeSimplified(context, ref);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: scaleSize(24), color: greenColor.withValues(alpha: 0.8)),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migrateToNewSafe'.tr(),
                        style: scaledTextStyle(
                          fontSize: 16,
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'migrateToNewSafeDescription'.tr(),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Migrate to existing safe option
        InkWell(
          onTap: () async {
            await _migrateToExistingSafeSimplified(context, ref);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: scaleSize(24),
                  color: context.colorScheme.primary.withValues(alpha: 0.8),
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'migrateToExistingSafe'.tr(),
                        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                      ),
                      Text(
                        'migrateToExistingSafeDescription'.tr(),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Change PIN code option
        InkWell(
          onTap: () async {
            await _changePinCode(context, ref);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/walletOptions/key.png', height: scaleSize(24)),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'changePassword'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
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
}

Widget aloneWalletOptions(BuildContext context, WidgetRef ref, {VoidCallback? onDerivationCreated}) {
  final walletsState = ref.watch(walletsListProvider);
  final derivationState = ref.watch(derivationStateProvider);
  return Column(
    children: [
      InkWell(
        onTap: () async {
          if (!await PinCodeService.askPinCode()) return;
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
          if (!derivationState.isLoading) {
            if (!await PinCodeService.askPinCode()) return;
            final lastWalletNumber = walletsState.wallets.isNotEmpty ? walletsState.wallets.last.number : -1;
            String newDerivationName = '${'wallet'.tr()} ${lastWalletNumber + 2}';
            await ref.read(walletActionsProvider.notifier).generateNewDerivation(newDerivationName);

            // Call the callback if provided (when embedded in WalletsHome)
            onDerivationCreated?.call();
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
          Navigator.push(homeContext, MaterialPageRoute(builder: (context) => const MigrateG1v1()));
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
