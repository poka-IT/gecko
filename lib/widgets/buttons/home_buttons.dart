import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/profile_view_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/providers/settings_provider.dart';
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
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 1, offset: const Offset(0, 1)),
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

  Widget _buildLabeledButton({
    required Color baseColor,
    required double offset,
    required VoidCallback onTap,
    required Widget child,
    required String label,
    String? semanticLabel,
  }) {
    final showImage = ref.watch(backgroundImageProvider);
    final labelColor = showImage ? Colors.white : context.colorScheme.onSurface;
    final labelShadows = showImage
        ? [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
        : <Shadow>[];

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      child: Column(
        children: <Widget>[
          _buildFlowerPowerButton(baseColor: baseColor, offset: offset, onTap: onTap, child: child),
          ScaledSizedBox(height: 10),
          ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                color: labelColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                shadows: labelShadows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final aspectRatio = screenHeight / screenWidth;
    final isWide = screenWidth >= 600;

    // Build the 3 action buttons
    final searchButton = _buildLabeledButton(
      baseColor: context.colorScheme.primary,
      offset: 0.33,
      onTap: () => Navigator.pushNamed(context, RouteNames.search),
      child: Padding(
        padding: EdgeInsets.all(scaleSize(15)),
        child: Image(image: _imageCache.getImageProvider('assets/home/loupe.png'), height: scaleSize(58)),
      ),
      label: "searchWallet".tr(),
    );

    final walletsButton = _buildLabeledButton(
      baseColor: context.colorScheme.primary,
      offset: 0.66,
      onTap: () async {
        final hadToUnlock = PinCodeService.pinCode.isEmpty;
        if (!await PinCodeService.askPinCode(context, canSwitch: true)) return;
        if (hadToUnlock) {
          // ignore: use_build_context_synchronously
          await _performSmoothTransition(context);
        } else {
          if (!context.mounted) return;
          Navigator.pushNamed(context, RouteNames.myWallets);
        }
      },
      child: Padding(
        key: keyOpenWalletsHomme,
        padding: EdgeInsets.all(scaleSize(14.5)),
        child: Image(image: _imageCache.getImageProvider('assets/home/wallet.png'), height: scaleSize(61)),
      ),
      label: "manageWallets".tr(),
    );

    final qrButton = _buildLabeledButton(
      baseColor: context.colorScheme.primary,
      offset: 0.0,
      onTap: () async {
        final scanQr = ref.read(qrScanProvider);
        await scanQr(context);
      },
      child: Padding(
        padding: EdgeInsets.all(scaleSize(14)),
        child: Image(image: _imageCache.getImageProvider('assets/home/qrcode.png'), height: scaleSize(62)),
      ),
      label: "scanQRCode".tr(),
    );

    // Wide screen: buttons in a row inside a glass container, anchored to bottom
    if (isWide) {
      final showImage = ref.watch(backgroundImageProvider);
      return SizedBox.expand(
        child: Column(
          children: [
            const Spacer(),
            Container(
              constraints: const BoxConstraints(maxWidth: 640),
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
              decoration: BoxDecoration(
                color: showImage
                    ? Colors.black.withValues(alpha: 0.35)
                    : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: showImage
                      ? Colors.white.withValues(alpha: 0.1)
                      : context.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  searchButton,
                  const SizedBox(width: 64),
                  walletsButton,
                  const SizedBox(width: 64),
                  qrButton,
                  // NFC button is not shown on desktop (NFC not available)
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.08),
          ],
        ),
      );
    }

    // Mobile: original 2+1 triangle layout
    double topOffsetPercentage;
    if (aspectRatio > 2.0) {
      topOffsetPercentage = 0.50;
    } else if (aspectRatio > 1.5) {
      topOffsetPercentage = 0.45;
    } else if (aspectRatio > 1.2) {
      topOffsetPercentage = 0.40;
    } else {
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[searchButton, ScaledSizedBox(width: 95), walletsButton],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: scaleSize(30)),
                      child: qrButton,
                    ),
                    ScaledSizedBox(height: isTall ? 40 : 20),
                  ],
                ),
              ),
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
