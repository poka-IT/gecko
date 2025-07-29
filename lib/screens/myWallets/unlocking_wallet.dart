// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:durt2/durt2.dart' show SafeEntity, WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/wallet_options.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/globals.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/widgets/safe_carousel.dart';
import 'package:gecko/widgets/biometric/biometric_auth_button.dart';

class UnlockingWallet extends ConsumerStatefulWidget {
  const UnlockingWallet({required this.wallet, this.canSwitch = false}) : super(key: keyUnlockWallet);

  final WalletEntity wallet;
  final bool canSwitch; // Whether user can switch between safes during unlock

  @override
  ConsumerState<UnlockingWallet> createState() => _UnlockingWalletState();
}

class _UnlockingWalletState extends ConsumerState<UnlockingWallet> {
  late int currentSafeNumber;
  late SafeEntity currentSafe;
  late List<SafeEntity> allSafes;
  int currentSafeIndex = 0;
  bool canUnlock = true;
  late final TextEditingController enterPin;
  late final FocusNode pinFocus;
  final CarouselSliderController carouselController = CarouselSliderController();

  // Biometric state tracking
  bool _biometricTriggered = false;

  Color pinColor = const Color(0xffF9F9F1);

  @override
  void initState() {
    super.initState();
    pinFocus = FocusNode(debugLabel: 'pinFocusNode');
    enterPin = TextEditingController();
    _initializeSafes();

    // Trigger automatic biometric authentication after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutomaticBiometric();
    });
  }

  // Removed didChangeDependencies to avoid conflicts with PIN focus and auto-reloads

  /// Initialize the safes list and current selection
  void _initializeSafes() {
    currentSafeNumber = ref.read(walletServiceProvider).defaultSafeBoxNumber;

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
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    try {
      myWalletProvider.isPinLoading = true;
      myWalletProvider.pinCode = pin.toUpperCase();

      // Add timeout to the entire unlock operation
      final unlockFuture = Future(() async {
        final isValid = await ref
            .read(walletServiceProvider)
            .checkCode(pin: pin.toUpperCase(), safeBoxNumber: currentSafeNumber);
        if (!isValid) {
          await Future.delayed(const Duration(milliseconds: 20));
          setState(() {
            pinColor = Colors.red[600]!;
          });
          myWalletProvider.isPinLoading = false;
          myWalletProvider.isPinValid = false;
          myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
          if (!fromBiometric) {
            enterPin.text = '';
            pinFocus.requestFocus();
          }
        } else {
          myWalletProvider.isPinValid = true;
          setState(() {
            pinColor = Colors.green[400]!;
          });

          // Update the default safe to the currently selected one
          ref.read(walletServiceProvider).setDefaultSafeBoxNumber(currentSafeNumber);

          // Invalidate providers after changing default safe to fix state synchronization
          myWalletProvider.invalidateProviders();

          // Wait for Durt to be connected and wallets to be loaded before allowing access
          await _waitForSystemReady();

          myWalletProvider.isPinLoading = false;
          myWalletProvider.debounceResetPinCode();

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
      myWalletProvider.isPinLoading = false;
      myWalletProvider.isPinValid = false;
      myWalletProvider.pinCode = myWalletProvider.mnemonic = '';
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
      // ignore: avoid_print
      print('🔴 Unlock error: $errorMessage');

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
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

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
          // ignore: avoid_print
          print('🔴 Storage service not ready yet: $e');
        }
      }

      // Both ready? Exit early
      if (isDurtConnected && isStorageReady) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!isDurtConnected || !isStorageReady) {
      // ignore: avoid_print
      print(
        '🔴 System not fully ready after 2 seconds, continuing anyway (Durt: $isDurtConnected, Storage: $isStorageReady)',
      );
    }

    await myWalletProvider.readAllWallets(safeBoxNumber: currentSafeNumber, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        myWalletProvider.isPinValid = false;
        myWalletProvider.isPinLoading = true;
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 8, top: isTall ? 14 : 0),
                  child: IconButton(
                    key: keyPopButton,
                    icon: Icon(Icons.arrow_back, color: Colors.black, size: scaleSize(28)),
                    onPressed: () {
                      myWalletProvider.isPinValid = false;
                      myWalletProvider.isPinLoading = true;
                      Navigator.pop(context);
                    },
                  ),
                ),
                ScaledSizedBox(height: isTall ? 12 : 4),
                // Safe display - either slider (if canSwitch) or static (if locked)
                widget.canSwitch ? _buildSafeSlider(context) : _buildStaticSafeDisplay(context),
                ScaledSizedBox(height: isTall ? 30 : 15),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(isTall ? 24 : 16),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
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
                      ScaledSizedBox(height: isTall ? 24 : 12),
                      if (!myWalletProvider.isPinValid && !myWalletProvider.isPinLoading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "thisIsNotAGoodCode".tr(),
                            style: scaledTextStyle(color: Colors.red[700], fontWeight: FontWeight.w500, fontSize: 15),
                          ),
                        ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          pinForm(context, pinLength),
                          if (myWalletProvider.isPinLoading && enterPin.text.length == pinLength)
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
                        BiometricAuthButton(
                          onAuthSuccess: (String pin) {
                            _handlePinCompletion(pin, fromBiometric: true);
                          },
                          onAuthFailure: (String error) {
                            // Error is already shown by the button widget
                          },
                          tooltip: 'useBiometricAuthentication'.tr(),
                          size: 50.0,
                        ),

                      ScaledSizedBox(height: isTall ? 12 : 8),
                      if (canUnlock)
                        old_provider.Consumer<WalletOptionsProvider>(
                          builder: (context, sub, _) {
                            return InkWell(
                              key: keyCachePassword,
                              onTap: () {
                                walletOptions.changePinCacheChoice();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    configBox.get('isCacheChecked') ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: context.colorScheme.primary,
                                    size: scaleSize(20),
                                  ),
                                  ScaledSizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'rememberPassword'.tr(),
                                      style: scaledTextStyle(
                                        fontSize: 12,
                                        color: homeContext.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the safe carousel slider with multi-safe support
  Widget _buildSafeSlider(BuildContext context) {
    // Show carousel with optional placeholder for creating new safes
    final totalItems =
        allSafes.length + (widget.canSwitch ? 1 : 0); // +1 for create/import placeholder only if canSwitch
    final isPlaceholderSelected = widget.canSwitch && currentSafeIndex >= allSafes.length;

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
                  ref.read(walletServiceProvider).setDefaultSafeBoxNumber(currentSafeNumber);

                  // Reset PIN state when changing safes
                  enterPin.clear();
                  pinColor = const Color(0xffF9F9F1);
                  ref.read(biometricProvider.notifier).refresh();
                }
                // If placeholder is selected, we don't update currentSafe
              });
            },
            onSafeCreated: _simpleReloadSafes,
            onSafeImported: _simpleReloadSafes,
            showCreatePlaceholder: widget.canSwitch,
            height: scaleSize(isTall ? 140 : 120),
            isCompact: true,
          ),
        ),

        ScaledSizedBox(height: 8),

        // Safe name or action hint
        Text(
          isPlaceholderSelected ? 'createOrImportSafe'.tr() : currentSafe.name,
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
                : (allSafes.length > 1 ? 'swipeToChangeSafe'.tr() : 'swipeToCreateSafe'.tr()),
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
                  ? Image.asset(
                      'assets/safes/${currentSafe.number % 4}.png',
                      width: scaleSize(isTall ? 95 : 75),
                      fit: BoxFit.contain,
                    )
                  : Image.file(File(currentSafe.imagePath!), width: scaleSize(isTall ? 127 : 95), fit: BoxFit.contain),
            ),
          ),
        ),
        ScaledSizedBox(height: 8),
        // Safe name (no pagination dots, no hint)
        Text(
          currentSafe.name,
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

  Widget pinForm(BuildContext context, int pinLenght) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    final biometricState = ref.watch(biometricProvider);

    // Don't auto-focus PIN field if biometric authentication is available and hasn't been triggered yet
    // This prevents virtual keyboard from appearing when biometric popup will show instead
    final shouldAutoFocus = !biometricState.canAuthenticate || _biometricTriggered;

    return Form(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(3), horizontal: scaleSize(isTall ? 30 : 20)),
        child: PinCodeTextField(
          key: keyPinForm,
          textCapitalization: TextCapitalization.characters,
          focusNode: pinFocus,
          autoFocus: shouldAutoFocus,
          appContext: context,
          pastedTextStyle: scaledTextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
          length: pinLenght,
          obscureText: true,
          obscuringCharacter: '●',
          animationType: AnimationType.fade,
          animationDuration: const Duration(milliseconds: 150),
          useHapticFeedback: true,
          validator: (v) {
            if (v!.length < pinLenght) {
              return "yourPasswordLengthIsX".tr(args: [pinLenght.toString()]);
            } else {
              return null;
            }
          },
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: scaleSize(50),
            fieldWidth: scaleSize(50),
            activeFillColor: context.colorScheme.surfaceContainer,
            selectedFillColor: context.colorScheme.surfaceContainer,
            inactiveFillColor: context.colorScheme.surfaceContainer,
            activeColor: pinColor,
            selectedColor: context.colorScheme.primary,
            inactiveColor: Colors.grey[300],
            borderWidth: 1.5,
          ),
          enableActiveFill: true,
          showCursor: !kDebugMode,
          cursorColor: context.colorScheme.primary,
          cursorHeight: 25,
          textStyle: scaledTextStyle(fontSize: 24, height: 1.6, fontWeight: FontWeight.w600),
          backgroundColor: Colors.transparent,
          controller: enterPin,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onCompleted: (pin) => _handlePinCompletion(pin),
          onChanged: (value) {
            if (enterPin.text != '') myWalletProvider.isPinLoading = true;
            if (pinColor != const Color(0xFFA4B600)) {
              pinColor = const Color(0xFFA4B600);
            }
            // Simplified - only reload provider, no safe reloading
            myWalletProvider.reload();
          },
        ),
      ),
    );
  }
}
