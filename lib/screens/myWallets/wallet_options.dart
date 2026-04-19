import 'dart:async';
import 'package:durt2/durt2.dart' show IdtyStatus, WalletEntity, Durt, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cs_publish_status_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_management_service.dart';
import 'package:gecko/services/wallet_deletion_service.dart';
import 'package:gecko/services/wallet_name_dialog_service.dart';
import 'package:gecko/screens/activity.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';
import 'package:gecko/screens/myWallets/switch_safe.dart';
import 'package:gecko/screens/myWallets/g1v1_migration/g1v1_migration_flow.dart';
import 'package:gecko/widgets/commons/wallet_app_bar.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/buttons/manage_membership_button.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/screens/identity/confirm_identity.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/providers/certification_queue_provider.dart';
import 'package:gecko/screens/certification_queue_screen.dart';
import 'package:gecko/widgets/cert_alert_banner.dart';
import 'package:gecko/widgets/membership_alert_card.dart';
import 'package:gecko/widgets/migration_alert_card.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/activity_modal.dart';
import 'package:gecko/widgets/desktop/modals/certification_queue_modal.dart';
import 'package:gecko/widgets/desktop/modals/cesium_profile_modal.dart';
import 'package:gecko/widgets/desktop/modals/confirm_identity_modal.dart';
import 'package:gecko/widgets/desktop/modals/legacy_migration_modal.dart';
import 'package:gecko/widgets/desktop/modals/market_analysis_modal.dart';
import 'package:gecko/widgets/desktop/modals/safe_options_modal.dart';
import 'package:gecko/widgets/desktop/modals/wallet_options_modal.dart';

class WalletOptions extends ConsumerStatefulWidget {
  const WalletOptions({Key? keyMyWallets, required this.wallet, this.onDerivationCreated, this.embeddedMode = false})
    : super(key: keyMyWallets);
  final WalletEntity wallet;
  final VoidCallback? onDerivationCreated;

  /// When true, renders without Scaffold/AppBar (for desktop modal).
  final bool embeddedMode;

  @override
  ConsumerState<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends ConsumerState<WalletOptions> {
  late String currentWalletName;

  bool get isLegacyWallet => widget.wallet.safe.target?.safeType == SafeType.legacy;

  @override
  void initState() {
    super.initState();
    currentWalletName = WalletNameService.displayName(widget.wallet.name);
  }

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsListProvider);
    final currentSafe = walletsState.currentSafeNumber;
    final isWalletNameIndexed = ref.read(squidServiceProvider).walletNameIndexer[widget.wallet.address] != null;

    final isAlone = walletsState.wallets.length == 1;

