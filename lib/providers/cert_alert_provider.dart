import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/widgets/certs_list.dart';

/// Alert status for certification expiration indicators.
enum CertAlertStatus {
  /// No alert -- all certifications are healthy (>30 days until expiration).
  none,

  /// At least one certification expires within 30 days.
  expiringSoon,

  /// At least one certification has already expired.
  expired,
}

/// Computes worst-case cert alert status for an address.
///
/// Iterates the certification list for [address] in the given [direction] and
/// returns the most severe status found:
/// - [CertAlertStatus.expired] if any cert has passed its expiration date
/// - [CertAlertStatus.expiringSoon] if any cert expires within 30 days
/// - [CertAlertStatus.none] otherwise
///
/// For home wallet tiles: use [CertDirection.received].
/// For contact entries: use [CertDirection.sent].
final certAlertStatusProvider = Provider.family<CertAlertStatus, ({String address, CertDirection direction})>((ref, params) {
  final certState = ref.watch(certificationListProvider((address: params.address, direction: params.direction)));

  if (certState.isLoading || certState.certifications.isEmpty) {
    return CertAlertStatus.none;
  }

  final now = DateTime.now();
  bool hasExpiringSoon = false;

  for (final cert in certState.certifications) {
    if (cert.expireDate == null) continue;

    if (now.isAfter(cert.expireDate!)) {
      // Worst status reached -- short-circuit immediately
      return CertAlertStatus.expired;
    }

    if (cert.expireDate!.difference(now).inDays <= 30) {
      hasExpiringSoon = true;
    }
  }

  return hasExpiringSoon ? CertAlertStatus.expiringSoon : CertAlertStatus.none;
});

/// Checks if the current user has any sent cert to [contactAddress] that is
/// expired or expiring soon, across all owned wallets.
///
/// Iterates every wallet in the current safe and inspects their sent
/// certifications for the given contact. Returns the worst status found.
final contactCertAlertProvider = Provider.family<CertAlertStatus, String>((ref, contactAddress) {
  final walletsState = ref.watch(walletsListProvider);

  if (walletsState.isLoading || walletsState.wallets.isEmpty) {
    return CertAlertStatus.none;
  }

  final now = DateTime.now();
  bool hasExpiringSoon = false;

  for (final wallet in walletsState.wallets) {
    final certState = ref.watch(
      certificationListProvider((address: wallet.address, direction: CertDirection.sent)),
    );

    if (certState.isLoading || certState.certifications.isEmpty) continue;

    for (final cert in certState.certifications) {
      if (cert.address != contactAddress) continue;
      if (cert.expireDate == null) continue;

      if (now.isAfter(cert.expireDate!)) {
        // Worst status reached -- short-circuit immediately
        return CertAlertStatus.expired;
      }

      if (cert.expireDate!.difference(now).inDays <= 30) {
        hasExpiringSoon = true;
      }
    }
  }

  return hasExpiringSoon ? CertAlertStatus.expiringSoon : CertAlertStatus.none;
});
