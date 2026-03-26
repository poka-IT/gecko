import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';

import 'package:gecko/extensions.dart';
import 'package:gecko/providers/home_alert_provider.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/screens/home/desktop_home_widget.dart';
import 'package:gecko/widgets/optimized_background.dart';
import 'package:gecko/widgets/animated_header_image.dart';
import 'package:gecko/widgets/buttons/home_buttons.dart';
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';
import 'package:gecko/widgets/easter_egg_detector.dart';

/// Handles tap on a home alert message — navigates to the appropriate screen.
///
/// Used by both mobile and desktop home widgets.
void handleHomeAlertTap(BuildContext context, HomeAlertState alert) {
  switch (alert.action) {
    case HomeAlertAction.openProfile:
      if (alert.targetAddress != null) {
        NavigationService.openProfile(context, address: alert.targetAddress!, username: alert.targetName);
      }
    case HomeAlertAction.openCertList:
      if (alert.walletAddress != null) {
        NavigationService.openProfile(context, address: alert.walletAddress!);
      }
    case HomeAlertAction.walletOptions:
      // For membership alerts, open own wallet profile
      if (alert.walletAddress != null) {
        NavigationService.openProfile(context, address: alert.walletAddress!);
      }
    case HomeAlertAction.nothing:
      break;
  }
}

/// Home screen widget displayed when wallets exist
class GeckoHomeWidget extends ConsumerWidget {
  final bool isEasterEggActive;
  final ValueChanged<bool> onEasterEggStateChange;

  const GeckoHomeWidget({super.key, required this.isEasterEggActive, required this.onEasterEggStateChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use desktop dashboard layout on wide screens
    if (isDesktopLayout(context)) {
      return DesktopHomeWidget(isEasterEggActive: isEasterEggActive, onEasterEggStateChange: onEasterEggStateChange);
    }

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final showImage = ref.watch(backgroundImageProvider);
    final useWhiteText = showImage || context.colorScheme.brightness == Brightness.light;
    final textColor = useWhiteText ? Colors.white : context.colorScheme.onSurface;
    final textShadows = useWhiteText
        ? <Shadow>[
            const Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
            const Shadow(offset: Offset(0, 0), blurRadius: 20, color: Colors.black),
          ]
        : <Shadow>[];

    return EasterEggDetector(
      onPlayingStateChanged: onEasterEggStateChange,
      child: OptimizedBackground(
        isEasterEggActive: isEasterEggActive,
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Positioned(top: statusBarHeight + scaleSize(10), left: scaleSize(15), child: IconHomeSettings()),
                    Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: AnimatedHeaderImage(isEasterEggActive: isEasterEggActive, height: scaleSize(165)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: DefaultTextStyle(
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              shadows: textShadows,
                            ),
                            child: const _HomeMessageDisplay(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: 15),
                // Gradient overlay only when background image is shown
                Expanded(
                  flex: 1,
                  child: showImage
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            // HomeButtons in absolute position, independent of content above
            SafeArea(child: HomeButtons(isEasterEggActive: isEasterEggActive)),
          ],
        ),
      ),
    );
  }
}

/// Displays the home message with alert sync and tap navigation.
///
/// Extracted as a dedicated [ConsumerWidget] so that [ref.listen] is called
/// in [build] (proper Riverpod lifecycle) rather than inside a nested
/// [Consumer.builder] callback.
class _HomeMessageDisplay extends ConsumerWidget {
  const _HomeMessageDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeMessage = ref.watch(homeMessageProvider);
    final homeMessageNotifier = ref.read(homeMessageProvider.notifier);

    final alert = ref.watch(homeAlertProvider);
    ref.listen(homeAlertProvider, (_, next) {
      homeMessageNotifier.syncWithAlert(next);
    });

    final isIdle = homeMessage == HomeMessageNotifier.idleKey;
    final displayText = isIdle ? 'noLizard'.tr() : homeMessage;

    return GestureDetector(
      onTap: () {
        if (alert.hasAlert) {
          handleHomeAlertTap(context, alert);
        } else if (isIdle) {
          homeMessageNotifier.showWisdomOfTheDay(context);
        }
      },
      child: AnimatedFadeOutIn<String>(
        data: displayText,
        duration: const Duration(milliseconds: 200),
        builder: (value) => Text(value),
      ),
    );
  }
}
