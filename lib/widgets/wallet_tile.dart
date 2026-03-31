import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/name_by_address.dart';

class WalletTile extends ConsumerWidget {
  const WalletTile({
    super.key,
    required this.repository,
    this.tutorialKey,
    required this.uniqueId,
    required this.currentSafe,
    this.hasIdentityWallet = false,
  });

  final WalletEntity repository;
  final GlobalKey? tutorialKey; // GlobalKey needed for tutorial targeting
  final String uniqueId; // Add unique identifier to avoid key conflicts
  final int currentSafe; // Pass currentSafe to avoid provider access during layout
  final bool hasIdentityWallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch wallets list to get fresh wallet data
    final freshWallet = ref.watch(walletByAddressProvider(repository.address)) ?? repository;

    // Cache scale size to prevent recalculation during layout
    final padding = EdgeInsets.all(scaleSize(11));
    // Create stable key once
    final gestureKey = ValueKey('wallet_${repository.address}_safe${currentSafe}_$uniqueId');

    // Highlight root wallet (no derivation) or first wallet if no root exists,
    // but only when there is no identity wallet (which has its own dedicated tile).
    final wallets = ref.watch(walletsListProvider).wallets;
    final isHighlighted =
        !hasIdentityWallet &&
        (freshWallet.derivation == null ||
            (wallets.isNotEmpty &&
                wallets.first.address == freshWallet.address &&
                !wallets.any((w) => w.derivation == null)));

    return Padding(
      padding: padding,
      child: Semantics(
        label: 'Wallet ${freshWallet.name ?? freshWallet.address}',
        button: true,
        child: GestureDetector(
          key: gestureKey,
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.walletOptions,
              arguments: WalletOptionsArguments(wallet: freshWallet),
            );
          },
          child: ScaledSizedBox(
            key: tutorialKey, // Use the passed tutorial key directly
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        color: context.colorScheme.secondary.withValues(alpha: context.isDarkTheme ? 1 : 0.3),
                      ),
                      child: freshWallet.imagePath == null || freshWallet.imagePath == ''
                          ? Padding(
                              padding: EdgeInsets.all(scaleSize(6)),
                              child: Image.asset(
                                'assets/avatars/${freshWallet.number % 4}.png',
                                alignment: Alignment.bottomCenter,
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.all(scaleSize(6)),
                              child: CachedAvatarImage(
                                imagePath: freshWallet.imagePath!,
                                fit: BoxFit.contain,
                                isCircular: true,
                                fallback: Image.asset(
                                  'assets/avatars/${freshWallet.number % 4}.png',
                                  alignment: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Container(
                    height: scaleSize(60), // Fixed height to prevent layout shift
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? context.colorScheme.primary.withValues(alpha: 0.9)
                          : context.colorScheme.secondary.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: scaleSize(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            NameByAddress(
                              wallet: freshWallet,
                              size: 16,
                              color: isHighlighted ? Colors.white : context.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              showCesiumPlusName: true,
                            ),
                            ScaledSizedBox(height: 4),
                            Balance(
                              address: freshWallet.address,
                              size: 14,
                              color: isHighlighted ? Colors.white : context.colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ],
                    ),
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
