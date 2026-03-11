import 'dart:convert';
import 'package:durt2/durt2.dart' as d;
import 'package:gecko/globals.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for local storage of certification queues using Hive
class CertificationQueueService {
  static const String _boxName = 'certification_queues';
  static Box<String>? _box;

  /// Initialize the service
  static Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<String>(_boxName);
    }
  }

  /// Get the box, initializing if necessary
  static Future<Box<String>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Load the certification queue for an issuer from local storage
  static Future<d.CertificationQueueState?> loadQueue(String issuerAddress) async {
    final box = await _getBox();
    final jsonString = box.get(issuerAddress);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return d.CertificationQueueState.fromJson(json);
    } catch (e) {
      log.e('[CertQueueService] Error parsing queue for $issuerAddress: $e');
      return null;
    }
  }

  /// Save a certification queue to local storage
  static Future<void> saveQueue(d.CertificationQueueState queue) async {
    final box = await _getBox();
    final jsonString = jsonEncode(queue.toJson());
    await box.put(queue.issuerAddress, jsonString);
  }

  /// Delete a certification queue from local storage
  static Future<void> deleteQueue(String issuerAddress) async {
    final box = await _getBox();
    await box.delete(issuerAddress);
  }

  /// Delete all certification queues for a list of issuer addresses
  static Future<void> deleteQueuesForAddresses(List<String> addresses) async {
    final box = await _getBox();
    for (final address in addresses) {
      await box.delete(address);
    }
  }

  /// Clear ALL local queues (use with caution)
  static Future<void> clearAllQueues() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Get all issuer addresses that have queues
  static Future<List<String>> getAllIssuerAddresses() async {
    final box = await _getBox();
    return box.keys.cast<String>().toList();
  }

  /// Calculate the expected date for a certification at a given position in the queue
  ///
  /// [position] - 1-based position in the queue
  /// [certPeriodBlocks] - Number of blocks between certifications
  /// [currentBlockNumber] - Current block number
  /// [nextIssuableBlock] - Block when the issuer can next certify (null if can certify now)
  static DateTime calculateExpectedDate({
    required int position,
    required int certPeriodBlocks,
    required int currentBlockNumber,
    required int? nextIssuableBlock,
  }) {
    const blockTimeSeconds = 6;

    // Start from when the issuer can next certify
    // If nextIssuableBlock is in the past, use current block as base
    // (the first cert will execute "now", so subsequent ones wait from now)
    int baseBlock = nextIssuableBlock ?? currentBlockNumber;
    if (baseBlock < currentBlockNumber) {
      baseBlock = currentBlockNumber;
    }

    // Add (position - 1) certification periods for queue position
    // Position 1 = ready at nextIssuableBlock
    // Position 2 = ready at nextIssuableBlock + certPeriodBlocks
    // etc.
    final targetBlock = baseBlock + ((position - 1) * certPeriodBlocks);

    // Calculate how many blocks until the target block
    final blocksUntilTarget = targetBlock - currentBlockNumber;

    // If target block is in the past or now, return current time
    if (blocksUntilTarget <= 0) {
      return DateTime.now();
    }

    // Convert blocks to seconds and add to current time
    final secondsUntilTarget = blocksUntilTarget * blockTimeSeconds;
    return DateTime.now().add(Duration(seconds: secondsUntilTarget));
  }

  /// Update all expected dates in a queue based on current blockchain state
  static d.CertificationQueueState updateExpectedDates({
    required d.CertificationQueueState queue,
    required int certPeriodBlocks,
    required int currentBlockNumber,
    required int? nextIssuableBlock,
  }) {
    if (queue.pendingCertifications.isEmpty) return queue;

    final updatedCertifications = <d.PendingCertification>[];

    for (var i = 0; i < queue.pendingCertifications.length; i++) {
      final cert = queue.pendingCertifications[i];
      final position = i + 1;

      final expectedDate = calculateExpectedDate(
        position: position,
        certPeriodBlocks: certPeriodBlocks,
        currentBlockNumber: currentBlockNumber,
        nextIssuableBlock: nextIssuableBlock,
      );

      // Calculate expected block
      final expectedBlock = (nextIssuableBlock ?? currentBlockNumber) + ((position - 1) * certPeriodBlocks);

      updatedCertifications.add(
        cert.copyWith(position: position, expectedAvailableDate: expectedDate, expectedAvailableBlock: expectedBlock),
      );
    }

    return queue.copyWith(
      pendingCertifications: updatedCertifications,
      nextIssuableOn: nextIssuableBlock,
      // Do NOT update lastUpdated here - this is an internal recalculation,
      // not a user action. Updating lastUpdated would make local always appear
      // newer than remote, breaking CesiumPlus sync.
    );
  }
}
