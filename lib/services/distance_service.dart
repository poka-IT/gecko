import 'dart:math';

import 'package:durt2/durt2.dart';

/// Result of distance and quality computation for an identity.
class DistanceResult {
  final double distanceRatio;
  final double qualityRatio;
  final int distanceAccessible;
  final int distanceTotal;
  final int qualityAccessible;
  final int qualityTotal;
  final double xPercent;

  const DistanceResult({
    required this.distanceRatio,
    required this.qualityRatio,
    required this.distanceAccessible,
    required this.distanceTotal,
    required this.qualityAccessible,
    required this.qualityTotal,
    required this.xPercent,
  });
}

/// WoT graph data shared between distance and quality computations.
class WotData {
  final Map<int, List<int>> receivedCerts;
  final Set<int> referees;
  final int membersCount;

  const WotData({required this.receivedCerts, required this.referees, required this.membersCount});
}

/// Stateless service for computing WoT distance and quality metrics.
/// Ported from cesium2s distance.service.ts + distance-computation.service.ts.
class DistanceService {
  /// Fetches the full WoT graph data from the blockchain.
  /// [onProgress] emits progress from 0.0 to 1.0.
  static Future<WotData> fetchWotData({required void Function(double progress) onProgress}) async {
    final blockchain = Durt.i.blockchain;

    // --- Phase 1 (0-15%): Fetch identities and memberships ---
    onProgress(0.0);

    final nextIndex = await blockchain.query.identity.nextIdtyIndex();
    final allIdentityIndexes = <int>{};
    final memberIdties = <int>{};

    const batchSize = 100;

    for (var i = 0; i < nextIndex; i += batchSize) {
      final batchEnd = (i + batchSize > nextIndex) ? nextIndex : i + batchSize;
      final batch = List.generate(batchEnd - i, (j) => i + j);

      // Separate calls to avoid Future.wait type erasure
      final memberships = await blockchain.query.membership.multiMembership(batch);
      final identities = await blockchain.query.identity.multiIdentities(batch);

      for (var j = 0; j < batch.length; j++) {
        if (identities[j] != null) {
          allIdentityIndexes.add(batch[j]);
        }
        if (memberships[j] != null) {
          memberIdties.add(batch[j]);
        }
      }

      onProgress(0.15 * (batchEnd / nextIndex));
    }

    onProgress(0.15);

    // Compute minCertsForReferee
    final membersCount = await blockchain.query.membership.counterForMembership();
    final maxDepth = blockchain.constant.distance.maxRefereeDistance;
    final minCertsForReferee = (pow(membersCount, 1 / maxDepth)).ceil();

    // --- Phase 2 (15-95%): Fetch certifications ---
    final receivedCerts = <int, List<int>>{};
    final certsByIssuer = <int, List<int>>{};
    final idtyList = allIdentityIndexes.toList();

    for (var i = 0; i < idtyList.length; i += batchSize) {
      final batchEnd = (i + batchSize > idtyList.length) ? idtyList.length : i + batchSize;
      final batch = idtyList.sublist(i, batchEnd);

      // Use dynamic to work around durt2 reified generic type cast issue
      // (empty inner lists are List<dynamic> at runtime, not List<Tuple2<int, int>>)
      final dynamic certsBatchDynamic = await blockchain.query.certification.multiCertsByReceiver(batch);

      for (var j = 0; j < batch.length; j++) {
        final idtyIndex = batch[j];
        final List<dynamic> certs = certsBatchDynamic[j] as List<dynamic>;
        final issuers = <int>[];
        for (final cert in certs) {
          issuers.add((cert as dynamic).value0 as int);
        }
        receivedCerts[idtyIndex] = issuers;

        for (final issuer in issuers) {
          certsByIssuer.putIfAbsent(issuer, () => []).add(idtyIndex);
        }
      }

      onProgress(0.15 + 0.80 * (batchEnd / idtyList.length));
    }

    onProgress(0.95);

    // Identify referees: members with >= minCertsForReferee received AND issued
    final referees = <int>{};
    for (final idtyIndex in memberIdties) {
      final received = receivedCerts[idtyIndex]?.length ?? 0;
      final issued = certsByIssuer[idtyIndex]?.length ?? 0;
      if (received >= minCertsForReferee && issued >= minCertsForReferee) {
        referees.add(idtyIndex);
      }
    }

    onProgress(1.0);

    return WotData(receivedCerts: receivedCerts, referees: referees, membersCount: membersCount);
  }

