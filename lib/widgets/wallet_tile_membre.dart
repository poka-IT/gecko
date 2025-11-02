import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:responsive_framework/responsive_framework.dart';

class WalletTileMembre extends StatefulWidget {
  const WalletTileMembre({super.key, required this.wallet, this.attachTutorialKey = false});

  final WalletEntity wallet;
  final bool attachTutorialKey;

  @override
  State<WalletTileMembre> createState() => _WalletTileMembreState();
}

class _WalletTileMembreState extends State<WalletTileMembre> {
  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    final freshWallet = myWalletProvider.getWalletDataByAddress(widget.wallet.address) ?? widget.wallet;
    final currentSafe = myWalletProvider.getCurrentSafe;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(52), vertical: scaleSize(15)),
      child: GestureDetector(
        key: ValueKey('${keyOpenWallet(freshWallet.address).toString()}_safe${currentSafe}_membre'),
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.walletOptions,
            arguments: WalletOptionsArguments(wallet: freshWallet),
          );
        },
        child: MaxWidthBox(
          maxWidth: 400,
          child: ScaledSizedBox(
            key: widget.attachTutorialKey ? ValueKey('tutorial_membre_${freshWallet.address}_safe$currentSafe') : null,
            height: 180,
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
                    child: Stack(
                      children: [
                        Container(
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
                                  padding: EdgeInsets.all(scaleSize(16)),
                                  child: Image.asset(
                                    'assets/avatars/${freshWallet.number % 4}.png',
                                    alignment: Alignment.bottomCenter,
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.all(scaleSize(16)),
                                  child: CachedAvatarImage(
                                    imagePath: freshWallet.imagePath!,
                                    fit: BoxFit.contain,
                                    isCircular: true,
                                  ),
                                ),
                        ),
                        Positioned(
                          left: scaleSize(16),
                          top: scaleSize(16),
                          child: Image.asset(
                            'assets/medal.png',
                            color: context.colorScheme.primary.withValues(alpha: 0.8),
                            height: scaleSize(28),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: scaleSize(64), // Fixed height to prevent layout shift
                    decoration: BoxDecoration(
                      color: isDefault
                          ? context.colorScheme.primary.withValues(alpha: 0.9)
                          : context.colorScheme.secondary.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NameByAddress(
                              wallet: freshWallet,
                              size: 16,
                              color: isDefault ? Colors.white : context.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            ScaledSizedBox(height: 4),
                            Balance(
                              address: freshWallet.address,
                              size: 14,
                              color: isDefault ? Colors.white : context.colorScheme.onSurface,
                            ),
                          ],
                        ),
                        Certifications(
                          address: freshWallet.address,
                          color: isDefault ? Colors.white : context.colorScheme.onSurface,
                          size: 15,
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

  bool get isDefault {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final freshWallet = myWalletProvider.getWalletDataByAddress(widget.wallet.address) ?? widget.wallet;
    return freshWallet.address == myWalletProvider.getDefaultWallet().address;
  }
}
