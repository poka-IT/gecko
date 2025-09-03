// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils/flower_power_colors.dart';

class HomeButtons extends ConsumerStatefulWidget {
  final bool isEasterEggActive;

  const HomeButtons({super.key, this.isEasterEggActive = false});

  @override
  ConsumerState<HomeButtons> createState() => _HomeButtonsState();
}

class _HomeButtonsState extends ConsumerState<HomeButtons> with TickerProviderStateMixin {
  final ImageCacheService _imageCache = ImageCacheService();
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
        // Fixed button size to prevent oval/round resizing issue
        final buttonSize = scaleSize(90);

        return Container(
          width: buttonSize,
          height: buttonSize,
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
    // Use absolute positioning based on screen height, independent of other content
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final aspectRatio = screenHeight / screenWidth;

    // Adjust position based on screen aspect ratio
    // Tall screens (mobile): higher percentage
    // Wide screens (desktop/tablet): lower percentage
    double topOffsetPercentage;
    if (aspectRatio > 2.0) {
      // Very tall screens (modern phones)
      topOffsetPercentage = 0.50;
    } else if (aspectRatio > 1.5) {
      // Standard mobile screens
      topOffsetPercentage = 0.45;
    } else if (aspectRatio > 1.2) {
      // Tablet portrait
      topOffsetPercentage = 0.40;
    } else {
      // Wide screens (desktop, tablet landscape)
      topOffsetPercentage = 0.35;
    }

    final topOffset = screenHeight * topOffsetPercentage;

    return SizedBox(
      height: double.infinity,
      child: Stack(
        children: [
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            child: Column(
              children: <Widget>[
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
                            child: Image(
                              image: _imageCache.getImageProvider('assets/home/loupe.png'),
                              height: scaleSize(58),
                            ),
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
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
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
                            final hadToUnlock = PinCodeService.pinCode.isEmpty;
                            if (!await PinCodeService.askPinCode(canSwitch: true)) return;

                            if (hadToUnlock) {
                              // Use smooth transition if we came from unlocking screen
                              await _performSmoothTransition(context);
                            } else {
                              // Direct navigation if already unlocked
                              Navigator.pushNamed(context, RouteNames.myWallets);
                            }
                          },
                          child: Padding(
                            key: keyOpenWalletsHomme,
                            padding: EdgeInsets.all(scaleSize(14.5)),
                            child: Image(
                              image: _imageCache.getImageProvider('assets/home/wallet.png'),
                              height: scaleSize(61),
                            ),
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
                              final scanQr = ref.read(qrScanProvider);
                              await scanQr(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(scaleSize(14)),
                              child: Image(
                                image: _imageCache.getImageProvider('assets/home/qrcode.png'),
                                height: scaleSize(62),
                              ),
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
                ScaledSizedBox(height: isTall ? 40 : 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Performs a smooth transition to myWallets screen with overlay to hide intermediate navigation
  Future<void> _performSmoothTransition(BuildContext context) async {
    // Create an animated overlay with fade transition
    late OverlayEntry overlayEntry;

    // Animation controller for the overlay
    bool showOverlay = false;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: showOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: Container(color: context.colorScheme.surface),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(overlayEntry);

    // Start fade in and navigation simultaneously
    showOverlay = true;
    overlayEntry.markNeedsBuild();

    // Preload the page during fade in
    Navigator.pushNamed(context, RouteNames.myWallets);

    // Wait for fade in to complete
    await Future.delayed(const Duration(milliseconds: 100));

    // Wait a bit then fade out the overlay
    Future.delayed(const Duration(milliseconds: 50), () {
      showOverlay = false;
      overlayEntry.markNeedsBuild();

      // Remove overlay after fade out
      Future.delayed(const Duration(milliseconds: 100), () {
        overlayEntry.remove();
      });
    });
  }
}
