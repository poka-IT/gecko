import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:durt2/durt2.dart';
import 'package:local_auth_android/local_auth_android.dart' show AndroidAuthMessages;
import 'package:local_auth_ios/types/auth_messages_ios.dart' show IOSAuthMessages;

/// Provider for biometric authentication state
final biometricProvider = NotifierProvider<BiometricNotifier, BiometricState>(BiometricNotifier.new);

/// State class for biometric authentication
class BiometricState {
  final bool isDeviceSupported;
  final bool isAvailable;
  final List<BiometricType> availableTypes;
  final bool isEnrolledForCurrentSafe;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  const BiometricState({
    this.isDeviceSupported = false,
    this.isAvailable = false,
    this.availableTypes = const [],
    this.isEnrolledForCurrentSafe = false,
    this.isLoading = true, // Start as loading by default
    this.isInitialized = false, // Track if initialization is complete
    this.errorMessage,
  });

  BiometricState copyWith({
    bool? isDeviceSupported,
    bool? isAvailable,
    List<BiometricType>? availableTypes,
    bool? isEnrolledForCurrentSafe,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return BiometricState(
      isDeviceSupported: isDeviceSupported ?? this.isDeviceSupported,
      isAvailable: isAvailable ?? this.isAvailable,
      availableTypes: availableTypes ?? this.availableTypes,
      isEnrolledForCurrentSafe: isEnrolledForCurrentSafe ?? this.isEnrolledForCurrentSafe,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
    );
  }

  bool get canEnroll => isDeviceSupported && isAvailable && availableTypes.isNotEmpty && !isEnrolledForCurrentSafe;
  bool get canAuthenticate => isDeviceSupported && isAvailable && availableTypes.isNotEmpty && isEnrolledForCurrentSafe;
}

/// Notifier for biometric authentication
///
/// NOTE: This is a temporary implementation using local storage.
/// When Durt2 is updated with biometric support, this will be updated to use the proper API.
class BiometricNotifier extends Notifier<BiometricState> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// The safe number currently targeted for biometric operations.
  /// Set by [refreshForSafe], used by [authenticateWithBiometric] and [enrollBiometric].
  int? _targetSafeNumber;

  @override
  BiometricState build() {
    Future.microtask(() => _initializeBiometric());
    return const BiometricState();
  }