    final body = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: WalletHeader(
            address: widget.wallet.address,
            customImagePath: widget.wallet.imagePath,
            defaultImagePath: widget.wallet.imagePath,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MigrationAlertCard(address: widget.wallet.address),
                  MembershipAlertCard(address: widget.wallet.address),
                  CertAlertBanner(address: widget.wallet.address, username: widget.wallet.name),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScaledSizedBox(height: 16),
                        if (isLegacyWallet)
                          Container(
                            margin: EdgeInsets.symmetric(vertical: scaleSize(8)),
                            padding: EdgeInsets.all(scaleSize(12)),
                            decoration: BoxDecoration(
                              color: context.geckoColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: context.geckoColors.warning, size: scaleSize(20)),
                                ScaledSizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'legacyWalletWarning'.tr(),
                                    style: scaledTextStyle(fontSize: 13, color: context.geckoColors.warningText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildWalletOptionsContent(context, ref, isAlone, currentSafe),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedMode) {
      return body;
    }

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        ref.read(walletsListProvider.notifier).loadWallets();
      },
      child: Scaffold(
        appBar: WalletAppBar(
          address: widget.wallet.address,
          title: isWalletNameIndexed
              ? ref.read(squidServiceProvider).walletNameIndexer[widget.wallet.address]!
              : currentWalletName,
        ),
        body: body,
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
          child: CachedAvatarImage(
            imagePath: widget.wallet.imagePath!,
            fit: BoxFit.cover,
            isCircular: true,
            fallback: Image.asset('assets/avatars/${widget.wallet.number % 4}.png', fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.all(scaleSize(8)),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: InkWell(
              onTap: () async {
                final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: widget.wallet);
                if (!mounted) return;
                if (capturedPin == null) return;

                final newPath = await WalletManagementService.changeAvatar(
                  widget.wallet.address,
                  pinCode: capturedPin,
                  ref: ref,
                );
                if (!mounted) return;
                if (newPath.isNotEmpty) {
                  setState(() {
                    widget.wallet.imagePath = newPath;
                  });
                  ref.read(walletsListProvider.notifier).refresh();
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
        if (widget.embeddedMode && isDesktopLayout(context)) {
          Navigator.of(context).pop();
          showDesktopActivityModal(
            Gecko.navigatorContext!,
            address: widget.wallet.address,
            onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: widget.wallet),
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ActivityScreen(address: widget.wallet.address),
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/walletOptions/clock.png',
              height: scaleSize(24),
              color: context.geckoColors.info.withValues(alpha: 0.8),
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

  Widget deleteWallet(BuildContext context, WidgetRef ref, int currentSafe) {
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
                !hasConsumers &&
                (balance > BigInt.from(2) || balance == BigInt.zero) &&
                !IdentityUtils.hasIdentity(ref, widget.wallet.address);

            return InkWell(
              key: keyDeleteWallet,
              onTap: canDelete
                  ? () async {
                      final result = await WalletDeletionService.deleteWallet(context, widget.wallet, ref: ref);
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
                            color: context.geckoColors.deleteAction,
                          ),
                          ScaledSizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'deleteThisWallet'.tr(),
                                  style: scaledTextStyle(fontSize: 16, color: context.geckoColors.deleteAction),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'deleteThisWalletHint'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 12,
                                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  softWrap: true,
                                ),
                              ],
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

  /// Build the wallet options content with reactive identity checks
  Widget _buildWalletOptionsContent(BuildContext context, WidgetRef ref, bool isAlone, int currentSafe) {
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
            if (!hasIdentity) ...[
              InkWell(
                key: keyRenameWallet,
                onTap: () async {
                  final newName = await WalletNameDialogService.showEditWalletNameDialog(context, widget.wallet);
                  if (newName != null && mounted) {
                    await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafe);
                    if (!mounted) return;
                    final updatedWallet = ref.read(walletByAddressProvider(widget.wallet.address));
                    if (updatedWallet != null) {
                      widget.wallet.name = updatedWallet.name;
                      setState(() {
                        currentWalletName = updatedWallet.name!;
                      });
                    }

                    // Publish to CesiumPlus if non-default name
                    if (!WalletNameService.isDefault(newName)) {
                      final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: widget.wallet);
                      if (capturedPin != null && mounted) {
                        unawaited(
                          WalletManagementService.publishNameToCesiumPlus(
                            widget.wallet.address,
                            newName,
                            capturedPin,
                            ref: ref,
                          ),
                        );
                      }
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
                        color: context.geckoColors.info.withValues(alpha: 0.8),
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
              // Retry indicator for failed CesiumPlus name publication
              Consumer(
                builder: (context, ref, _) {
                  final publishStatus = ref.watch(csPublishStatusProvider(widget.wallet.address));
                  if (publishStatus != CsPublishStatus.failed) return const SizedBox.shrink();
                  return InkWell(
                    onTap: () async {
                      final currentName = widget.wallet.name;
                      if (currentName == null || WalletNameService.isDefault(currentName)) return;
                      final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: widget.wallet);
                      if (capturedPin != null && mounted) {
                        unawaited(
                          WalletManagementService.publishNameToCesiumPlus(
                            widget.wallet.address,
                            currentName,
                            capturedPin,
                            ref: ref,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(8)),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, color: context.geckoColors.warning, size: scaleSize(20)),
                          ScaledSizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'retryPublishName'.tr(),
                              style: scaledTextStyle(fontSize: 14, color: context.geckoColors.warning),
                            ),
                          ),
                          Icon(Icons.refresh, color: context.geckoColors.warning, size: scaleSize(18)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            _buildCesiumProfileButton(context),
            // Market Analysis button
            InkWell(
              onTap: () {
                if (isDesktopLayout(context)) {
                  if (widget.embeddedMode) Navigator.of(context).pop();
                  showDesktopMarketAnalysisModal(
                    Gecko.navigatorContext!,
                    walletAddress: widget.wallet.address,
                    onBack: widget.embeddedMode
                        ? () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: widget.wallet)
                        : null,
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    RouteNames.marketAnalysis,
                    arguments: MarketAnalysisArguments(walletAddress: widget.wallet.address),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: scaleSize(22),
                      color: context.geckoColors.info.withValues(alpha: 0.8),
                    ),
                    ScaledSizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'marketAnalysis'.tr(),
                        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!hasIdentity && (!isAlone || (widget.embeddedMode && isDesktopLayout(context))))
              deleteWallet(context, ref, currentSafe),
            if (hasIdentity) ManageMembershipButton(address: widget.wallet.address),
            if (hasIdentity) _buildCertificationQueueButton(context, ref),
            if (isAlone)
              isLegacyWallet
                  ? _buildLegacyWalletOptions()
                  : aloneWalletOptions(
                      context,
                      ref,
                      wallet: widget.wallet,
                      onDerivationCreated: widget.onDerivationCreated,
                    ),
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
          _buildCesiumProfileButton(context),
          if (isAlone)
            isLegacyWallet
                ? _buildLegacyWalletOptions()
                : aloneWalletOptions(
                    context,
                    ref,
                    wallet: widget.wallet,
                    onDerivationCreated: widget.onDerivationCreated,
                  ),
          ScaledSizedBox(height: 32),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          buildConfirmIdentitySection(context, ref),
          buildOptionsSection(context),
          _buildCesiumProfileButton(context),
          if (isAlone)
            isLegacyWallet
                ? _buildLegacyWalletOptions()
                : aloneWalletOptions(
                    context,
                    ref,
                    wallet: widget.wallet,
                    onDerivationCreated: widget.onDerivationCreated,
                  ),
          ScaledSizedBox(height: 32),
        ],
      ),
    );
  }

  /// Cesium+ profile button - used in data, loading, and error states.
  Widget _buildCesiumProfileButton(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.embeddedMode && isDesktopLayout(context)) {
          Navigator.of(context).pop();
          showDesktopCesiumProfileModal(
            Gecko.navigatorContext!,
            address: widget.wallet.address,
            onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: widget.wallet),
          );
        } else {
          Navigator.pushNamed(context, RouteNames.cesiumProfile, arguments: widget.wallet.address);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: scaleSize(22), color: context.geckoColors.info.withValues(alpha: 0.8)),
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
                  if (widget.embeddedMode && isDesktopLayout(context)) {
                    Navigator.of(context).pop();
                    showDesktopConfirmIdentityModal(
                      Gecko.navigatorContext!,
                      address: widget.wallet.address,
                      onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: widget.wallet),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ConfirmIdentityScreen(address: widget.wallet.address)),
                    );
                  }
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
      // Check identity status of the legacy wallet (use cached provider)
      final idtyStatusAsync = ref.read(hybridIdtyStatusProvider(widget.wallet.address));
      final idtyStatus = idtyStatusAsync.value ?? IdtyStatus.none;
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

      // Ask for PIN code and capture it locally. The previous confirmation
      // dialog was user-interactive, so the captured string is the only safe
      // way to carry the PIN across the remaining steps.
      if (!context.mounted) return;
      final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: widget.wallet);
      if (capturedPin == null) return;

      // Get legacy wallet information for migration
      final rawSeed = await ref
          .read(walletServiceProvider)
          .getLegacyRawSeed(address: widget.wallet.address, pinCode: capturedPin);

      // Store migration data in provider for onboarding to pick up
      ref
          .read(pendingLegacyMigrationProvider.notifier)
          .set(LegacyMigrationData(fromAddress: widget.wallet.address, rawSeed: rawSeed, hasIdentity: hasIdentity));

      // Navigate to safe creation - the onboarding will handle migration automatically
      if (!context.mounted) return;
      Navigator.pushNamed(context, RouteNames.onboardingStepOne);
    } catch (e) {
      log.e('Migration to new safe error: $e');
      if (!context.mounted) return;
      SnackbarService.showError(context, message: 'migrationError'.tr(args: [e.toString()]));
    }
  }

  Future<void> _migrateToExistingSafeSimplified(BuildContext context, WidgetRef ref) async {
    try {
      // Check identity status of the legacy wallet (use cached provider)
      final idtyStatusAsync = ref.read(hybridIdtyStatusProvider(widget.wallet.address));
      final idtyStatus = idtyStatusAsync.value ?? IdtyStatus.none;
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

      // Ask for PIN code and capture it locally. The PIN will be passed to the
      // SafeSelection route below — that screen is consumed by the user much
      // later than the 1s `debounceResetPinCode` window, so reading the
      // service field at navigation time would guarantee an empty PIN.
      if (!context.mounted) return;
      final capturedPin = await PinCodeService.askPinCodeAndCapture(context, wallet: widget.wallet);
      if (capturedPin == null) return;

      // Get legacy wallet information for migration
      final rawSeed = await ref
          .read(walletServiceProvider)
          .getLegacyRawSeed(address: widget.wallet.address, pinCode: capturedPin);

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
          // Navigate to safe selection screen, forwarding the locally-captured
          // PIN so the downstream screen doesn't hit an expired cache.
          Navigator.pushNamed(
            context,
            RouteNames.safeSelection,
            arguments: SafeSelectionArguments(migrationData: migrationData, pinCode: capturedPin),
          );
        } else {
          // No existing safes, go directly to import flow
          ref.read(pendingLegacyMigrationProvider.notifier).set(migrationData);
          Navigator.pushNamed(context, RouteNames.restoreSafe, arguments: RestoreSafeArguments(skipIntro: true));
        }
      }
    } catch (e) {
      log.e('Migration to existing safe error: $e');
      if (!context.mounted) return;
      SnackbarService.showError(context, message: 'migrationError'.tr(args: [e.toString()]));
    }
  }

  Future<void> _changePinCode(BuildContext context, WidgetRef ref) async {
    // For legacy wallets, we need to handle PIN change differently
    // because we need to re-encrypt the salt and password with the new PIN

    // Ask for current PIN and capture it locally — it's forwarded to the
    // ChangePinScreen which consumes it much later (after the user enters
    // the new PIN), well beyond the 1s `debounceResetPinCode` window.
    final oldPin = await PinCodeService.askPinCodeAndCapture(context, force: true, wallet: widget.wallet);
    if (oldPin == null) return;

    // Navigate to change PIN screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangePinScreen(walletName: WalletNameService.displayName(widget.wallet.name), oldPin: oldPin),
      ),
    );
  }

  Widget _buildCertificationQueueButton(BuildContext context, WidgetRef ref) {
    final issuerAddress = widget.wallet.address;
    final hasItems = ref.watch(hasQueueItemsProvider(issuerAddress));
    final hasReady = ref.watch(hasReadyCertificationProvider(issuerAddress));
    final queueLength = ref.watch(queueLengthProvider(issuerAddress));

    return InkWell(
      key: keyCertificationQueue,
      onTap: () {
        if (widget.embeddedMode && isDesktopLayout(context)) {
          Navigator.of(context).pop();
          showDesktopCertificationQueueModal(
            Gecko.navigatorContext!,
            issuerAddress: issuerAddress,
            onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: widget.wallet),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CertificationQueueScreen(issuerAddress: issuerAddress)),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(17), vertical: scaleSize(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  Icons.queue,
                  size: scaleSize(22),
                  color: hasReady ? context.geckoColors.success : context.geckoColors.warning.withValues(alpha: 0.8),
                ),
                if (hasItems && queueLength > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: hasReady ? context.geckoColors.success : context.geckoColors.info,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$queueLength',
                        style: scaledTextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            ScaledSizedBox(width: 18),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'certificationQueue'.tr(),
                      style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasReady) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.geckoColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'certificationReady'.tr(),
                        style: scaledTextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: scaleSize(20), color: context.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
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
                Icon(
                  Icons.shield_outlined,
                  size: scaleSize(24),
                  color: context.geckoColors.success.withValues(alpha: 0.8),
                ),
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

Widget aloneWalletOptions(
  BuildContext context,
  WidgetRef ref, {
  required WalletEntity wallet,
  VoidCallback? onDerivationCreated,
}) {
  final walletsState = ref.watch(walletsListProvider);
  final derivationState = ref.watch(derivationStateProvider);
  return Column(
    children: [
      InkWell(
        onTap: () async {
          // Authentication gate for safe options screen.
          if (await PinCodeService.askPinCodeAndCapture(context, wallet: ref.read(firstWalletProvider)) == null) {
            return;
          }
          if (!context.mounted) return;
          if (isDesktopLayout(context)) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            showDesktopSafeOptionsModal(
              Gecko.navigatorContext!,
              ref,
              onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: wallet),
            );
          } else {
            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SafeOptions()));
          }
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
            final capturedPin = await PinCodeService.askPinCodeAndCapture(
              context,
              wallet: ref.read(firstWalletProvider),
            );
            if (capturedPin == null) return;
            final lastWalletNumber = walletsState.wallets.isNotEmpty ? walletsState.wallets.last.number : -1;
            String newDerivationName = '${'wallet'.tr()} ${lastWalletNumber + 2}';
            await ref
                .read(walletActionsProvider.notifier)
                .generateNewDerivation(newDerivationName, pinCode: capturedPin);

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
                color: ref.read(durtProvider).isConnected
                    ? context.geckoColors.success.withValues(alpha: 0.8)
                    : Colors.grey[400],
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
          if (isDesktopLayout(context)) {
            // On desktop, close modal - safe switching is handled from the desktop home
            Navigator.of(context).pop();
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SwitchSafe()));
          }
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
          if (isDesktopLayout(context)) {
            Navigator.of(context).pop();
            showDesktopLegacyMigrationModal(
              Gecko.navigatorContext!,
              onBack: () => showDesktopWalletOptionsModal(Gecko.navigatorContext!, wallet: wallet),
            );
          } else {
            Navigator.push(Gecko.navigatorContext!, MaterialPageRoute(builder: (context) => const G1v1MigrationFlow()));
          }
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
                  style: scaledTextStyle(fontSize: 16, color: Gecko.navigatorContext!.colorScheme.onSurface),
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