  /// Computes the distance metric: ratio of accessible referees via DFS.
  /// [depth] is the max traversal depth (5 for distance, 4 for quality).
  static double computeDistance({
    required Map<int, List<int>> receivedCerts,
    required Set<int> referees,
    required int depth,
    required int accountIndex,
  }) {
    final accessibleReferees = <int>{};
    final knownIdties = <int, int>{};

    _distanceRuleRecursive(
      receivedCerts: receivedCerts,
      referees: referees,
      idty: accountIndex,
      accessibleReferees: accessibleReferees,
      knownIdties: knownIdties,
      depth: depth,
    );

    final refereesCount = referees.length;
    if (refereesCount == 0) return 0.0;

    // If the identity is itself a referee, exclude it from the count
    if (referees.contains(accountIndex)) {
      final accessibleCount = accessibleReferees.length - 1;
      final totalCount = refereesCount - 1;
      if (totalCount == 0) return 0.0;
      return accessibleCount / totalCount;
    } else {
      return accessibleReferees.length / refereesCount;
    }
  }

  /// Recursive DFS through the certification graph.
  static void _distanceRuleRecursive({
    required Map<int, List<int>> receivedCerts,
    required Set<int> referees,
    required int idty,
    required Set<int> accessibleReferees,
    required Map<int, int> knownIdties,
    required int depth,
  }) {
    // Don't re-explore identities already explored at equal or greater depth
    final knownDepth = knownIdties[idty];
    if (knownDepth != null && knownDepth >= depth) {
      return;
    }
    knownIdties[idty] = depth;

    // If this is a referee, add it
    if (referees.contains(idty)) {
      accessibleReferees.add(idty);
    }

    // Stop at max depth
    if (depth == 0) return;

    // Explore certifiers
    final certifiers = receivedCerts[idty] ?? [];
    for (final certifier in certifiers) {
      _distanceRuleRecursive(
        receivedCerts: receivedCerts,
        referees: referees,
        idty: certifier,
        accessibleReferees: accessibleReferees,
        knownIdties: knownIdties,
        depth: depth - 1,
      );
    }
  }

  /// Computes both distance (5 steps) and quality (4 steps) for an identity.
  /// Returns detailed results including accessible/total referee counts.
  static Future<DistanceResult> computeDistanceAndQuality({
    required int accountIndex,
    required void Function(double progress) onProgress,
  }) async {
    final maxDepth = Durt.i.blockchain.constant.distance.maxRefereeDistance;
    final minAccessibleRefereesPerbill = Durt.i.blockchain.constant.distance.minAccessibleReferees;
    final xPercent = minAccessibleRefereesPerbill / 1000000000;

    // Fetch WoT data (0% to 95%)
    final wotData = await fetchWotData(onProgress: (p) => onProgress(p * 0.95));

    onProgress(0.95);

    // Compute distance (depth = maxDepth, typically 5)
    final distanceRatio = computeDistance(
      receivedCerts: wotData.receivedCerts,
      referees: wotData.referees,
      depth: maxDepth,
      accountIndex: accountIndex,
    );

    onProgress(0.97);

    // Compute quality (depth = maxDepth - 1, typically 4)
    final qualityRatio = computeDistance(
      receivedCerts: wotData.receivedCerts,
      referees: wotData.referees,
      depth: maxDepth - 1,
      accountIndex: accountIndex,
    );

    onProgress(1.0);

    // Compute accessible counts for display
    final totalReferees = wotData.referees.length;
    final isSelfReferee = wotData.referees.contains(accountIndex);
    final effectiveTotal = isSelfReferee ? totalReferees - 1 : totalReferees;

    return DistanceResult(
      distanceRatio: distanceRatio,
      qualityRatio: qualityRatio,
      distanceAccessible: (distanceRatio * effectiveTotal).round(),
      distanceTotal: effectiveTotal,
      qualityAccessible: (qualityRatio * effectiveTotal).round(),
      qualityTotal: effectiveTotal,
      xPercent: xPercent,
    );
  }
}
