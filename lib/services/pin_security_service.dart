import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/services/config_service.dart';

/// Service to manage PIN security, tracking failed attempts and enforcing lockouts
class PinSecurityService {
  /// Maximum attempts before safe deletion
  static const int maxAttempts = 13;

  /// Attempts before showing warning (10, 11, 12 show warnings)
  static const int warningThreshold = 10;

  /// Base lockout duration in seconds (30 seconds for first lockout)
  static const int baseLockoutSeconds = 30;

  static ConfigService get _config => ConfigService(configBox);

  /// Get the current number of failed attempts for a specific safe
  static int getFailedAttempts(int safeNumber) {
    return _config.getFailedAttempts(safeNumber);
  }

  /// Check if the safe is currently locked out
  static bool isLockedOut(int safeNumber) {
    final lockoutUntil = getLockoutEndTime(safeNumber);
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }

  /// Get the time when lockout expires, null if not locked
  static DateTime? getLockoutEndTime(int safeNumber) {
    final timestamp = _config.getLockoutUntil(safeNumber);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Get remaining lockout time in seconds
  static int getRemainingLockoutSeconds(int safeNumber) {
    final lockoutUntil = getLockoutEndTime(safeNumber);
    if (lockoutUntil == null) return 0;
    final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Calculate lockout duration based on failed attempts
  static int calculateLockoutSeconds(int failedAttempts) {
    if (failedAttempts < 3) return 0; // No lockout for first 2 attempts

    // Starting from 3rd attempt: 30s, 60s, 90s, 120s, etc.
    return baseLockoutSeconds * (failedAttempts - 2);
  }

  /// Record a failed PIN attempt and apply lockout if necessary
  static Future<void> recordFailedAttempt(int safeNumber) async {
    final currentAttempts = getFailedAttempts(safeNumber);
    final newAttempts = currentAttempts + 1;

    // Store the updated attempt count
    await _config.setFailedAttempts(safeNumber, newAttempts);

    // Apply lockout if this is the 3rd or subsequent failed attempt
    if (newAttempts >= 3) {
      final lockoutSeconds = calculateLockoutSeconds(newAttempts);
      final lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
      await _config.setLockoutUntil(safeNumber, lockoutUntil.millisecondsSinceEpoch);
    }

    log.w('PIN failed attempt recorded for safe $safeNumber: $newAttempts attempts');
  }

  /// Reset failed attempts for a safe (called on successful unlock)
  static Future<void> resetFailedAttempts(int safeNumber) async {
    await _config.deleteFailedAttempts(safeNumber);
    await _config.deleteLockoutUntil(safeNumber);

    log.i('PIN failed attempts reset for safe $safeNumber');
  }

  /// Check if safe should be deleted due to too many failed attempts
  static bool shouldDeleteSafe(int safeNumber) {
    return getFailedAttempts(safeNumber) >= maxAttempts;
  }

  /// Check if we should show warning about impending safe deletion
  static bool shouldShowWarning(int safeNumber) {
    final attempts = getFailedAttempts(safeNumber);
    return attempts >= warningThreshold && attempts < maxAttempts;
  }

  /// Get the number of remaining attempts before safe deletion
  static int getRemainingAttempts(int safeNumber) {
    final attempts = getFailedAttempts(safeNumber);
    return maxAttempts - attempts;
  }

  /// Delete all security data for a specific safe
  static Future<void> deleteSafeSecurityData(int safeNumber) async {
    await _config.deleteFailedAttempts(safeNumber);
    await _config.deleteLockoutUntil(safeNumber);

    log.i('Security data deleted for safe $safeNumber');
  }

  /// Format lockout time remaining as human-readable string
  static String formatLockoutTime(int remainingSeconds) {
    if (remainingSeconds <= 0) return '0s';

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
