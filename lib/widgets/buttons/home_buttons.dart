// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:provider/provider.dart';
import 'package:gecko/utils/flower_power_colors.dart';

class HomeButtons extends StatefulWidget {
  final bool isEasterEggActive;

  const HomeButtons({super.key, this.isEasterEggActive = false});

  @override
  State<HomeButtons> createState() => _HomeButtonsState();
}

class _HomeButtonsState extends State<HomeButtons> with TickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for flower power colors (fast cycle)
    _colorController = AnimationController(duration: const Duration(milliseconds: 4079), vsync: this);
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_colorController);
  }

  @override
  void didUpdateWidget(HomeButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEasterEggActive != oldWidget.isEasterEggActive) {
      if (widget.isEasterEggActive) {
        _colorController.repeat();
      } else {
        _colorController.stop();
      }
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Widget _buildFlowerPowerButton({
    required Widget child,
    required Color baseColor,
    required double offset,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 1, offset: const Offset(0, 1)),
            ],
          ),
          child: ClipOval(
            child: Material(
              color: widget.isEasterEggActive
                  ? FlowerPowerColors.getFlowerPowerColor(_colorAnimation.value, offset: offset)
                  : baseColor,
              child: InkWell(
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                onTap: onTap,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final historyProvider = Provider.of<WalletsProfilesProvider>(context);

    return Column(
      children: <Widget>[
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                _buildFlowerPowerButton(
                  baseColor: context.colorScheme.primary,
                  offset: 0.33, // Premier bouton - décalage 1/3
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.search);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(15)),
                    child: Image(image: const AssetImage('assets/home/loupe.png'), height: scaleSize(58)),
                  ),
                ),
                ScaledSizedBox(height: 10),
                Text(
                  "searchWallet".tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
            ScaledSizedBox(width: 95),
            Column(
              children: <Widget>[
                _buildFlowerPowerButton(
                  baseColor: context.colorScheme.primary,
                  offset: 0.66, // Deuxième bouton - décalage 2/3
                  onTap: () async {
                    if (!await myWalletProvider.askPinCode(canSwitch: true)) return;

                    Navigator.pushNamed(context, RouteNames.myWallets);
                  },
                  child: Padding(
                    key: keyOpenWalletsHomme,
                    padding: EdgeInsets.all(scaleSize(14.5)),
                    child: Image(image: const AssetImage('assets/home/wallet.png'), height: scaleSize(61)),
                  ),
                ),
                ScaledSizedBox(height: 10),
                Text(
                  "manageWallets".tr(),
                  textAlign: TextAlign.center,
                  style: scaledTextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: scaleSize(30)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  _buildFlowerPowerButton(
                    baseColor: context.colorScheme.primary,
                    offset: 0.0, // Troisième bouton - pas de décalage
                    onTap: () async {
                      await historyProvider.scan(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(14)),
                      child: Image(image: const AssetImage('assets/home/qrcode.png'), height: scaleSize(62)),
                    ),
                  ),
                  ScaledSizedBox(height: 10),
                  Text(
                    "scanQRCode".tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        ScaledSizedBox(height: isTall ? 60 : 30),
      ],
    );
  }
}
