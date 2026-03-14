// ignore_for_file: use_build_context_synchronously

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
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:gecko/globals.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/widgets/safe_carousel.dart';
import 'package:gecko/widgets/biometric/biometric_auth_button.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/gecko_pin_field.dart';

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
  late final TextEditingController enterPin;
  late final FocusNode pinFocus;
  late final PinInputController _pinController;
  final CarouselSliderController carouselController = CarouselSliderController();

  // Biometric state tracking
  bool _biometricTriggered = false;

  // Security state tracking
  Timer? _securityCountdownTimer;
  bool _wasLockedOut = false;

  Color pinColor = const Color(0xffF9F9F1);

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode');
    enterPin = TextEditingController();
    _pinController = PinInputController(textController: enterPin, focusNode: pinFocus);
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
        // Biometric not available or not enrolled, focus on PIN field
        if (mounted) {
          pinFocus.requestFocus();
        }
        return;
      }

      // Attempt biometric authentication
      final result = await biometricNotifier.authenticateWithBiometric();

      if (result.success && result.pin != null && mounted) {
        // Success - handle PIN completion
        await _handlePinCompletion(result.pin!, fromBiometric: true);
      } else {
        // Failed or cancelled - focus on PIN field for manual entry
        if (mounted) {
          pinFocus.requestFocus();
        }
      }
    } catch (e) {
      // Error during biometric setup - focus on PIN field for manual entry
      log.e('Error during automatic biometric authentication: $e');
      if (mounted) {
        pinFocus.requestFocus();
      }
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
      PinCodeService.pinCode = pin.toUpperCase();

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
          setState(() {
            pinColor = Colors.red[600]!;
          });
          pinNotifier.setLoading(false);
          pinNotifier.setValid(false);
          PinCodeService.pinCode = '';
          derivationNotifier.clearMnemonic();
          if (!fromBiometric) {
            enterPin.text = '';
            pinFocus.requestFocus();
          }
        } else {
          // Reset failed attempts on successful unlock
          await ref.read(pinSecurityProvider.notifier).resetFailedAttempts(currentSafeNumber);

          pinNotifier.setValid(true);
          setState(() {
            pinColor = Colors.green[400]!;
          });

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
      PinCodeService.pinCode = '';
      derivationNotifier.clearMnemonic();
      if (!fromBiometric) {
        enterPin.text = '';
      }
      setState(() {
        pinColor = Colors.red[600]!;
      });

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
        if (!fromBiometric) {
          pinFocus.requestFocus();
        }
      } else {
        // Show error snackbar for other errors (timeouts, network issues, etc.)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
          );
        }
        if (!fromBiometric) {
          pinFocus.requestFocus();
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
        // Lockout just ended, clear PIN field and refocus
        setState(() {
          enterPin.clear();
          pinColor = const Color(0xffF9F9F1);
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            pinFocus.requestFocus();
          }
        });
      }
      _wasLockedOut = securityState.isLockedOut;
    });

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!widget.embeddedMode) ...[
          Padding(
            padding: EdgeInsets.only(left: 8, top: isTall ? 14 : 0),
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
          ScaledSizedBox(height: isTall ? 12 : 4),
        ],
        // Safe display - either slider (if canSwitch) or static (if locked)
        widget.canSwitch ? _buildSafeSlider(context) : _buildStaticSafeDisplay(context),
        ScaledSizedBox(height: widget.embeddedMode ? 16 : (isTall ? 30 : 15)),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(isTall ? 24 : 16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Text(
                'toUnlockEnterPassword'.tr(),
                textAlign: TextAlign.center,
                style: scaledTextStyle(
                  fontSize: isTall ? 16 : 14,
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ScaledSizedBox(height: isTall ? 16 : 8),
              // Remember PIN toggle card
              if (canUnlock)
                StatefulBuilder(
                  builder: (context, setState) {
                    final pinCacheState = PinCodeService.isEnabled;
                    return GestureDetector(
                      key: keyCachePassword,
                      onTap: () {
                        setState(() {
                          PinCodeService.toggle();
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(6)),
                        decoration: BoxDecoration(
                          color: pinCacheState
                              ? const Color(0xff4CAF50).withValues(alpha: 0.15)
                              : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pinCacheState
                                ? const Color(0xff4CAF50).withValues(alpha: 0.3)
                                : context.colorScheme.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pinCacheState ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              color: pinCacheState ? const Color(0xff4CAF50) : context.colorScheme.onSurfaceVariant,
                              size: scaleSize(16),
                            ),
                            ScaledSizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'rememberPassword'.tr(),
                                style: scaledTextStyle(
                                  fontSize: 11,
                                  color: pinCacheState ? const Color(0xff4CAF50) : context.colorScheme.onSurfaceVariant,
                                  fontWeight: pinCacheState ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            ScaledSizedBox(width: 6),
                            SizedBox(
                              height: scaleSize(20),
                              width: scaleSize(34),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Switch.adaptive(
                                  value: pinCacheState,
                                  onChanged: (_) {
                                    setState(() {
                                      PinCodeService.toggle();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ScaledSizedBox(height: isTall ? 16 : 8),
              // Security messages and PIN error display
              Consumer(
                builder: (context, ref, child) {
                  final securityState = ref.watch(pinSecurityProvider);

                  // Show safe deletion warning
                  if (securityState.shouldShowWarning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              securityState.remainingAttempts <= 3
                                  ? 'pinSecurityFinalWarning'.tr(args: [securityState.remainingAttempts.toString()])
                                  : 'pinSecurityWarningTitle'.tr(),
                              style: scaledTextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'pinSecurityWarningMessage'.tr(args: [securityState.remainingAttempts.toString()]),
                              style: scaledTextStyle(color: Colors.red[600], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            // Show countdown if locked out
                            if (securityState.isLockedOut) ...[
                              const SizedBox(height: 8),
                              Text(
                                'pinSecurityUnlocksIn'.tr(
                                  args: [PinSecurityService.formatLockoutTime(securityState.remainingLockoutSeconds)],
                                ),
                                style: scaledTextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
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
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'pinSecurityLocked'.tr(),
                              style: scaledTextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'pinSecurityUnlocksIn'.tr(
                                args: [PinSecurityService.formatLockoutTime(securityState.remainingLockoutSeconds)],
                              ),
                              style: scaledTextStyle(color: Colors.orange[600], fontSize: 12),
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
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "thisIsNotAGoodCode".tr(),
                        style: scaledTextStyle(color: Colors.red[700], fontWeight: FontWeight.w500, fontSize: 15),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      // Force rebuild when security state changes
                      ref.watch(pinSecurityProvider);
                      return pinForm(context, pinLength);
                    },
                  ),
                  if (pinState.isLoading && enterPin.text.length == pinLength)
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
              ScaledSizedBox(height: isTall ? 12 : 8),

              // Biometric authentication button
              if (currentSafeIndex < allSafes.length)
                Consumer(
                  builder: (context, ref, child) {
                    final securityState = ref.watch(pinSecurityProvider);
                    final biometricState = ref.watch(biometricProvider);

                    // Hide button if locked out or biometric not available
                    if (securityState.isLockedOut || !biometricState.canAuthenticate) {
                      return const SizedBox.shrink();
                    }

                    return BiometricAuthButton(
                      onAuthSuccess: (String pin) {
                        _handlePinCompletion(pin, fromBiometric: true);
                      },
                      onAuthFailure: (String error) {
                        // Error is already shown by the button widget
                      },
                      tooltip: 'useBiometricAuthentication'.tr(),
                      size: 50.0,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.embeddedMode) {
      return PopScope(
        onPopInvokedWithResult: (_, _) {
          ref.read(pinStateProvider.notifier).setValid(false);
          ref.read(pinStateProvider.notifier).setLoading(true);
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: content),
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        ref.read(pinStateProvider.notifier).setValid(false);
        ref.read(pinStateProvider.notifier).setLoading(true);
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveCenter(maxWidth: 500, padding: EdgeInsets.zero, child: content),
          ),
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
          height: scaleSize(isTall ? 140 : 120),
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
                  enterPin.clear();
                  pinColor = const Color(0xffF9F9F1);
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
            height: scaleSize(isTall ? 140 : 120),
            isCompact: true,
          ),
        ),

        ScaledSizedBox(height: 8),

        // Safe name or action hint
        Text(
          isPlaceholderSelected ? 'createOrImportSafe'.tr() : WalletNameService.displayName(currentSafe.name),
          textAlign: TextAlign.center,
          style: scaledTextStyle(
            fontSize: isTall ? 24 : 20,
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),

        ScaledSizedBox(height: 4),

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
          height: scaleSize(isTall ? 140 : 120),
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

    return GeckoPinField(
      key: keyPinForm,
      pinController: _pinController,
      autoFocus: shouldAutoFocus,
      enabled: isFieldEnabled,
      pinColor: pinColor,
      length: pinLenght,
      onCompleted: (pin) => _handlePinCompletion(pin),
      onChanged: (value) {
        if (enterPin.text != '') {
          ref.read(pinStateProvider.notifier).setLoading(true);
        }
        if (pinColor != const Color(0xFFA4B600)) {
          pinColor = const Color(0xFFA4B600);
        }
        // Force widget rebuild for PIN color change
        setState(() {});
      },
    );
  }
}