  /// Initialize biometric capabilities and state
  Future<void> _initializeBiometric() async {
    state = state.copyWith(isLoading: true, isInitialized: false);

    try {
      // Check device capabilities
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableTypes = await _localAuth.getAvailableBiometrics();

      // Check if enrolled for current safe
      final isEnrolled = await _checkEnrollmentForCurrentSafe();

      state = state.copyWith(
        isDeviceSupported: isDeviceSupported,
        isAvailable: isAvailable,
        availableTypes: availableTypes,
        isEnrolledForCurrentSafe: isEnrolled,
        isLoading: false,
        isInitialized: true,
        errorMessage: null,
      );
    } catch (e) {
      log.e('Error initializing biometric: $e');
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Failed to initialize biometric authentication: $e',
      );
    }
  }

  /// Check if biometric is enrolled for current safe
  Future<bool> _checkEnrollmentForCurrentSafe() async {
    try {
      // Get current default safe number explicitly
      final walletService = ref.read(walletServiceProvider);
      final currentSafe = walletService.defaultSafeBoxNumber;

      // Handle case where no default safe is set (e.g., after deleting all safes)
      if (currentSafe == -1) {
        log.d('No default safe set, biometric enrollment: false');
        return false;
      }

      // Check if the safe still exists before checking enrollment
      try {
        walletService.getSafeBox(currentSafe);
      } catch (e) {
        // Safe doesn't exist anymore (probably deleted), return false
        log.w('Safe $currentSafe not found during biometric check: $e');
        return false;
      }

      // Check enrollment for the specific current safe
      final isEnrolled = await walletService.isBiometricEnrolled(currentSafe);

      log.d('Biometric enrollment check for safe $currentSafe: $isEnrolled');
      return isEnrolled;
    } catch (e) {
      log.e('Error checking biometric enrollment: $e');
      return false;
    }
  }

  /// Refresh biometric state (uses default safe)
  Future<void> refresh() async {
    _targetSafeNumber = null;

    // Force a small delay to ensure storage operations are completed
    await Future.delayed(const Duration(milliseconds: 100));

    // Clear any cached state first
    state = state.copyWith(isEnrolledForCurrentSafe: false, isLoading: true, isInitialized: false, errorMessage: null);

    // Force a complete re-initialization to ensure fresh state
    await _initializeBiometric();
  }

  /// Refresh biometric state for a specific safe number (not necessarily the default).
  /// Used when opening the unlock screen for a non-default safe.
  Future<void> refreshForSafe(int safeNumber) async {
    _targetSafeNumber = safeNumber;
    state = state.copyWith(isLoading: true, isInitialized: false, errorMessage: null);

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableTypes = await _localAuth.getAvailableBiometrics();

      final walletService = ref.read(walletServiceProvider);
      bool isEnrolled = false;
      try {
        walletService.getSafeBox(safeNumber);
        isEnrolled = await walletService.isBiometricEnrolled(safeNumber);
      } catch (_) {}

      state = state.copyWith(
        isDeviceSupported: isDeviceSupported,
        isAvailable: isAvailable,
        availableTypes: availableTypes,
        isEnrolledForCurrentSafe: isEnrolled,
        isLoading: false,
        isInitialized: true,
        errorMessage: null,
      );
    } catch (e) {
      log.e('Error refreshing biometric for safe $safeNumber: $e');
      state = state.copyWith(isLoading: false, isInitialized: true, errorMessage: e.toString());
    }
  }

  /// Enroll biometric authentication for current safe (temporary implementation)
  Future<BiometricEnrollmentResult> enrollBiometric(String pin) async {
    if (!state.canEnroll) {
      return BiometricEnrollmentResult.failure('Biometric authentication is not available or already enrolled');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // First authenticate with device biometric to confirm setup
      final didAuthenticate = await _authenticateWithDevice(
        reason: 'Confirm your identity to enable biometric authentication for this safe',
      );

      if (!didAuthenticate) {
        state = state.copyWith(isLoading: false);
        return BiometricEnrollmentResult.failure('Biometric authentication was cancelled or failed');
      }

      // Use Durt2 to securely enroll biometric authentication
      await ref.read(walletServiceProvider).enableBiometric(pin: pin, safeBoxNumber: _targetSafeNumber);

      // Update state
      state = state.copyWith(isEnrolledForCurrentSafe: true, isLoading: false);

      log.i('Biometric authentication successfully enrolled');
      return BiometricEnrollmentResult.success();
    } catch (e) {
      log.e('Error enrolling biometric: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to enroll biometric: $e');
      return BiometricEnrollmentResult.failure('Failed to set up biometric authentication: $e');
    }
  }

  /// Authenticate using biometric and retrieve PIN (temporary implementation)
  Future<BiometricAuthenticationResult> authenticateWithBiometric() async {
    if (!state.canAuthenticate) {
      return BiometricAuthenticationResult.failure(
        'Biometric authentication is not available or not enrolled',
        BiometricAuthErrorType.notEnrolled,
      );
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // First authenticate with device biometric
      final didAuthenticate = await _authenticateWithDevice(reason: 'useBiometricAuthenticationToUnlockSafe'.tr());

      if (!didAuthenticate) {
        state = state.copyWith(isLoading: false);
        return BiometricAuthenticationResult.failure(
          'Biometric authentication was cancelled or failed',
          BiometricAuthErrorType.authenticationFailed,
        );
      }

      // Use Durt2 to securely authenticate with biometric (target safe if set)
      final result = await ref.read(walletServiceProvider).authenticateWithBiometric(_targetSafeNumber);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        log.i('Biometric authentication successful');
        return BiometricAuthenticationResult.success(result.pin!);
      } else {
        log.w('Biometric authentication failed: ${result.error}');
        return BiometricAuthenticationResult.failure(
          result.error ?? 'Unknown error',
          _mapDurtErrorToLocal(result.errorType),
        );
      }
    } catch (e) {
      log.e('Error during biometric authentication: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Authentication error: $e');
      return BiometricAuthenticationResult.failure('Authentication error: $e', BiometricAuthErrorType.systemError);
    }
  }

  /// Disable biometric authentication for current safe (temporary implementation)
  Future<bool> disableBiometric() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref.read(walletServiceProvider).disableBiometric();

      state = state.copyWith(isEnrolledForCurrentSafe: false, isLoading: false);

      log.i('Biometric authentication disabled');
      return true;
    } catch (e) {
      log.e('Error disabling biometric: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to disable biometric: $e');
      return false;
    }
  }

  /// Internal method to authenticate with device biometric
  Future<bool> _authenticateWithDevice({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(signInTitle: 'connectionAuthTitle'.tr(), cancelButton: 'cancel'.tr()),
          IOSAuthMessages(
            goToSettingsButton: 'goToSettingsButton'.tr(),
            goToSettingsDescription: 'goToSettingsDescription'.tr(),
            cancelButton: 'cancel'.tr(),
            localizedFallbackTitle: 'localizedFallbackTitle'.tr(),
            lockOut: 'lockOut'.tr(),
          ),
        ],
        biometricOnly: true,
        sensitiveTransaction: true,
      );
    } on PlatformException catch (e) {
      log.w('Platform exception during biometric auth: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'no_fragment_activity':
          return false;
        default:
          return false;
      }
    } catch (e) {
      log.e('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// Map Durt2 error types to local error types
  BiometricAuthErrorType _mapDurtErrorToLocal(BiometricAuthError? durtError) {
    switch (durtError) {
      case BiometricAuthError.biometricNotSetup:
      case BiometricAuthError.notEnrolled:
        return BiometricAuthErrorType.notEnrolled;
      case BiometricAuthError.authenticationFailed:
      case BiometricAuthError.userCanceled:
        return BiometricAuthErrorType.authenticationFailed;
      case BiometricAuthError.systemError:
      case BiometricAuthError.notAvailable:
      case BiometricAuthError.invalidData:
      case null:
        return BiometricAuthErrorType.systemError;
    }
  }

  /// Wait for biometric initialization to complete
  Future<void> waitForInitialization() async {
    // Wait until initialization is complete (with timeout to prevent infinite loops)
    final timeout = DateTime.now().add(const Duration(seconds: 5));
    while (!state.isInitialized && DateTime.now().isBefore(timeout)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (!state.isInitialized) {
      log.w('Biometric initialization timeout after 5 seconds');
    }
  }
}

// Result classes for UI

class BiometricEnrollmentResult {
  final bool success;
  final String? errorMessage;

  BiometricEnrollmentResult._({required this.success, this.errorMessage});

  factory BiometricEnrollmentResult.success() => BiometricEnrollmentResult._(success: true);
  factory BiometricEnrollmentResult.failure(String message) =>
      BiometricEnrollmentResult._(success: false, errorMessage: message);
}

class BiometricAuthenticationResult {
  final bool success;
  final String? pin;
  final String? errorMessage;
  final BiometricAuthErrorType? errorType;

  BiometricAuthenticationResult._({required this.success, this.pin, this.errorMessage, this.errorType});

  factory BiometricAuthenticationResult.success(String pin) => BiometricAuthenticationResult._(success: true, pin: pin);

  factory BiometricAuthenticationResult.failure(String message, BiometricAuthErrorType errorType) =>
      BiometricAuthenticationResult._(success: false, errorMessage: message, errorType: errorType);
}

enum BiometricAuthErrorType { notEnrolled, authenticationFailed, systemError }
