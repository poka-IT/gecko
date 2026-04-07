import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/main.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/safe_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/screens/myWallets/custom_derivations.dart';
import 'package:gecko/screens/myWallets/migrate_safe.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/screens/myWallets/rename_safe.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/biometric/biometric_settings_tile.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/desktop/modals/change_pin_modal.dart';
import 'package:gecko/widgets/desktop/modals/migrate_safe_modal.dart';
import 'package:gecko/widgets/desktop/modals/rename_safe_modal.dart';
import 'package:gecko/widgets/desktop/modals/show_seed_modal.dart';

class SafeOptions extends ConsumerWidget {
  const SafeOptions({Key? keyMyWallets}) : super(key: keyMyWallets);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletService = ref.watch(walletServiceProvider);
    if (walletService.safeBox.isEmpty()) {
      return const SizedBox.shrink(); // Widget se ferme, évite l'exception
    }
    final currentSafe = walletService.defaultSafeBox;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      appBar: GeckoAppBar(WalletNameService.displayName(currentSafe.name)),
      body: Builder(
        builder: (ctx) => SafeArea(
          child: ResponsiveCenter(
            maxWidth: 600,
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ScaledSizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.only(left: scaleSize(16)),
                    child: SafeOptionsContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SafeOptionsContent extends ConsumerWidget {
  const SafeOptionsContent({super.key, this.safeNumber});

  /// If provided, show options for this specific safe instead of the default one.
  final int? safeNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletService = ref.watch(walletServiceProvider);
    if (walletService.safeBox.isEmpty()) {
      return const SizedBox.shrink();
    }
    final safeManager = ref.read(safeManagerProvider);

    // Resolve the target safe: specific safe number or default
    final d.SafeEntity currentSafe;
    final int walletCount;
    if (safeNumber != null) {
      final allSafes = walletService.safeBox.getAll();
      final match = allSafes.where((s) => s.number == safeNumber).firstOrNull;
      if (match == null) return const SizedBox.shrink();
      currentSafe = match;
      final query = walletService.walletBox.query()..link(WalletEntity_.safe, SafeEntity_.number.equals(safeNumber!));
      final built = query.build();
      walletCount = built.find().length;
      built.close();
    } else {
      currentSafe = walletService.defaultSafeBox;
      final walletsState = ref.watch(walletsListProvider);
      walletCount = walletsState.wallets.length;
    }
    final isAlone = walletCount == 1;
    final safeFirstWallet = currentSafe.wallets.isNotEmpty ? currentSafe.wallets.first : null;
    final isActiveSafe = currentSafe.number == walletService.defaultSafeBoxNumber;

    return Column(
      spacing: 5,
      children: [
        if (!isActiveSafe && isDesktopLayout(context))
          InkWell(
            onTap: () async {
              await ref.read(walletActionsProvider.notifier).switchSafe(currentSafe.number);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
              child: Row(
                children: [
                  Icon(Icons.radio_button_checked, size: scaleSize(24), color: context.colorScheme.primary),
                  ScaledSizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'setActiveSafe'.tr(),
                          style: scaledTextStyle(
                            fontSize: 16,
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'setActiveSafeHint'.tr(),
                          style: scaledTextStyle(
                            fontSize: 12,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        InkWell(
          key: keyShowSeed,
          onTap: () async {
            // Capture the PIN locally before navigation — the seed provider is
            // keyed on `pin` and would otherwise rebuild with an expired cache
            // by the time the modal / screen finishes building.
            final capturedPin = await PinCodeService.askPinCodeAndCapture(
              context,
              force: true,
              wallet: safeFirstWallet,
            );
            if (capturedPin == null) return;
            if (!context.mounted) return;
            if (isDesktopLayout(context)) {
              Navigator.of(context).pop();
              showDesktopShowSeedModal(
                Gecko.navigatorContext!,
                walletName: WalletNameService.displayName(currentSafe.name),
                pinCode: capturedPin,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ShowSeed(walletName: WalletNameService.displayName(currentSafe.name), pinCode: capturedPin),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.vpn_key_outlined, size: scaleSize(24), color: context.colorScheme.onSurface),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'displayMnemonic'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          key: keyMigrateSafe,
          onTap: ref.read(durtProvider).isConnected
              ? () {
                  if (isDesktopLayout(context)) {
                    Navigator.of(context).pop();
                    showDesktopMigrateSafeModal(Gecko.navigatorContext!);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MigrateSafeScreen()));
                  }
                }
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Icon(
                  Icons.sync_alt,
                  size: scaleSize(24),
                  color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[400],
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'migrateSafe'.tr(),
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
          key: keyChangePin,
          onTap: () async {
            // Capture the old PIN locally — it is forwarded to a modal /
            // screen that consumes it later (after user enters the new PIN),
            // well beyond the 1s `debounceResetPinCode` window.
            final oldPin = await PinCodeService.askPinCodeAndCapture(context, force: true, wallet: safeFirstWallet);
            if (oldPin == null) return;
            if (!context.mounted) return;
            if (isDesktopLayout(context)) {
              Navigator.of(context).pop();
              showDesktopChangePinModal(
                Gecko.navigatorContext!,
                walletName: WalletNameService.displayName(currentSafe.name),
                oldPin: oldPin,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangePinScreen(walletName: WalletNameService.displayName(currentSafe.name), oldPin: oldPin),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: scaleSize(24), color: const Color.fromARGB(255, 255, 142, 142)),
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

        // Biometric authentication settings
        BiometricSettingsTile(),
        if (!isAlone)
          if (ref.read(configServiceProvider).expertMode)
            InkWell(
              key: keycreateRootDerivation,
              onTap: ref.read(durtProvider).isConnected
                  ? () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomDerivation()));
                    }
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.manage_accounts,
                      size: scaleSize(24),
                      color: ref.read(durtProvider).isConnected ? context.colorScheme.onSurface : Colors.grey[400],
                    ),
                    ScaledSizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'createDerivation'.tr(),
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
          key: keyRenameSafe,
          onTap: () async {
            // Authentication gate for rename — no PIN used downstream.
            if (await PinCodeService.askPinCodeAndCapture(context, force: true, wallet: safeFirstWallet) == null) {
              return;
            }
            if (!context.mounted) return;
            if (isDesktopLayout(context)) {
              Navigator.of(context).pop();
              showDesktopRenameSafeModal(
                Gecko.navigatorContext!,
                currentName: WalletNameService.displayName(currentSafe.name),
                safeBoxNumber: currentSafe.number,
              );
            } else {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RenameSafeScreen(
                    currentName: WalletNameService.displayName(currentSafe.name),
                    safeBoxNumber: currentSafe.number,
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: scaleSize(24), color: context.colorScheme.onSurface),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'renameSafe'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          key: keyDeleteSafe,
          onTap: () async {
            // Authentication gate for delete — no PIN used downstream.
            if (await PinCodeService.askPinCodeAndCapture(context, force: true, wallet: safeFirstWallet) == null) {
              return;
            }
            if (!context.mounted) return;

            await safeManager.deleteSafe(context, currentSafe);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Image.asset(
                  'assets/walletOptions/trash.png',
                  height: scaleSize(24),
                  color: context.geckoColors.deleteAction,
                ),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'forgetSafe'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: context.geckoColors.deleteAction),
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
