import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart' as old_provider;

class WalletTile extends StatefulWidget {
  const WalletTile({
    super.key,
    required this.repository,
    this.tutorialKey,
    required this.uniqueId,
    required this.currentSafe,
  });

  final WalletEntity repository;
  final GlobalKey? tutorialKey; // GlobalKey needed for tutorial targeting
  final String uniqueId; // Add unique identifier to avoid key conflicts
  final int currentSafe; // Pass currentSafe to avoid provider access during layout

  @override
  State<WalletTile> createState() => _WalletTileState();
}

class _WalletTileState extends State<WalletTile> {
  @override
  Widget build(BuildContext context) {
    // Listen to MyWalletsProvider to get fresh wallet data
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    final freshWallet = myWalletProvider.getWalletDataByAddress(widget.repository.address) ?? widget.repository;

    // Cache scale size to prevent recalculation during layout
    final padding = EdgeInsets.all(scaleSize(11));
    // Create stable key once
    final gestureKey = ValueKey('wallet_${widget.repository.address}_safe${widget.currentSafe}_${widget.uniqueId}');

    // Check if this wallet is the default wallet
    final isDefault = myWalletProvider.getDefaultWallet().address == freshWallet.address;

    return Padding(
      padding: padding,
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
          key: widget.tutorialKey, // Use the passed tutorial key directly
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
                            ),
                          ),
                  ),
                ),
                Container(
                  height: scaleSize(60), // Fixed height to prevent layout shift
                  decoration: BoxDecoration(
                    color: isDefault
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
