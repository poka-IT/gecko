import 'dart:async';
import 'package:durt2/durt2.dart' show SafeEntity, WalletEntity, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/pin_security_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/pin_security_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/cached_avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/widgets/safe_carousel.dart';
import 'package:gecko/widgets/biometric/biometric_auth_button.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/pin/gecko_pin_entry.dart';

class UnlockingWallet extends ConsumerStatefulWidget {
  const UnlockingWallet({
    super.key = keyUnlockWallet,
    required this.wallet,
    this.canSwitch = false,
    this.embeddedMode = false,
  });

  final WalletEntity wallet;
  final bool canSwitch; // Whether user can switch between safes during unlock
  final bool embeddedMode; // When true, removes Scaffold wrapper for embedding in desktop modal

  @override
  ConsumerState<UnlockingWallet> createState() => _UnlockingWalletState();
}

class _UnlockingWalletState extends ConsumerState<UnlockingWallet> {
  late int currentSafeNumber;
  late SafeEntity currentSafe;
  late List<SafeEntity> allSafes;
  int currentSafeIndex = 0;
  bool canUnlock = true;
  bool _hasNonLegacySafes = false;
  final _pinController = GeckoPinEntryController();
  final CarouselSliderController carouselController = CarouselSliderController();

  // Biometric state tracking
  bool _biometricTriggered = false;

  // Security state tracking
  Timer? _securityCountdownTimer;
  bool _wasLockedOut = false;

