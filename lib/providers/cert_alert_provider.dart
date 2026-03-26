import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certs_list.dart';

/// Detailed cert alert info for a specific wallet+direction.
/// Used by CertAlertBanner to show person name and days left.
class CertAlertDetail {
  final CertAlertStatus status;
  final String? contactName;
  final String? contactAddress;
  final int? daysLeft;

  const CertAlertDetail({this.status = CertAlertStatus.none, this.contactName, this.contactAddress, this.daysLeft});
}

/// Returns the most urgent expiring cert for a wallet, with contact name and days.
/// Single source of truth for cert alert scanning — used by the banner,
/// home alert, status dot (via [certAlertStatusProvider]), and contact alert.
final certAlertDetailProvider = Provider.family<CertAlertDetail, ({String address, CertDirection direction})>((
  ref,
  params,
) {
  final certState = ref.watch(certificationListProvider((address: params.address, direction: params.direction)));

  if (certState.isLoading || certState.certifications.isEmpty) {
    return const CertAlertDetail();
  }

  final now = DateTime.now();
  CertDisplayItem? worstCert;
  bool isExpired = false;
  bool isExpiringSoon = false;

  for (final cert in certState.certifications) {
    if (cert.expireDate == null) continue;

    if (now.isAfter(cert.expireDate!)) {
      worstCert = cert;
      isExpired = true;
      break;
    }

    final threshold = params.direction == CertDirection.sent ? 60 : 30;
    if (cert.expireDate!.difference(now).inDays <= threshold) {
      if (worstCert == null || cert.expireDate!.isBefore(worstCert.expireDate!)) {
        worstCert = cert;
        isExpiringSoon = true;
      }
    }
  }

  if (worstCert == null) return const CertAlertDetail();

  final name = worstCert.name.isNotEmpty ? worstCert.name : getShortPubkey(worstCert.address);
  final daysLeft = worstCert.expireDate!.difference(now).inDays;

  return CertAlertDetail(
    status: isExpired
        ? CertAlertStatus.expired
        : (isExpiringSoon ? CertAlertStatus.expiringSoon : CertAlertStatus.none),
    contactName: name,
    contactAddress: worstCert.address,
    daysLeft: daysLeft,
  );
});

/// Alert status for certification expiration indicators.
enum CertAlertStatus {
  /// No alert -- all certifications are healthy (>30 days until expiration).
  none,

  /// At least one certification expires within 30 days.
  expiringSoon,

  /// At least one certification has already expired.
  expired,
}

/// Simple status-only view of [certAlertDetailProvider].
/// Used by [CertAlertDot] and anywhere only the enum is needed.
final certAlertStatusProvider = Provider.family<CertAlertStatus, ({String address, CertDirection direction})>((
  ref,
  params,
) {
  return ref.watch(certAlertDetailProvider(params)).status;
});

/// Checks if the current user has any sent cert to [contactAddress] that is
/// expired or expiring soon, across all owned wallets.
///
/// Returns the worst status found across all wallets in the current safe.
final contactCertAlertProvider = Provider.family<CertAlertStatus, String>((ref, contactAddress) {
  final walletsState = ref.watch(walletsListProvider);

  if (walletsState.isLoading || walletsState.wallets.isEmpty) {
    return CertAlertStatus.none;
  }

  CertAlertStatus worst = CertAlertStatus.none;

  for (final wallet in walletsState.wallets) {
    final detail = ref.watch(certAlertDetailProvider((address: wallet.address, direction: CertDirection.sent)));

    // Only consider the cert targeting this specific contact
    if (detail.status == CertAlertStatus.none) continue;
    if (detail.contactAddress != contactAddress) continue;

    if (detail.status == CertAlertStatus.expired) return CertAlertStatus.expired;
    worst = CertAlertStatus.expiringSoon;
  }

  return worst;
});
