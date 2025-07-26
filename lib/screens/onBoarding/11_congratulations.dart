// ignore_for_file: file_names

import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gif_view/gif_view.dart';

class OnboardingStepEleven extends ConsumerStatefulWidget {
  const OnboardingStepEleven({super.key, this.fromRestore = false});
  final bool fromRestore;

  @override
  ConsumerState<OnboardingStepEleven> createState() => _OnboardingStepElevenState();
}

class _OnboardingStepElevenState extends ConsumerState<OnboardingStepEleven> {
  // Instance flag to prevent multiple bottom sheet openings
  bool _biometricSetupAttempted = false;

  @override
  Widget build(BuildContext context) {
    final conffetiController = ConfettiController(duration: const Duration(milliseconds: 500));
    conffetiController.play();

    // Get PIN code from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as OnboardingStepElevenArguments?;
    final pinCode = args?.pinCode;

    // Auto-trigger biometric setup bottom sheet if available, PIN is available, and not already attempted
    if (pinCode != null && !_biometricSetupAttempted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait for biometric provider to finish loading, then check canEnroll
        await _waitForBiometricAndSetup(context, ref, pinCode);
      });
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('allGood'.tr()),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ScaledSizedBox(height: isTall ? 25 : 5),
                      BuildText(
                        text: widget.fromRestore
                            ? "yourSafeAndWalletWereRestoredSuccessfully".tr()
                            : "yourSafeAndWalletWereCreatedSuccessfully".tr(),
                      ),
                      ScaledSizedBox(height: isTall ? 15 : 5),
                      GifView(
                        image: AssetImage('assets/onBoarding/gecko-clin.gif'),
                        height: scaleSize(isTall ? 330 : 280),
                      ),
                      // We need this invisible second gif to preload the gif, otherwise it will glitch on loop
                      Image.asset('assets/onBoarding/gecko-clin.gif', height: 0),

                      Container(
                        padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                        child: finishButton(context),
                      ),
                      ScaledSizedBox(height: isTall ? 40 : 5),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.15,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 8,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.85,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 8,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: const Alignment(-0.3, -0.2),
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.3,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 6,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
              Align(
                alignment: const Alignment(0.3, -0.2),
                child: ConfettiWidget(
                  confettiController: conffetiController,
                  blastDirection: pi * 0.7,
                  maxBlastForce: 15,
                  minBlastForce: 3,
                  emissionFrequency: 0.04,
                  numberOfParticles: 6,
                  shouldLoop: true,
                  gravity: 0.15,
                  particleDrag: 0.1,
                  minimumSize: const Size(8, 8),
                  maximumSize: const Size(12, 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wait for biometric provider to load and setup biometric if possible
  Future<void> _waitForBiometricAndSetup(BuildContext context, WidgetRef ref, String pinCode) async {
    // Read the biometric provider and wait for it to finish loading
    ref.read(biometricProvider.notifier);

    // Keep checking until the provider is no longer loading
    while (ref.read(biometricProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Now read the final state and check if we can enroll
    final biometricState = ref.read(biometricProvider);

    if (biometricState.canEnroll && !_biometricSetupAttempted) {
      // Add delay before showing the bottom sheet
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_biometricSetupAttempted && context.mounted) {
        _handleBiometricSetup(context, ref, pinCode);
      }
    }
  }

  /// Handle biometric setup during onboarding
  Future<void> _handleBiometricSetup(BuildContext context, WidgetRef ref, String pinCode) async {
    try {
      _biometricSetupAttempted = true;

      // Show bottom sheet for biometric setup confirmation
      final shouldSetup = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(scaleSize(20)),
              topRight: Radius.circular(scaleSize(20)),
            ),
          ),
          padding: EdgeInsets.all(scaleSize(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: scaleSize(40),
                height: scaleSize(4),
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(scaleSize(2)),
                ),
              ),
              SizedBox(height: scaleSize(20)),

              // Title with icon
              Row(
                children: [
                  Icon(Icons.fingerprint, color: context.colorScheme.primary, size: scaleSize(24)),
                  SizedBox(width: scaleSize(12)),
                  Expanded(
                    child: Text(
                      'setupBiometric'.tr(),
                      style: TextStyle(
                        fontSize: scaleSize(20),
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: scaleSize(16)),

              // Description
              Text(
                'wouldYouLikeToSetupBiometricAuth'.tr(),
                style: TextStyle(fontSize: scaleSize(16), color: context.colorScheme.onSurface.withValues(alpha: 0.8)),
              ),
              SizedBox(height: scaleSize(24)),

              // Action buttons with better design
              Column(
                children: [
                  // Setup Now button (primary action)
                  SizedBox(
                    width: double.infinity,
                    height: scaleSize(50),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(12))),
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(12)),
                      ),
                      child: Text(
                        'setupNow'.tr(),
                        style: TextStyle(fontSize: scaleSize(16), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: scaleSize(12)),

                  // Skip button (secondary action)
                  SizedBox(
                    width: double.infinity,
                    height: scaleSize(50),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(scaleSize(12))),
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(12)),
                      ),
                      child: Text(
                        'skip'.tr(),
                        style: TextStyle(fontSize: scaleSize(16), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + scaleSize(8)),
            ],
          ),
        ),
      );

      if (shouldSetup == true && context.mounted) {
        // Actually setup biometric authentication
        await _setupBiometricAuthentication(context, ref, pinCode);
      }

      // Flag is already set to true, no need to change it
      // This ensures the bottom sheet never reappears
    } catch (e) {
      log.e('Error setting up biometric during onboarding: $e');
      // Flag remains true to prevent re-showing even on error
    }
  }

  /// Actually setup biometric authentication with PIN collection
  Future<void> _setupBiometricAuthentication(BuildContext context, WidgetRef ref, String pinCode) async {
    try {
      // Show loading while setting up
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(scaleSize(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: scaleSize(16)),
                  Text('settingUpBiometric'.tr()),
                ],
              ),
            ),
          ),
        ),
      );

      // Attempt to enroll biometric
      final biometricNotifier = ref.read(biometricProvider.notifier);
      final result = await biometricNotifier.enrollBiometric(pinCode);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (result.success) {
          // Success message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('biometricSetupSuccessful'.tr()), backgroundColor: Colors.green));
        } else {
          // Error message
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('biometricSetupFailed'.tr()), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }
}

Widget finishButton(BuildContext context) {
  return ScaledSizedBox(
    width: 340,
    height: 55,
    child: ElevatedButton(
      key: keyGoWalletsHome,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: context.colorScheme.primary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
      ),
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.myWallets, ModalRoute.withName(RouteNames.home));
      },
      child: Text(
        "accessMySafe".tr(),
        style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