  @override
  void initState() {
    super.initState();
    _initializeSafes();

    // Initialize security state and trigger automatic biometric authentication after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeSecurity();
      // Refresh biometric state for the target safe (may differ from default)
      await ref.read(biometricProvider.notifier).refreshForSafe(currentSafeNumber);
      _tryAutomaticBiometric();
    });
  }

  /// Initialize security state for the current safe
  void _initializeSecurity() {
    ref.read(pinSecurityProvider.notifier).updateForSafe(currentSafeNumber);
  }

  // Removed didChangeDependencies to avoid conflicts with PIN focus and auto-reloads

  /// Initialize the safes list and current selection
  void _initializeSafes() {
    currentSafeNumber = widget.wallet.safe.target?.number ?? ref.read(walletServiceProvider).defaultSafeBoxNumber;

    if (widget.canSwitch) {
      // Multi-safe support enabled - load all safes
      allSafes = ref.read(walletServiceProvider).safeBox.getAll();
      if (allSafes.isEmpty) {
        // This shouldn't happen, but handle gracefully
        throw Exception('No safes found');
      }

      // Sort safes by number for consistent ordering
      allSafes.sort((a, b) => a.number.compareTo(b.number));

      // Find current safe index
      currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentSafeNumber);
      if (currentSafeIndex == -1) {
        currentSafeIndex = 0; // Fallback to first safe
        currentSafeNumber = allSafes[0].number;
      }
      currentSafe = allSafes[currentSafeIndex];

      // Check if at least one non-legacy safe exists
      _hasNonLegacySafes = allSafes.any((safe) => safe.safeType != SafeType.legacy);
    } else {
      // Single-safe mode - only load current safe
      try {
        currentSafe = ref.read(walletServiceProvider).getSafeBox(currentSafeNumber);
        allSafes = [currentSafe]; // Single safe in list
        currentSafeIndex = 0;
      } catch (e) {
        throw Exception('Current safe $currentSafeNumber not found');
      }
    }
  }

  /// Try automatic biometric authentication if enabled
  Future<void> _tryAutomaticBiometric() async {
    if (_biometricTriggered) return;

    _biometricTriggered = true;

    try {
      // Wait for biometric provider to fully initialize
      final biometricNotifier = ref.read(biometricProvider.notifier);
      await biometricNotifier.waitForInitialization();

      // Check if biometric authentication is available after initialization
      final biometricState = ref.read(biometricProvider);
      if (!biometricState.canAuthenticate) {
        return;
      }

      // Attempt biometric authentication
      final result = await biometricNotifier.authenticateWithBiometric();

      if (result.success && result.pin != null && mounted) {
        // Success - handle PIN completion
        await _handlePinCompletion(result.pin!, fromBiometric: true);
      }
    } catch (e) {
      // Error during biometric setup - user can use manual PIN entry
      log.e('Error during automatic biometric authentication: $e');
    }
  }

  /// Handle PIN completion (extracted from PIN form for reuse with biometric auth)
  Future<void> _handlePinCompletion(String pin, {bool fromBiometric = false}) async {
    final pinNotifier = ref.read(pinStateProvider.notifier);
    final derivationNotifier = ref.read(derivationStateProvider.notifier);
    final securityState = ref.read(pinSecurityProvider);

    // Check if safe is currently locked out
    if (securityState.isLockedOut) {
      // Don't process PIN if locked out
      return;
    }

    try {
      pinNotifier.setLoading(true);
      PinCodeService.cachePin(pin.toUpperCase());

      // Add timeout to the entire unlock operation
      final unlockFuture = Future(() async {
        final isValid = await ref
            .read(walletServiceProvider)
            .checkCode(pin: pin.toUpperCase(), safeBoxNumber: currentSafeNumber);
        if (!isValid) {
          // Record failed attempt for security tracking
          await ref.read(pinSecurityProvider.notifier).recordFailedAttempt(currentSafeNumber);

          // Check if safe should be deleted immediately
          final securityState = ref.read(pinSecurityProvider);
          if (securityState.shouldDeleteSafe) {
            await _handleSafeDeletion();
            return;
          }

          await Future.delayed(const Duration(milliseconds: 20));
          pinNotifier.setLoading(false);
          pinNotifier.setValid(false);
          PinCodeService.clearPin();
          derivationNotifier.clearMnemonic();
          if (!fromBiometric) {
            _pinController.triggerError();
          }
        } else {
          // Reset failed attempts on successful unlock
          await ref.read(pinSecurityProvider.notifier).resetFailedAttempts(currentSafeNumber);

          pinNotifier.setValid(true);
          if (!fromBiometric) {
            _pinController.triggerSuccess();
          }

          // Update the default safe to the currently selected one
          ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(currentSafeNumber);

          // Invalidate providers after changing default safe to fix state synchronization
          ref.read(walletActionsProvider.notifier).invalidateProviders();

          // Invalidate identity providers to ensure they use the new safe
          ref.invalidate(idtyWalletAsyncProvider);
          ref.invalidate(identityWalletsAsyncProvider);

          // Wait for Durt to be connected and wallets to be loaded before allowing access
          await _waitForSystemReady();

          pinNotifier.setLoading(false);
          PinCodeService.setAuthenticatedSafe(currentSafeNumber);
          PinCodeService.debounceResetPinCode();

          // ALWAYS return success and let the caller decide navigation
          if (!mounted) return;
          Navigator.pop(context, pin.toUpperCase());
        }
      });

      // Apply global timeout to prevent hanging
      await unlockFuture.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Unlock operation timeout after 60 seconds');
        },
      );
    } catch (e) {
      // Comprehensive error handling
      pinNotifier.setLoading(false);
      pinNotifier.setValid(false);
      PinCodeService.clearPin();
      derivationNotifier.clearMnemonic();
      if (!fromBiometric) {
        _pinController.triggerError();
      }

      String errorMessage;
      bool isInvalidPin = false;

      // Check for Invalid secret code (incorrect PIN)
      if (e.toString().contains('Invalid secret code')) {
        isInvalidPin = true;
        errorMessage = 'incorrectPinCode'.tr();
      } else if (e is TimeoutException) {
        errorMessage = 'Timeout: ${e.message ?? 'Operation took too long'}';
      } else {
        errorMessage = 'Unlock failed: ${e.toString()}';
      }

      // Log error for debugging
      log.e('🔴 Unlock error: $errorMessage');

      // For invalid PIN, just trigger the existing UI feedback
      if (isInvalidPin) {
        // The existing "thisIsNotAGoodCode" message will be shown
        // by the UI when isPinValid is false
      } else {
        // Show error snackbar for other errors (timeouts, network issues, etc.)
        if (mounted) {
          SnackbarService.showError(context, message: errorMessage, duration: 5);
        }
      }
    }
  }

  Future<void> _waitForSystemReady() async {
    // Wait for both Durt connection and storage initialization with total timeout of 2 seconds
    final systemTimeout = DateTime.now().add(const Duration(seconds: 2));
    bool isDurtConnected = false;
    bool isStorageReady = false;

    while ((!isDurtConnected || !isStorageReady) && DateTime.now().isBefore(systemTimeout)) {
      // Check Durt connection
      if (!isDurtConnected) {
        isDurtConnected = ref.read(durtProvider).isConnected;
      }

      // Check storage initialization
      if (!isStorageReady) {
        try {
          final _ = ref.read(durtProvider).storage;
          isStorageReady = true;
        } catch (e) {
          log.e('🔴 Storage service not ready yet: $e');
        }
      }

      // Both ready? Exit early
      if (isDurtConnected && isStorageReady) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!isDurtConnected || !isStorageReady) {
      log.e(
        '🔴 System not fully ready after 2 seconds, continuing anyway (Durt: $isDurtConnected, Storage: $isStorageReady)',
      );
    }

    await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: currentSafeNumber);
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinStateProvider);
    final securityState = ref.watch(pinSecurityProvider);

    // Handle lockout state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_wasLockedOut && !securityState.isLockedOut && mounted) {
        // Lockout just ended, clear PIN field
        _pinController.clear();
      }
      _wasLockedOut = securityState.isLockedOut;
    });

    final topSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!widget.embeddedMode)
          Padding(
            padding: EdgeInsets.only(left: 8, top: isTall ? 8 : 0),
            child: IconButton(
              key: keyPopButton,
              icon: Icon(Icons.arrow_back, color: Colors.black, size: scaleSize(28)),
              onPressed: () {
                ref.read(pinStateProvider.notifier).setValid(false);
                ref.read(pinStateProvider.notifier).setLoading(true);
                Navigator.pop(context);
              },
            ),
          ),
        // Safe display
        widget.canSwitch ? _buildSafeSlider(context) : _buildStaticSafeDisplay(context),
        ScaledSizedBox(height: isTall ? 12 : 6),
      ],
    );

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final pinSection = Container(
      padding: EdgeInsets.only(left: 20, right: 20, top: isTall ? 12 : 8, bottom: 4 + bottomSafe),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Instruction text — compact
          Text(
            'toUnlockEnterPassword'.tr(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          // Remember PIN toggle — compact inline
          if (canUnlock)
            StatefulBuilder(
              builder: (context, setState) {
                final pinCacheState = PinCodeService.isEnabled;
                return GestureDetector(
                  key: keyCachePassword,
                  onTap: () => setState(() => PinCodeService.toggle()),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(10), vertical: 3),
                    decoration: BoxDecoration(
                      color: pinCacheState
                          ? context.geckoColors.success.withValues(alpha: 0.15)
                          : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: pinCacheState
                            ? context.geckoColors.success.withValues(alpha: 0.3)
                            : context.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pinCacheState ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: pinCacheState ? context.geckoColors.success : context.colorScheme.onSurfaceVariant,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'rememberPassword'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: scaledTextStyle(
                              fontSize: 14,
                              color: pinCacheState ? context.geckoColors.success : context.colorScheme.onSurfaceVariant,
                              fontWeight: pinCacheState ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 18,
                          width: 32,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Switch.adaptive(
                              value: pinCacheState,
                              onChanged: (_) => setState(() => PinCodeService.toggle()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 6),
          // Security messages and PIN error display
          Consumer(
            builder: (context, ref, child) {
              final securityState = ref.watch(pinSecurityProvider);

              // Show safe deletion warning
              if (securityState.shouldShowWarning) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.geckoColors.dangerContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.geckoColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          securityState.remainingAttempts <= 3
                              ? 'pinSecurityFinalWarning'.tr(args: [securityState.remainingAttempts.toString()])
                              : 'pinSecurityWarningTitle'.tr(),
                          style: scaledTextStyle(
                            color: context.geckoColors.dangerText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'pinSecurityWarningMessage'.tr(args: [securityState.remainingAttempts.toString()]),
                          style: scaledTextStyle(color: context.geckoColors.danger, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        if (securityState.isLockedOut) ...[
                          const SizedBox(height: 4),
                          Text(
                            'pinSecurityUnlocksIn'.tr(
                              args: [PinSecurityService.formatLockoutTime(securityState.remainingLockoutSeconds)],
                            ),
                            style: scaledTextStyle(
                              color: context.geckoColors.warningText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Show lockout message
              if (securityState.isLockedOut) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.geckoColors.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'pinSecurityLocked'.tr(),
                          style: scaledTextStyle(
                            color: context.geckoColors.warningText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'pinSecurityUnlocksIn'.tr(
                            args: [PinSecurityService.formatLockoutTime(securityState.remainingLockoutSeconds)],
                          ),
                          style: scaledTextStyle(color: context.geckoColors.warning, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show regular PIN error
              final pinState = ref.watch(pinStateProvider);
              if (!pinState.isValid && !pinState.isLoading) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "thisIsNotAGoodCode".tr(),
                    style: scaledTextStyle(
                      color: context.geckoColors.dangerText,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          // PIN entry — Expanded so it fills remaining space and adapts button sizes
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    ref.watch(pinSecurityProvider);
                    return pinForm(context, pinLength);
                  },
                ),
                if (pinState.isLoading && _pinController.text.length == pinLength)
                  Container(
                    width: double.infinity,
                    height: scaleSize(80),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: scaleSize(20),
                          height: scaleSize(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
                          ),
                        ),
                        ScaledSizedBox(height: 6),
                        Text(
                          'loading'.tr(),
                          style: scaledTextStyle(
                            color: context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    void popCallback(bool _, dynamic __) {
      ref.read(pinStateProvider.notifier).setValid(false);
      ref.read(pinStateProvider.notifier).setLoading(true);
    }

    Widget buildLayout({required bool constrained}) {
      final screenHeight = MediaQuery.of(context).size.height;
      final maxTopHeight = screenHeight * 0.3;

      final topWidget = constrained
          ? ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: topSection)
          : topSection;

      return Column(
        children: [
          // Top section: capped at 30% of screen, scrolls if content overflows
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxTopHeight),
            child: SingleChildScrollView(physics: const ClampingScrollPhysics(), child: topWidget),
          ),
          // PIN section: takes ALL remaining space
          Expanded(child: pinSection),
        ],
      );
    }

    if (widget.embeddedMode) {
      return PopScope(onPopInvokedWithResult: popCallback, child: buildLayout(constrained: true));
    }

    return PopScope(
      onPopInvokedWithResult: popCallback,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: ResponsiveCenter(maxWidth: 500, padding: EdgeInsets.zero, child: buildLayout(constrained: false)),
        ),
      ),
    );
  }

  /// Build the safe carousel slider with multi-safe support
  Widget _buildSafeSlider(BuildContext context) {
    // Show carousel with optional placeholder for creating new safes
    final showPlaceholder = widget.canSwitch && _hasNonLegacySafes;
    final totalItems = allSafes.length + (showPlaceholder ? 1 : 0);
    final isPlaceholderSelected = showPlaceholder && currentSafeIndex >= allSafes.length;

    return Column(
      children: [
        // Always show carousel slider for safe selection + creation
        SizedBox(
          height: scaleSize(isTall ? 80 : 64),
          child: SafeCarousel(
            allSafes: allSafes,
            currentSafeIndex: currentSafeIndex,
            carouselController: carouselController,
            onPageChanged: (index, reason) {
              setState(() {
                currentSafeIndex = index;
                if (index < allSafes.length) {
                  // Regular safe selected
                  currentSafe = allSafes[index];
                  currentSafeNumber = currentSafe.number;

                  // Update the default safe to the currently selected one
                  ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(currentSafeNumber);

                  // Invalidate identity providers to ensure they use the new safe
                  ref.invalidate(idtyWalletAsyncProvider);
                  ref.invalidate(identityWalletsAsyncProvider);

                  // Reset PIN state when changing safes
                  _pinController.clear();
                  ref.read(biometricProvider.notifier).refreshForSafe(currentSafeNumber);

                  // Update security state for new safe
                  ref.read(pinSecurityProvider.notifier).updateForSafe(currentSafeNumber);
                }
                // If placeholder is selected, we don't update currentSafe
              });
            },
            onSafeCreated: _simpleReloadSafes,
            onSafeImported: _simpleReloadSafes,
            showCreatePlaceholder: showPlaceholder,
            height: scaleSize(isTall ? 80 : 64),
            isCompact: true,
          ),
        ),

        ScaledSizedBox(height: 4),

        // Safe name or action hint
        Text(
          isPlaceholderSelected ? 'createOrImportSafe'.tr() : WalletNameService.displayName(currentSafe.name),
          textAlign: TextAlign.center,
          style: scaledTextStyle(
            fontSize: isTall ? 18 : 16,
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),

        ScaledSizedBox(height: 2),

        // Pagination dots for all items (including placeholder)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalItems, (index) {
            return GestureDetector(
              onTap: () {
                carouselController.animateToPage(index);
              },
              child: Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (context.colorScheme.onSurface).withValues(alpha: currentSafeIndex == index ? 0.9 : 0.4),
                ),
              ),
            );
          }),
        ),

        ScaledSizedBox(height: 4),

        // Hint text (only show if canSwitch is enabled)
        if (widget.canSwitch)
          Text(
            isPlaceholderSelected
                ? 'tapToCreateOrImport'.tr()
                : (allSafes.length > 1 ? 'swipeToChangeSafe'.tr() : (showPlaceholder ? 'swipeToCreateSafe'.tr() : '')),
            style: scaledTextStyle(
              fontSize: 11,
              color: context.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  /// Build static safe display when switching is not allowed
  Widget _buildStaticSafeDisplay(BuildContext context) {
    return Column(
      children: [
        // Safe image without carousel
        SizedBox(
          height: scaleSize(isTall ? 80 : 64),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: currentSafe.imagePath == null
                  ? (currentSafe.safeType == SafeType.legacy
                        ? SvgPicture.asset(
                            'assets/cesium_bw2.svg',
                            width: scaleSize(isTall ? 95 : 75),
                            fit: BoxFit.contain,
                            semanticsLabel: 'Cesium',
                          )
                        : Image.asset(
                            'assets/safes/${currentSafe.number % 4}.png',
                            width: scaleSize(isTall ? 95 : 75),
                            fit: BoxFit.contain,
                          ))
                  : CachedAvatarImage(
                      imagePath: currentSafe.imagePath!,
                      fit: BoxFit.contain,
                      isCircular: false,
                      fallback: Image.asset(
                        'assets/safes/${currentSafe.number % 4}.png',
                        width: scaleSize(isTall ? 95 : 75),
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
        ),
        ScaledSizedBox(height: 8),
        // Safe name (no pagination dots, no hint)
        Text(
          WalletNameService.displayName(currentSafe.name),
          textAlign: TextAlign.center,
          style: scaledTextStyle(
            fontSize: isTall ? 24 : 20,
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        ScaledSizedBox(height: 16), // Extra space to compensate for missing dots/hint
      ],
    );
  }

  /// Simple reload of safes without complex logic
  void _simpleReloadSafes() {
    if (!mounted) return;

    // Only reload if canSwitch is enabled, otherwise safes shouldn't change
    if (!widget.canSwitch) return;

    setState(() {
      // Reload all safes
      allSafes = ref.read(walletServiceProvider).safeBox.getAll();
      allSafes.sort((a, b) => a.number.compareTo(b.number));

      // Recalculate non-legacy safes flag
      _hasNonLegacySafes = allSafes.any((safe) => safe.safeType != SafeType.legacy);

      // Update to the current default safe
      currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentSafeNumber);

      if (currentSafeIndex >= 0 && currentSafeIndex < allSafes.length) {
        currentSafe = allSafes[currentSafeIndex];
      } else if (allSafes.isNotEmpty) {
        // Fallback to first safe if default not found
        currentSafeIndex = 0;
        currentSafe = allSafes[0];
        currentSafeNumber = currentSafe.number;
      }
    });

    // Update carousel position if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && allSafes.isNotEmpty && currentSafeIndex >= 0) {
        carouselController.animateToPage(currentSafeIndex);
      }
    });
  }

  /// Handle safe deletion due to too many failed attempts
  Future<void> _handleSafeDeletion() async {
    try {
      // Delete the safe from storage
      await ref.read(walletServiceProvider).deleteSafe(currentSafeNumber);

      // Clean up security data
      await ref.read(pinSecurityProvider.notifier).deleteSafeSecurityData(currentSafeNumber);

      if (mounted) {
        // Show deletion confirmation dialog
        await showConfirmationDialog(
          context: context,
          type: ConfirmationDialogType.error,
          title: 'pinSecuritySafeDeleted'.tr(),
          message: ['pinSecuritySafeDeletedMessage'.tr(), 'pinSecuritySafeDeletedSubMessage'.tr()].join('\n\n'),
          confirmText: 'pinSecurityReturnHome'.tr(),
          hideCancelButton: true,
          barrierDismissible: false,
        );

        // Check if there are remaining safes and refresh home state accordingly
        final remainingSafes = ref.read(walletServiceProvider).safeBox.getAll();

        if (mounted) {
          // Return to home
          Navigator.of(context).pop();

          // If no safes left, we need to trigger a home state refresh
          if (remainingSafes.isEmpty) {
            // Force refresh of the home providers to switch to welcome state
            _refreshHomeStateForNoSafes();
          }
        }
      }
    } catch (e) {
      log.e('Error deleting safe: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Return to home on error
      }
    }
  }

  /// Force refresh of home state when no safes are left
  void _refreshHomeStateForNoSafes() {
    try {
      // Force refresh of wallet list and invalidate providers
      ref.read(walletsListProvider.notifier).refresh();

      log.i('Home state refreshed - should switch to welcome mode');
    } catch (e) {
      log.e('Error refreshing home state: $e');
    }
  }

  @override
  void dispose() {
    _securityCountdownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Widget pinForm(BuildContext context, int pinLenght) {
    final biometricState = ref.watch(biometricProvider);
    final securityState = ref.watch(pinSecurityProvider);

    // Don't auto-focus PIN field if biometric authentication is available and hasn't been triggered yet
    // This prevents virtual keyboard from appearing when biometric popup will show instead
    // Also don't auto-focus if safe is locked out
    final shouldAutoFocus = (!biometricState.canAuthenticate || _biometricTriggered) && !securityState.isLockedOut;
    final isFieldEnabled = !securityState.isLockedOut;

    // Build biometric button widget for the numpad bottom-left slot
    Widget? biometricButton;
    if (currentSafeIndex < allSafes.length) {
      final biometricCanAuth = biometricState.canAuthenticate;
      final isLockedOut = securityState.isLockedOut;
      if (!isLockedOut && biometricCanAuth) {
        biometricButton = BiometricAuthButton(
          onAuthSuccess: (String pin) {
            _handlePinCompletion(pin, fromBiometric: true);
          },
          onAuthFailure: (String error) {
            // Error is already shown by the button widget
          },
          tooltip: 'useBiometricAuthentication'.tr(),
          size: 50.0,
        );
      }
    }

    return GeckoPinEntry(
      key: keyPinForm,
      controller: _pinController,
      autoFocus: shouldAutoFocus,
      enabled: isFieldEnabled,
      length: pinLenght,
      onCompleted: (pin) => _handlePinCompletion(pin),
      onChanged: (value) {
        if (value.isNotEmpty) {
          ref.read(pinStateProvider.notifier).setLoading(true);
        }
      },
      bottomLeftWidget: biometricButton,
    );
  }
}
