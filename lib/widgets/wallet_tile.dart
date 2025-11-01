import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/smart_avatar.dart';
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
    // Cache scale size to prevent recalculation during layout
    final padding = EdgeInsets.all(scaleSize(11));
    // Create stable key once
    final gestureKey = ValueKey('wallet_${widget.repository.address}_safe${widget.currentSafe}_${widget.uniqueId}');

    return Padding(
      padding: padding,
      child: GestureDetector(
        key: gestureKey,
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.walletOptions,
            arguments: WalletOptionsArguments(wallet: widget.repository),
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
                    child: widget.repository.imagePath == null || widget.repository.imagePath == ''
                        ? Padding(
                            padding: EdgeInsets.all(scaleSize(16)),
                            child: Image.asset(
                              'assets/avatars/${widget.repository.number % 4}.png',
                              alignment: Alignment.bottomCenter,
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.all(scaleSize(16)),
                            child: SmartAvatar(
                              imagePath: widget.repository.imagePath!,
                              address: widget.repository.address,
                            ),
                          ),
                  ),
                ),
                Container(
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
                            wallet: widget.repository,
                            size: 16,
                            color: isDefault ? Colors.white : context.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          ScaledSizedBox(height: 4),
                          Balance(
                            address: widget.repository.address,
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

  bool get isDefault =>
      widget.repository.address ==
      old_provider.Provider.of<MyWalletsProvider>(homeContext, listen: false).getDefaultWallet().address;
}
