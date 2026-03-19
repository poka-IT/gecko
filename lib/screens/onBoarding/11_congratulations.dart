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
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gif_view/gif_view.dart';

class OnboardingStepEleven extends ConsumerStatefulWidget {
  const OnboardingStepEleven({super.key, this.fromRestore = false, this.isLegacyMode = false});
  final bool fromRestore;
  final bool isLegacyMode;

  @override
  ConsumerState<OnboardingStepEleven> createState() => _OnboardingStepElevenState();
}

class _OnboardingStepElevenState extends ConsumerState<OnboardingStepEleven> with TickerProviderStateMixin {
  // Instance flag to prevent multiple bottom sheet openings
  bool _biometricSetupAttempted = false;

  // Scroll detection variables
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;
  bool _isAtBottom = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize scroll detection
    _scrollController.addListener(_scrollListener);

    // Initialize animation
    _animationController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Start pulsing animation
    _animationController.repeat(reverse: true);

    // Check if content is scrollable after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollable();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final bool isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;

    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
      });
    }
  }

  void _checkScrollable() {
    if (!_scrollController.hasClients) return;

    // Only show indicator if there's meaningful scroll content (more than 10 pixels)
    final bool isScrollable = _scrollController.position.maxScrollExtent > 50;
    if (_showScrollIndicator != isScrollable) {
      setState(() {
        _showScrollIndicator = isScrollable;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

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
              ResponsiveCenter(
                maxWidth: 500,
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                          child: finishButton(context, widget.isLegacyMode),
                        ),
                        ScaledSizedBox(height: isTall ? 40 : 5),
                      ],
                    ),
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
              // Scroll indicator at bottom
              if (_showScrollIndicator && !_isAtBottom)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: GestureDetector(
                            onTap: _scrollToBottom,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    'scrollToContinue'.tr(),
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
    // Wait for biometric provider to finish initialization
    final biometricNotifier = ref.read(biometricProvider.notifier);
    await biometricNotifier.waitForInitialization();

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
        constraints: const BoxConstraints(maxWidth: 600),
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
          SnackbarService.showSuccess(context, message: 'biometricSetupSuccessful'.tr());
        } else {
          // Error message
          SnackbarService.showError(context, message: 'biometricSetupFailed'.tr());
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        SnackbarService.showError(context, message: 'anErrorOccurred'.tr());
      }
    }
  }
}

Widget finishButton(BuildContext context, [bool isLegacyMode = false]) {
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
        // Force refresh of wallet providers before navigation to ensure correct safe is loaded
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.myWallets, ModalRoute.withName(RouteNames.home));
      },
      child: Text(
        isLegacyMode ? "accessMyWallet".tr() : "accessMySafe".tr(),
        style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
