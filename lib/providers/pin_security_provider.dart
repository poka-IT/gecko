import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/services/pin_security_service.dart';

/// State class for PIN security information
class PinSecurityState {
  final int failedAttempts;
  final bool isLockedOut;
  final int remainingLockoutSeconds;
  final bool shouldShowWarning;
  final int remainingAttempts;
  final bool shouldDeleteSafe;

  const PinSecurityState({
    this.failedAttempts = 0,
    this.isLockedOut = false,
    this.remainingLockoutSeconds = 0,
    this.shouldShowWarning = false,
    this.remainingAttempts = 13,
    this.shouldDeleteSafe = false,
  });

  PinSecurityState copyWith({
    int? failedAttempts,
    bool? isLockedOut,
    int? remainingLockoutSeconds,
    bool? shouldShowWarning,
    int? remainingAttempts,
    bool? shouldDeleteSafe,
  }) {
    return PinSecurityState(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      remainingLockoutSeconds: remainingLockoutSeconds ?? this.remainingLockoutSeconds,
      shouldShowWarning: shouldShowWarning ?? this.shouldShowWarning,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      shouldDeleteSafe: shouldDeleteSafe ?? this.shouldDeleteSafe,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PinSecurityState &&
        other.failedAttempts == failedAttempts &&
        other.isLockedOut == isLockedOut &&
        other.remainingLockoutSeconds == remainingLockoutSeconds &&
        other.shouldShowWarning == shouldShowWarning &&
        other.remainingAttempts == remainingAttempts &&
        other.shouldDeleteSafe == shouldDeleteSafe;
  }

  @override
  int get hashCode {
    return Object.hash(
      failedAttempts,
      isLockedOut,
      remainingLockoutSeconds,
      shouldShowWarning,
      remainingAttempts,
      shouldDeleteSafe,
    );
  }
}

/// Notifier for managing PIN security state
class PinSecurityNotifier extends StateNotifier<PinSecurityState> {
  PinSecurityNotifier() : super(const PinSecurityState());

  Timer? _countdownTimer;
  int? _currentSafeNumber;

  /// Update security state for a specific safe
  void updateForSafe(int safeNumber) {
    _currentSafeNumber = safeNumber;
    _updateState();
    _startCountdownIfNeeded();
  }

  /// Record a failed PIN attempt
  Future<void> recordFailedAttempt(int safeNumber) async {
    await PinSecurityService.recordFailedAttempt(safeNumber);
    if (_currentSafeNumber == safeNumber) {
      _updateState();
      _startCountdownIfNeeded();
    }
  }

  /// Reset failed attempts (called on successful unlock)
  Future<void> resetFailedAttempts(int safeNumber) async {
    await PinSecurityService.resetFailedAttempts(safeNumber);
    if (_currentSafeNumber == safeNumber) {
      _updateState();
      _stopCountdown();
    }
  }

  /// Delete safe security data
  Future<void> deleteSafeSecurityData(int safeNumber) async {
    await PinSecurityService.deleteSafeSecurityData(safeNumber);
    if (_currentSafeNumber == safeNumber) {
      _updateState();
      _stopCountdown();
    }
  }

  /// Update the current state based on service data
  void _updateState() {
    if (_currentSafeNumber == null) return;

    final safeNumber = _currentSafeNumber!;
    final failedAttempts = PinSecurityService.getFailedAttempts(safeNumber);
    final isLockedOut = PinSecurityService.isLockedOut(safeNumber);
    final remainingLockoutSeconds = PinSecurityService.getRemainingLockoutSeconds(safeNumber);
    final shouldShowWarning = PinSecurityService.shouldShowWarning(safeNumber);
    final remainingAttempts = PinSecurityService.getRemainingAttempts(safeNumber);
    final shouldDeleteSafe = PinSecurityService.shouldDeleteSafe(safeNumber);

    state = PinSecurityState(
      failedAttempts: failedAttempts,
      isLockedOut: isLockedOut,
      remainingLockoutSeconds: remainingLockoutSeconds,
      shouldShowWarning: shouldShowWarning,
      remainingAttempts: remainingAttempts,
      shouldDeleteSafe: shouldDeleteSafe,
    );
  }

  /// Start countdown timer if locked out
  void _startCountdownIfNeeded() {
    _stopCountdown(); // Stop any existing timer

    if (state.isLockedOut && state.remainingLockoutSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentSafeNumber == null) {
          _stopCountdown();
          return;
        }

        final remainingSeconds = PinSecurityService.getRemainingLockoutSeconds(_currentSafeNumber!);

        if (remainingSeconds <= 0) {
          _stopCountdown();
          _updateState(); // Update to reflect lockout ended
          // Force a complete state refresh to ensure UI updates
          final newState = state.copyWith(isLockedOut: false, remainingLockoutSeconds: 0);
          state = newState;
        } else {
          state = state.copyWith(remainingLockoutSeconds: remainingSeconds, isLockedOut: true);
        }
      });
    }
  }

  /// Stop the countdown timer
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void dispose() {
    _stopCountdown();
    super.dispose();
  }
}

/// Provider for PIN security state management
final pinSecurityProvider = StateNotifierProvider<PinSecurityNotifier, PinSecurityState>((ref) {
  return PinSecurityNotifier();
});
