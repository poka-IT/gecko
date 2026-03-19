/// Unit tests for PinSecurityService
///
/// PinSecurityService manages PIN brute-force protection:
/// - Tracks failed attempts per safe (stored in Hive configBox)
/// - Applies escalating lockouts starting at the 3rd failed attempt
/// - Triggers safe deletion after 13 consecutive failures
/// - Shows warnings from attempt 10 onwards
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/services/pin_security_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pin_security_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Open a fresh configBox for each test to ensure isolation
    if (Hive.isBoxOpen('configBox')) {
      await Hive.box('configBox').clear();
    } else {
      configBox = await Hive.openBox('configBox');
    }
  });

  tearDown(() async {
    await configBox.clear();
  });

  // ==========================================================================
  // 1. calculateLockoutSeconds - Pure formula, no state
  // ==========================================================================

  group('calculateLockoutSeconds', () {
    test('returns 0 for 0 failed attempts (no lockout)', () {
      expect(PinSecurityService.calculateLockoutSeconds(0), 0);
    });

    test('returns 0 for 1 failed attempt (no lockout)', () {
      expect(PinSecurityService.calculateLockoutSeconds(1), 0);
    });

    test('returns 0 for 2 failed attempts (no lockout)', () {
      expect(PinSecurityService.calculateLockoutSeconds(2), 0);
    });

    test('returns 30s for 3rd failed attempt (first lockout)', () {
      // Formula: baseLockoutSeconds * (attempts - 2) = 30 * (3 - 2) = 30
      expect(PinSecurityService.calculateLockoutSeconds(3), 30);
    });

    test('returns 60s for 4th failed attempt', () {
      expect(PinSecurityService.calculateLockoutSeconds(4), 60);
    });

    test('returns 90s for 5th failed attempt', () {
      expect(PinSecurityService.calculateLockoutSeconds(5), 90);
    });

    test('returns 300s (5min) for 12th failed attempt', () {
      // 30 * (12 - 2) = 300
      expect(PinSecurityService.calculateLockoutSeconds(12), 300);
    });

    test('returns 330s for 13th (max) attempt', () {
      // 30 * (13 - 2) = 330
      expect(PinSecurityService.calculateLockoutSeconds(13), 330);
    });

    test('lockout escalates linearly with each attempt', () {
      for (int i = 3; i <= 13; i++) {
        final expected = PinSecurityService.baseLockoutSeconds * (i - 2);
        expect(
          PinSecurityService.calculateLockoutSeconds(i),
          expected,
          reason: 'Lockout for attempt $i should be ${expected}s',
        );
      }
    });
  });

  // ==========================================================================
  // 2. shouldDeleteSafe - Threshold check
  // ==========================================================================

  group('shouldDeleteSafe', () {
    test('returns false when no attempts recorded', () {
      expect(PinSecurityService.shouldDeleteSafe(0), false);
    });

    test('returns false at 12 attempts (one below max)', () async {
      await configBox.put('pinFailedAttempts_0', 12);
      expect(PinSecurityService.shouldDeleteSafe(0), false);
    });

    test('returns true at exactly 13 attempts (maxAttempts)', () async {
      await configBox.put('pinFailedAttempts_0', 13);
      expect(PinSecurityService.shouldDeleteSafe(0), true);
    });

    test('returns true above 13 attempts', () async {
      await configBox.put('pinFailedAttempts_0', 20);
      expect(PinSecurityService.shouldDeleteSafe(0), true);
    });

    test('checks the correct safe number', () async {
      await configBox.put('pinFailedAttempts_1', 13);
      await configBox.put('pinFailedAttempts_2', 5);
      expect(PinSecurityService.shouldDeleteSafe(1), true);
      expect(PinSecurityService.shouldDeleteSafe(2), false);
    });
  });

  // ==========================================================================
  // 3. shouldShowWarning - Warning threshold
  // ==========================================================================

  group('shouldShowWarning', () {
    test('returns false below warning threshold (9 attempts)', () async {
      await configBox.put('pinFailedAttempts_0', 9);
      expect(PinSecurityService.shouldShowWarning(0), false);
    });

    test('returns true at warning threshold (10 attempts)', () async {
      await configBox.put('pinFailedAttempts_0', 10);
      expect(PinSecurityService.shouldShowWarning(0), true);
    });

    test('returns true at 11 and 12 attempts', () async {
      await configBox.put('pinFailedAttempts_0', 11);
      expect(PinSecurityService.shouldShowWarning(0), true);
      await configBox.put('pinFailedAttempts_0', 12);
      expect(PinSecurityService.shouldShowWarning(0), true);
    });

    test('returns false at maxAttempts (13) - deletion takes over', () async {
      await configBox.put('pinFailedAttempts_0', 13);
      expect(PinSecurityService.shouldShowWarning(0), false);
    });

    test('returns false when no attempts recorded', () {
      expect(PinSecurityService.shouldShowWarning(0), false);
    });
  });

  // ==========================================================================
  // 4. getRemainingAttempts
  // ==========================================================================

  group('getRemainingAttempts', () {
    test('returns maxAttempts (13) when no attempts recorded', () {
      expect(PinSecurityService.getRemainingAttempts(0), 13);
    });

    test('returns correct remaining count after some attempts', () async {
      await configBox.put('pinFailedAttempts_0', 5);
      expect(PinSecurityService.getRemainingAttempts(0), 8);
    });

    test('returns 1 at 12 attempts', () async {
      await configBox.put('pinFailedAttempts_0', 12);
      expect(PinSecurityService.getRemainingAttempts(0), 1);
    });

    test('returns 0 at maxAttempts (13)', () async {
      await configBox.put('pinFailedAttempts_0', 13);
      expect(PinSecurityService.getRemainingAttempts(0), 0);
    });

    test('returns negative when over maxAttempts', () async {
      await configBox.put('pinFailedAttempts_0', 15);
      expect(PinSecurityService.getRemainingAttempts(0), -2);
    });

    test('is isolated per safe number', () async {
      await configBox.put('pinFailedAttempts_0', 3);
      await configBox.put('pinFailedAttempts_1', 7);
      expect(PinSecurityService.getRemainingAttempts(0), 10);
      expect(PinSecurityService.getRemainingAttempts(1), 6);
    });
  });

  // ==========================================================================
  // 5. getFailedAttempts
  // ==========================================================================

  group('getFailedAttempts', () {
    test('returns 0 when no attempts recorded', () {
      expect(PinSecurityService.getFailedAttempts(0), 0);
    });

    test('returns stored value', () async {
      await configBox.put('pinFailedAttempts_0', 7);
      expect(PinSecurityService.getFailedAttempts(0), 7);
    });

    test('is isolated per safe number', () async {
      await configBox.put('pinFailedAttempts_0', 3);
      await configBox.put('pinFailedAttempts_1', 9);
      expect(PinSecurityService.getFailedAttempts(0), 3);
      expect(PinSecurityService.getFailedAttempts(1), 9);
      expect(PinSecurityService.getFailedAttempts(2), 0); // no data for safe 2
    });
  });

  // ==========================================================================
  // 6. getLockoutEndTime
  // ==========================================================================

  group('getLockoutEndTime', () {
    test('returns null when no lockout is set', () {
      expect(PinSecurityService.getLockoutEndTime(0), isNull);
    });

    test('returns correct DateTime from stored timestamp', () async {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      await configBox.put('pinLockoutUntil_0', futureTime.millisecondsSinceEpoch);

      final result = PinSecurityService.getLockoutEndTime(0);
      expect(result, isNotNull);
      // Compare milliseconds to avoid microsecond rounding
      expect(result!.millisecondsSinceEpoch, futureTime.millisecondsSinceEpoch);
    });

    test('returns past DateTime if lockout has expired', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      await configBox.put('pinLockoutUntil_0', pastTime.millisecondsSinceEpoch);

      final result = PinSecurityService.getLockoutEndTime(0);
      expect(result, isNotNull);
      expect(result!.isBefore(DateTime.now()), true);
    });

    test('is isolated per safe number', () async {
      final time1 = DateTime.now().add(const Duration(minutes: 2));
      final time2 = DateTime.now().add(const Duration(minutes: 10));
      await configBox.put('pinLockoutUntil_0', time1.millisecondsSinceEpoch);
      await configBox.put('pinLockoutUntil_1', time2.millisecondsSinceEpoch);

      expect(PinSecurityService.getLockoutEndTime(0)!.millisecondsSinceEpoch, time1.millisecondsSinceEpoch);
      expect(PinSecurityService.getLockoutEndTime(1)!.millisecondsSinceEpoch, time2.millisecondsSinceEpoch);
      expect(PinSecurityService.getLockoutEndTime(2), isNull);
    });
  });

  // ==========================================================================
  // 7. isLockedOut
  // ==========================================================================

  group('isLockedOut', () {
    test('returns false when no lockout is set', () {
      expect(PinSecurityService.isLockedOut(0), false);
    });

    test('returns true when lockout is in the future', () async {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      await configBox.put('pinLockoutUntil_0', futureTime.millisecondsSinceEpoch);
      expect(PinSecurityService.isLockedOut(0), true);
    });

    test('returns false when lockout has expired', () async {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
      await configBox.put('pinLockoutUntil_0', pastTime.millisecondsSinceEpoch);
      expect(PinSecurityService.isLockedOut(0), false);
    });
  });

  // ==========================================================================
  // 8. getRemainingLockoutSeconds
  // ==========================================================================

  group('getRemainingLockoutSeconds', () {
    test('returns 0 when no lockout is set', () {
      expect(PinSecurityService.getRemainingLockoutSeconds(0), 0);
    });

    test('returns positive seconds when lockout is active', () async {
      final futureTime = DateTime.now().add(const Duration(seconds: 120));
      await configBox.put('pinLockoutUntil_0', futureTime.millisecondsSinceEpoch);

      final remaining = PinSecurityService.getRemainingLockoutSeconds(0);
      // Allow 2-second tolerance for test execution time
      expect(remaining, greaterThan(117));
      expect(remaining, lessThanOrEqualTo(120));
    });

    test('returns 0 when lockout has expired', () async {
      final pastTime = DateTime.now().subtract(const Duration(seconds: 30));
      await configBox.put('pinLockoutUntil_0', pastTime.millisecondsSinceEpoch);
      expect(PinSecurityService.getRemainingLockoutSeconds(0), 0);
    });
  });

  // ==========================================================================
  // 9. recordFailedAttempt - State mutation
  // ==========================================================================

  group('recordFailedAttempt', () {
    test('increments counter from 0 to 1 on first attempt', () async {
      expect(PinSecurityService.getFailedAttempts(0), 0);
      await PinSecurityService.recordFailedAttempt(0);
      expect(PinSecurityService.getFailedAttempts(0), 1);
    });

    test('increments counter sequentially', () async {
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(0);
      expect(PinSecurityService.getFailedAttempts(0), 3);
    });

    test('does not set lockout for attempts 1 and 2', () async {
      await PinSecurityService.recordFailedAttempt(0);
      expect(PinSecurityService.getLockoutEndTime(0), isNull);

      await PinSecurityService.recordFailedAttempt(0);
      expect(PinSecurityService.getLockoutEndTime(0), isNull);
    });

    test('sets 30s lockout on 3rd attempt', () async {
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(0);

      final lockoutEnd = PinSecurityService.getLockoutEndTime(0);
      expect(lockoutEnd, isNotNull);

      // Lockout should be ~30s from now
      final secondsFromNow = lockoutEnd!.difference(DateTime.now()).inSeconds;
      expect(secondsFromNow, greaterThan(27)); // allow 3s tolerance
      expect(secondsFromNow, lessThanOrEqualTo(30));
    });

    test('sets 60s lockout on 4th attempt', () async {
      for (int i = 0; i < 4; i++) {
        await PinSecurityService.recordFailedAttempt(0);
      }

      final lockoutEnd = PinSecurityService.getLockoutEndTime(0);
      expect(lockoutEnd, isNotNull);

      final secondsFromNow = lockoutEnd!.difference(DateTime.now()).inSeconds;
      expect(secondsFromNow, greaterThan(57));
      expect(secondsFromNow, lessThanOrEqualTo(60));
    });

    test('lockout escalates correctly through all attempts up to max', () async {
      for (int attempt = 1; attempt <= 13; attempt++) {
        await PinSecurityService.recordFailedAttempt(0);
        expect(PinSecurityService.getFailedAttempts(0), attempt);

        if (attempt < 3) {
          expect(PinSecurityService.getLockoutEndTime(0), isNull, reason: 'No lockout expected at attempt $attempt');
        } else {
          final lockoutEnd = PinSecurityService.getLockoutEndTime(0);
          expect(lockoutEnd, isNotNull, reason: 'Lockout expected at attempt $attempt');

          final expectedSeconds = PinSecurityService.baseLockoutSeconds * (attempt - 2);
          final actualSeconds = lockoutEnd!.difference(DateTime.now()).inSeconds;
          expect(
            actualSeconds,
            greaterThan(expectedSeconds - 3),
            reason: 'Lockout at attempt $attempt should be ~${expectedSeconds}s',
          );
          expect(
            actualSeconds,
            lessThanOrEqualTo(expectedSeconds),
            reason: 'Lockout at attempt $attempt should not exceed ${expectedSeconds}s',
          );
        }
      }
    });

    test('is isolated per safe number', () async {
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(0);
      await PinSecurityService.recordFailedAttempt(1);

      expect(PinSecurityService.getFailedAttempts(0), 2);
      expect(PinSecurityService.getFailedAttempts(1), 1);
    });

    test('triggers shouldDeleteSafe after 13 attempts', () async {
      for (int i = 0; i < 13; i++) {
        await PinSecurityService.recordFailedAttempt(0);
      }
      expect(PinSecurityService.shouldDeleteSafe(0), true);
    });

    test('triggers shouldShowWarning at 10 attempts', () async {
      for (int i = 0; i < 10; i++) {
        await PinSecurityService.recordFailedAttempt(0);
      }
      expect(PinSecurityService.shouldShowWarning(0), true);
      expect(PinSecurityService.shouldDeleteSafe(0), false);
    });
  });

  // ==========================================================================
  // 10. resetFailedAttempts - Clears state on successful unlock
  // ==========================================================================

  group('resetFailedAttempts', () {
    test('clears attempt counter', () async {
      await configBox.put('pinFailedAttempts_0', 5);
      await PinSecurityService.resetFailedAttempts(0);
      expect(PinSecurityService.getFailedAttempts(0), 0);
    });

    test('clears lockout timestamp', () async {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      await configBox.put('pinFailedAttempts_0', 5);
      await configBox.put('pinLockoutUntil_0', futureTime.millisecondsSinceEpoch);

      await PinSecurityService.resetFailedAttempts(0);

      expect(PinSecurityService.getFailedAttempts(0), 0);
      expect(PinSecurityService.getLockoutEndTime(0), isNull);
      expect(PinSecurityService.isLockedOut(0), false);
    });

    test('does not affect other safes', () async {
      await configBox.put('pinFailedAttempts_0', 5);
      await configBox.put('pinFailedAttempts_1', 8);

      await PinSecurityService.resetFailedAttempts(0);

      expect(PinSecurityService.getFailedAttempts(0), 0);
      expect(PinSecurityService.getFailedAttempts(1), 8);
    });

    test('is safe to call when no attempts exist', () async {
      // Should not throw
      await PinSecurityService.resetFailedAttempts(0);
      expect(PinSecurityService.getFailedAttempts(0), 0);
    });
  });

  // ==========================================================================
  // 11. deleteSafeSecurityData
  // ==========================================================================

  group('deleteSafeSecurityData', () {
    test('clears both attempts and lockout for the safe', () async {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      await configBox.put('pinFailedAttempts_0', 10);
      await configBox.put('pinLockoutUntil_0', futureTime.millisecondsSinceEpoch);

      await PinSecurityService.deleteSafeSecurityData(0);

      expect(PinSecurityService.getFailedAttempts(0), 0);
      expect(PinSecurityService.getLockoutEndTime(0), isNull);
    });

    test('does not affect other safes', () async {
      await configBox.put('pinFailedAttempts_0', 10);
      await configBox.put('pinFailedAttempts_1', 7);

      await PinSecurityService.deleteSafeSecurityData(0);

      expect(PinSecurityService.getFailedAttempts(0), 0);
      expect(PinSecurityService.getFailedAttempts(1), 7);
    });
  });

  // ==========================================================================
  // 12. formatLockoutTime - Pure formatting, no state
  // ==========================================================================

  group('formatLockoutTime', () {
    test('returns "0s" for 0 seconds', () {
      expect(PinSecurityService.formatLockoutTime(0), '0s');
    });

    test('returns "0s" for negative seconds', () {
      expect(PinSecurityService.formatLockoutTime(-5), '0s');
    });

    test('returns seconds only when under a minute', () {
      expect(PinSecurityService.formatLockoutTime(1), '1s');
      expect(PinSecurityService.formatLockoutTime(30), '30s');
      expect(PinSecurityService.formatLockoutTime(59), '59s');
    });

    test('returns minutes and seconds for 60+', () {
      expect(PinSecurityService.formatLockoutTime(60), '1m 0s');
      expect(PinSecurityService.formatLockoutTime(90), '1m 30s');
      expect(PinSecurityService.formatLockoutTime(330), '5m 30s');
    });

    test('formats the max lockout duration (330s at attempt 13)', () {
      // 30 * (13 - 2) = 330s = 5m 30s
      final maxLockout = PinSecurityService.calculateLockoutSeconds(PinSecurityService.maxAttempts);
      expect(PinSecurityService.formatLockoutTime(maxLockout), '5m 30s');
    });
  });

  // ==========================================================================
  // 13. Integration: full brute-force scenario
  // ==========================================================================

  group('Full brute-force scenario', () {
    test('simulates 13 failed attempts then reset on success', () async {
      const safeNumber = 0;

      // Phase 1: First 2 attempts - no lockout
      for (int i = 0; i < 2; i++) {
        await PinSecurityService.recordFailedAttempt(safeNumber);
      }
      expect(PinSecurityService.getFailedAttempts(safeNumber), 2);
      expect(PinSecurityService.isLockedOut(safeNumber), false);
      expect(PinSecurityService.shouldShowWarning(safeNumber), false);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), false);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 11);

      // Phase 2: Attempts 3-9 - lockouts but no warning yet
      for (int i = 0; i < 7; i++) {
        await PinSecurityService.recordFailedAttempt(safeNumber);
      }
      expect(PinSecurityService.getFailedAttempts(safeNumber), 9);
      expect(PinSecurityService.isLockedOut(safeNumber), true);
      expect(PinSecurityService.shouldShowWarning(safeNumber), false);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), false);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 4);

      // Phase 3: Attempt 10 - warning appears
      await PinSecurityService.recordFailedAttempt(safeNumber);
      expect(PinSecurityService.getFailedAttempts(safeNumber), 10);
      expect(PinSecurityService.shouldShowWarning(safeNumber), true);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), false);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 3);

      // Phase 4: Attempts 11-12 - still warning
      await PinSecurityService.recordFailedAttempt(safeNumber);
      await PinSecurityService.recordFailedAttempt(safeNumber);
      expect(PinSecurityService.getFailedAttempts(safeNumber), 12);
      expect(PinSecurityService.shouldShowWarning(safeNumber), true);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), false);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 1);

      // Phase 5: Attempt 13 - safe should be deleted
      await PinSecurityService.recordFailedAttempt(safeNumber);
      expect(PinSecurityService.getFailedAttempts(safeNumber), 13);
      expect(PinSecurityService.shouldShowWarning(safeNumber), false);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), true);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 0);

      // Phase 6: Successful login resets everything
      await PinSecurityService.resetFailedAttempts(safeNumber);
      expect(PinSecurityService.getFailedAttempts(safeNumber), 0);
      expect(PinSecurityService.isLockedOut(safeNumber), false);
      expect(PinSecurityService.shouldShowWarning(safeNumber), false);
      expect(PinSecurityService.shouldDeleteSafe(safeNumber), false);
      expect(PinSecurityService.getRemainingAttempts(safeNumber), 13);
    });

    test('multiple safes are fully independent', () async {
      // Fail safe 0 many times
      for (int i = 0; i < 10; i++) {
        await PinSecurityService.recordFailedAttempt(0);
      }

      // Fail safe 1 a few times
      for (int i = 0; i < 3; i++) {
        await PinSecurityService.recordFailedAttempt(1);
      }

      // Verify isolation
      expect(PinSecurityService.getFailedAttempts(0), 10);
      expect(PinSecurityService.getFailedAttempts(1), 3);
      expect(PinSecurityService.shouldShowWarning(0), true);
      expect(PinSecurityService.shouldShowWarning(1), false);

      // Reset safe 0, safe 1 unaffected
      await PinSecurityService.resetFailedAttempts(0);
      expect(PinSecurityService.getFailedAttempts(0), 0);
      expect(PinSecurityService.getFailedAttempts(1), 3);
      expect(PinSecurityService.isLockedOut(1), true);
    });
  });

  // ==========================================================================
  // 14. Constants verification
  // ==========================================================================

  group('Constants', () {
    test('maxAttempts is 13', () {
      expect(PinSecurityService.maxAttempts, 13);
    });

    test('warningThreshold is 10', () {
      expect(PinSecurityService.warningThreshold, 10);
    });

    test('baseLockoutSeconds is 30', () {
      expect(PinSecurityService.baseLockoutSeconds, 30);
    });

    test('warningThreshold is less than maxAttempts', () {
      expect(PinSecurityService.warningThreshold, lessThan(PinSecurityService.maxAttempts));
    });
  });
}
