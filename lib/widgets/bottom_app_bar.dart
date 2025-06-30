// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';

class GeckoBottomAppBar extends StatelessWidget {
  const GeckoBottomAppBar({super.key, this.actualRoute = ''});
  final String actualRoute;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    final historyProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;
    const bool showBottomBar = true;
    final lockAction = actualRoute == 'safeHome';

    return Visibility(
      visible: showBottomBar,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: context.colorScheme.tertiary,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, -4), blurRadius: 10),
            ],
          ),
          width: size.width,
          height: scaleSize(67),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                key: keyAppBarHome,
                icon: Icons.home_outlined,
                isSelected: false,
                onTap: () {
                  searchProvider.reload();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
              ),
              _buildNavItem(
                key: keyAppBarQrcode,
                imagePath: 'assets/qrcode-scan.png',
                isSelected: actualRoute == 'scan',
                onTap: () async {
                  historyProvider.scan(homeContext);
                },
              ),
              _buildNavItem(
                key: keyAppBarChest,
                imagePath: 'assets/wallet.png',
                isSelected: actualRoute == 'wallet' || lockAction,
                isDisabled: lockAction,
                onTap: lockAction
                    ? null
                    : () async {
                        if (!await myWalletProvider.askPinCode()) return;

                        Navigator.pushNamedAndRemoveUntil(context, '/mywallets', ModalRoute.withName('/'));
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    Key? key,
    IconData? icon,
    String? imagePath,
    required bool isSelected,
    bool isDisabled = false,
    required VoidCallback? onTap,
  }) {
    final color = isSelected
        ? homeContext.colorScheme.onSurface.withValues(alpha: 0.8)
        : homeContext.colorScheme.onSecondaryContainer.withValues(alpha: 0.8);
    final size = scaleSize(34);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(scaleSize(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? homeContext.colorScheme.secondary.withValues(alpha: 0.5) : Colors.transparent,
          ),
          child: icon != null
              ? Icon(icon, size: size, color: color)
              : Image.asset(imagePath!, height: size, width: size, color: color),
        ),
      ),
    );
  }
}
