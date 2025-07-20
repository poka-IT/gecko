// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/safe_provider.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/change_pin.dart';
import 'package:gecko/screens/myWallets/custom_derivations.dart';
import 'package:gecko/screens/myWallets/migrate_safe.dart';
import 'package:gecko/screens/myWallets/show_seed.dart';
import 'package:gecko/screens/myWallets/rename_safe.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

class SafeOptions extends ConsumerWidget {
  const SafeOptions({Key? keyMyWallets}) : super(key: keyMyWallets);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSafe = ref.watch(walletServiceProvider).defaultSafeBox;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      appBar: GeckoAppBar(currentSafe.name),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: Builder(
        builder: (ctx) => SafeArea(
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
    );
  }
}

class SafeOptionsContent extends ConsumerWidget {
  const SafeOptionsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeProvider = old_provider.Provider.of<SafeProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final currentSafe = ref.watch(walletServiceProvider).defaultSafeBox;
    final isAlone = myWalletProvider.listWallets.length == 1;

    return Column(
      spacing: 5,
      children: [
        InkWell(
          key: keyShowSeed,
          onTap: () async {
            if (!await myWalletProvider.askPinCode(force: true)) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowSeed(walletName: currentSafe.name, walletProvider: myWalletProvider),
              ),
            );
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MigrateSafeScreen()));
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
            if (!await myWalletProvider.askPinCode(force: true)) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePinScreen(walletName: currentSafe.name, walletProvider: myWalletProvider),
              ),
            );
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
        if (!isAlone)
          if (configBox.get('expertMode') ?? false)
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
            if (!await myWalletProvider.askPinCode(force: true)) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RenameSafeScreen(currentName: currentSafe.name, safeBoxNumber: currentSafe.number),
              ),
            );
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
            if (!await myWalletProvider.askPinCode(force: true)) return;

            await safeProvider.forgetSafe(context, currentSafe);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
            child: Row(
              children: [
                Image.asset('assets/walletOptions/trash.png', height: scaleSize(24), color: const Color(0xffD80000)),
                ScaledSizedBox(width: 16),
                Expanded(
                  child: Text(
                    'forgetSafe'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: const Color(0xffD80000)),
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
