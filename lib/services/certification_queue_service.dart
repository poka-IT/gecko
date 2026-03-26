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

  /// Update all expected dates in a queue based on current blockchain state
  static d.CertificationQueueState updateExpectedDates({
    required d.CertificationQueueState queue,
    required int certPeriodBlocks,
    required int currentBlockNumber,
    required int? nextIssuableBlock,
    int blockTimeSeconds = 6,
  }) {
    if (queue.pendingCertifications.isEmpty) return queue;

    final updatedCertifications = <d.PendingCertification>[];

    for (var i = 0; i < queue.pendingCertifications.length; i++) {
      final cert = queue.pendingCertifications[i];
      final position = i + 1;

      // Calculate position-based block
      var expectedBlock = (nextIssuableBlock ?? currentBlockNumber) + ((position - 1) * certPeriodBlocks);

      // Enforce cert-specific minimum constraint (e.g. canRenewIn)
      if (cert.minAvailableBlock != null && cert.minAvailableBlock! > expectedBlock) {
        expectedBlock = cert.minAvailableBlock!;
      }

      final expectedDate = _blockToDate(
        targetBlock: expectedBlock,
        currentBlockNumber: currentBlockNumber,
        blockTimeSeconds: blockTimeSeconds,
      );

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

  /// Convert a target block number to a DateTime relative to now.
  static DateTime _blockToDate({
    required int targetBlock,
    required int currentBlockNumber,
    required int blockTimeSeconds,
  }) {
    final blocksUntil = targetBlock - currentBlockNumber;
    if (blocksUntil <= 0) return DateTime.now();
    return DateTime.now().add(Duration(seconds: blocksUntil * blockTimeSeconds));
  }
}
