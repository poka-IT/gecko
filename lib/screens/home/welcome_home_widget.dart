import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
import 'package:gecko/screens/onBoarding/import_choice_screen.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';

/// Desktop breakpoint width (same as gecko_home_widget.dart)
const double _desktopWelcomeBreakpoint = 900;

/// Welcome screen widget displayed when no wallets exist
class WelcomeHomeWidget extends ConsumerWidget {
  const WelcomeHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showImage = ref.watch(backgroundImageProvider);

    if (screenWidth >= _desktopWelcomeBreakpoint) {
      return _DesktopWelcomeWidget(showBackgroundImage: showImage);
    }

    return _MobileWelcomeWidget(showBackgroundImage: showImage);
  }
}

// ─────────────────────────── Desktop Layout ───────────────────────────

class _DesktopWelcomeWidget extends StatelessWidget {
  final bool showBackgroundImage;

  const _DesktopWelcomeWidget({required this.showBackgroundImage});

  @override
  Widget build(BuildContext context) {
    final imageCache = ImageCacheService();

    // Get fixed screen dimensions for background
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return Stack(
      children: [
        // Background layer
        Positioned(
          top: 0,
          left: 0,
          width: screenSize.width,
          height: screenSize.height,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -1),
                end: const Alignment(1, 1),
                colors: [
                  context.colorScheme.surface,
                  Color.lerp(context.colorScheme.surface, context.colorScheme.primary, 0.06)!,
                  context.colorScheme.surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              image: showBackgroundImage
                  ? DecorationImage(
                      opacity: 0.15,
                      image: imageCache.getImageProvider("assets/home/background.jpg"),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Stack(
            children: [
              // Settings button top-left
              Positioned(top: scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
              // Full-height column: header at top, gecko+buttons at center-bottom
              Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // Header image — pinned at top
                      Image(image: imageCache.getImageProvider('assets/home/header.png'), height: scaleSize(150)),
                      const SizedBox(height: 8),
                      // App description
                      Text(
                        "fastAppDescription".tr(args: [Durt.i.network.symbol]),
                        textAlign: TextAlign.center,
                        style: scaledTextStyle(
                          color: context.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Gecko + bubble — directly above buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image(
                            image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'),
                            height: scaleSize(150),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: BubbleSpeakWithTail(text: "noLizard".tr()),
                          ),
                        ],
                      ),
                      // Buttons
                      _buildButtons(context),
                      const TestWalletButton(),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380, minHeight: scaleSize(55)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: keyOnboardingNewSafe,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: context.colorScheme.primary,
                  elevation: 4,
                  padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, RouteNames.onboardingStepOne),
                child: Text(
                  'createWallet'.tr(),
                  style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          ScaledSizedBox(height: scaleSize(14)),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380, minHeight: scaleSize(55)),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: keyRestoreSafe,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(width: scaleSize(3), color: context.colorScheme.primary),
                  padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (ImportChoiceScreen.enableLegacyLogin) {
                    Navigator.pushNamed(context, RouteNames.importChoice);
                  } else {
                    Navigator.pushNamed(context, RouteNames.restoreSafe);
                  }
                },
                child: Text(
                  "restoreWallet".tr(),
                  style: scaledTextStyle(fontSize: 20, color: context.colorScheme.primary, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Mobile Layout (original) ───────────────────────────

class _MobileWelcomeWidget extends StatelessWidget {
  final bool showBackgroundImage;

  const _MobileWelcomeWidget({required this.showBackgroundImage});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final imageCache = ImageCacheService();

    // Get fixed screen dimensions to avoid keyboard-related scaling
    final view = View.of(context);
    final screenSize = view.physicalSize / view.devicePixelRatio;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Fixed background that ignores keyboard changes
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: Container(
              decoration: BoxDecoration(
                color: showBackgroundImage ? null : context.colorScheme.secondary,
                image: showBackgroundImage
                    ? DecorationImage(
                        image: imageCache.getImageProvider("assets/home/background.jpg"),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),

          // Content on top
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
                  Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Image(
                        image: imageCache.getImageProvider('assets/home/header.png'),
                        height: scaleSize(165),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "fastAppDescription".tr(args: [Durt.i.network.symbol]),
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: scaledTextStyle(
                          color: Colors.white,
                          fontSize: isTall ? 19 : 17,
                          fontWeight: FontWeight.w700,
                          shadows: const <Shadow>[
                            Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                            Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: <Widget>[
                          const Spacer(flex: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: scaleSize(isTall ? 55 : 0)),
                                child: Image(
                                  image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'),
                                  height: scaleSize(isTall ? 180 : 160),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: BubbleSpeakWithTail(text: "noLizard".tr()),
                              ),
                            ],
                          ),
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        key: keyOnboardingNewSafe,
                                        style:
                                            ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: context.colorScheme.primary,
                                              elevation: 0,
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 8;
                                              }),
                                              shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                            ),
                                        onPressed: () {
                                          Navigator.pushNamed(context, RouteNames.onboardingStepOne);
                                        },
                                        child: Text(
                                          'createWallet'.tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ScaledSizedBox(height: scaleSize(17)),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 400, minHeight: scaleSize(60)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        key: keyRestoreSafe,
                                        style:
                                            OutlinedButton.styleFrom(
                                              side: BorderSide(width: scaleSize(4), color: context.colorScheme.primary),
                                              padding: EdgeInsets.symmetric(
                                                vertical: scaleSize(12),
                                                horizontal: scaleSize(16),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.resolveWith<double>((
                                                Set<WidgetState> states,
                                              ) {
                                                if (states.contains(WidgetState.pressed)) return 0;
                                                return 4;
                                              }),
                                              shadowColor: WidgetStateProperty.all(
                                                Colors.black.withValues(alpha: 0.15),
                                              ),
                                            ),
                                        onPressed: () {
                                          if (ImportChoiceScreen.enableLegacyLogin) {
                                            Navigator.pushNamed(context, RouteNames.importChoice);
                                          } else {
                                            Navigator.pushNamed(context, RouteNames.restoreSafe);
                                          }
                                        },
                                        child: Text(
                                          "restoreWallet".tr(),
                                          style: scaledTextStyle(
                                            fontSize: 20,
                                            color: context.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TestWalletButton(),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
