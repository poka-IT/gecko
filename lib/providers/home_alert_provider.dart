import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certs_list.dart';

/// Priority levels for home alerts, highest to lowest.
///
/// Only the highest-priority alert is displayed. Connection messages
/// (handled separately by [ConnectionStatusNotifier]) take absolute
/// precedence and are NOT part of this enum.
enum HomeAlertPriority {
  /// Identity has expired.
  identityExpired(100),

  /// Membership has expired.
  membershipExpired(90),

  /// A membership renewal is pending evaluation.
  membershipPendingEval(80),

  /// Membership expires soon.
  membershipExpiringSoon(70),

  /// A certification we SENT has expired — we can re-certify.
  sentCertExpired(65),

  /// A certification we SENT expires soon — we can re-certify.
  sentCertExpiringSoon(55),

  /// A certification we RECEIVED has expired.
  receivedCertExpired(50),

  /// A certification we RECEIVED expires soon.
  receivedCertExpiringSoon(40),

  /// Everything is healthy.
  none(0);

  const HomeAlertPriority(this.value);
  final int value;
}

/// What action to perform when the user taps the alert message.
enum HomeAlertAction {
  /// Navigate to wallet options (membership renewal).
  walletOptions,

  /// Navigate to a contact's profile (to re-certify them).
  openProfile,

  /// Navigate to our cert list (informational, received cert expiring).
  openCertList,

  /// No action.
  nothing,
}

/// Immutable snapshot of the highest-priority home alert.
class HomeAlertState {
  /// The priority level of the alert.
  final HomeAlertPriority priority;

  /// The formatted, user-facing message (with emoji prefix).
  final String message;

  /// Address of the wallet that triggered the alert.
  final String? walletAddress;

  /// Address of the target contact (for profile navigation).
  final String? targetAddress;

  /// Name of the target contact (for profile navigation).
  final String? targetName;

  /// What to do when the message is tapped.
  final HomeAlertAction action;

  const HomeAlertState({
    this.priority = HomeAlertPriority.none,
    this.message = '',
    this.walletAddress,
    this.targetAddress,
    this.targetName,
    this.action = HomeAlertAction.nothing,
  });

  bool get hasAlert => priority != HomeAlertPriority.none;
}

/// Aggregates alerts from all owned wallets and returns the single
/// highest-priority alert.
///
/// Watches only sources that are already loaded or throttled:
/// - [walletsListProvider] — cached, always available
/// - [membershipStatusProvider] — throttled (≤1 fetch per 10 blocks)
/// - [smartIdtyStatusStreamProvider] — persistent stream for owned wallets
/// - [certificationListProvider] — already subscribed for cert tiles/alerts
///
/// Scans both RECEIVED and SENT certifications to find the specific
/// person and expiration date for the alert message.
class HomeAlertNotifier extends Notifier<HomeAlertState> {
  @override
  HomeAlertState build() {
    final walletsState = ref.watch(walletsListProvider);

    if (walletsState.isLoading || walletsState.wallets.isEmpty) {
      return const HomeAlertState();
    }

    HomeAlertState best = const HomeAlertState();

    for (final wallet in walletsState.wallets) {
      final alert = _checkWallet(wallet.address);
      if (alert.priority.value > best.priority.value) {
        best = alert;
      }
      if (best.priority == HomeAlertPriority.identityExpired) break;
    }

    return best;
  }

  /// Checks all alert conditions for a single wallet.
  HomeAlertState _checkWallet(String address) {
    // --- Identity & Membership alerts ---
    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));
    final idtyStatus = idtyStatusAsync.asData?.value;

    if (idtyStatus == d.IdtyStatus.expired) {
      return HomeAlertState(
        priority: HomeAlertPriority.identityExpired,
        message: '⛔ ${'homeAlertIdentityExpired'.tr()}',
        walletAddress: address,
        action: HomeAlertAction.walletOptions,
      );
    }

    if (idtyStatus != null && idtyStatus != d.IdtyStatus.none) {
      final membershipAsync = ref.watch(membershipStatusProvider(address));
      final membership = membershipAsync.asData?.value;

      if (membership != null) {
        final alert = _checkMembership(address, membership);
        if (alert != null) return alert;
      }
    }

    // --- Sent cert alerts (actionable: we can re-certify) ---
    final sentAlert = _findExpiringCert(address, CertDirection.sent);
    if (sentAlert != null) return sentAlert;

    // --- Received cert alerts (informational) ---
    final receivedAlert = _findExpiringCert(address, CertDirection.received);
    if (receivedAlert != null) return receivedAlert;

    return const HomeAlertState();
  }

  /// Checks membership status and returns an alert if needed.
  HomeAlertState? _checkMembership(String address, d.MembershipStatus membership) {
    final info = MembershipRenewal.calculateRenewalInfo(membership);

    if (info.isExpired) {
      final autoRevocText = info.autoRevocationDate != null
          ? ' (${'homeAlertAutoRevocation'.tr(args: [DateFormat('dd/MM').format(info.autoRevocationDate!)])})'
          : '';
      return HomeAlertState(
        priority: HomeAlertPriority.membershipExpired,
        message: '🔴 ${'homeAlertMembershipExpired'.tr()}$autoRevocText',
        walletAddress: address,
        action: HomeAlertAction.walletOptions,
      );
    }

    if (info.hasPendingRenewal) {
      return HomeAlertState(
        priority: HomeAlertPriority.membershipPendingEval,
        message: '⏳ ${'homeAlertMembershipPendingEval'.tr()}',
        walletAddress: address,
        action: HomeAlertAction.walletOptions,
      );
    }

    if (_shouldShowMembershipAlert(info)) {
      final daysLeft = info.expireDate != null ? info.expireDate!.difference(DateTime.now()).inDays : 0;
      return HomeAlertState(
        priority: HomeAlertPriority.membershipExpiringSoon,
        message: '⚠️ ${'homeAlertMembershipExpiringSoon'.tr(args: ['$daysLeft'])}',
        walletAddress: address,
        action: HomeAlertAction.walletOptions,
      );
    }

    return null;
  }

  /// Finds the first expiring/expired cert in [direction] for [walletAddress]
  /// and builds a specific alert message with the contact's name.
  HomeAlertState? _findExpiringCert(String walletAddress, CertDirection direction) {
    final certState = ref.watch(certificationListProvider((address: walletAddress, direction: direction)));

    if (certState.isLoading || certState.certifications.isEmpty) return null;

    final now = DateTime.now();
    CertDisplayItem? worstCert;
    bool isExpired = false;
    bool isExpiringSoon = false;

    for (final cert in certState.certifications) {
      if (cert.expireDate == null) continue;

      if (now.isAfter(cert.expireDate!)) {
        // Expired — highest severity for this direction
        worstCert = cert;
        isExpired = true;
        break; // Can't get worse
      }

      // Sent certs: 60-day threshold (actionable — we can re-certify)
      // Received certs: 30-day threshold (informational only)
      final threshold = direction == CertDirection.sent ? 60 : 30;
      if (cert.expireDate!.difference(now).inDays <= threshold) {
        // Only keep the soonest-expiring cert
        if (worstCert == null || cert.expireDate!.isBefore(worstCert.expireDate!)) {
          worstCert = cert;
          isExpiringSoon = true;
        }
      }
    }

    if (worstCert == null) return null;

    final contactName = worstCert.name.isNotEmpty ? worstCert.name : getShortPubkey(worstCert.address);
    final daysLeft = worstCert.expireDate!.difference(now).inDays;

    if (direction == CertDirection.sent) {
      // Sent cert: WE certified this person → we can re-certify
      if (isExpired) {
        return HomeAlertState(
          priority: HomeAlertPriority.sentCertExpired,
          message: '🔄 ${'homeAlertSentCertExpired'.tr(args: [contactName])}',
          walletAddress: walletAddress,
          targetAddress: worstCert.address,
          targetName: worstCert.name.isNotEmpty ? worstCert.name : null,
          action: HomeAlertAction.openProfile,
        );
      }
      if (isExpiringSoon) {
        return HomeAlertState(
          priority: HomeAlertPriority.sentCertExpiringSoon,
          message: '🔄 ${'homeAlertSentCertExpiringSoon'.tr(args: [contactName, '$daysLeft'])}',
          walletAddress: walletAddress,
          targetAddress: worstCert.address,
          targetName: worstCert.name.isNotEmpty ? worstCert.name : null,
          action: HomeAlertAction.openProfile,
        );
      }
    } else {
      // Received cert: someone certified US → informational
      if (isExpired) {
        return HomeAlertState(
          priority: HomeAlertPriority.receivedCertExpired,
          message: '📋 ${'homeAlertReceivedCertExpired'.tr(args: [contactName])}',
          walletAddress: walletAddress,
          targetAddress: worstCert.address,
          targetName: worstCert.name.isNotEmpty ? worstCert.name : null,
          action: HomeAlertAction.openCertList,
        );
      }
      if (isExpiringSoon) {
        return HomeAlertState(
          priority: HomeAlertPriority.receivedCertExpiringSoon,
          message: '📋 ${'homeAlertReceivedCertExpiringSoon'.tr(args: [contactName, '$daysLeft'])}',
          walletAddress: walletAddress,
          targetAddress: worstCert.address,
          targetName: worstCert.name.isNotEmpty ? worstCert.name : null,
          action: HomeAlertAction.openCertList,
        );
      }
    }

    return null;
  }

  /// Returns true when membership is in the last half of the renewal window.
  bool _shouldShowMembershipAlert(RenewalInfo info) {
    if (info.isExpired && info.canRenew) return true;
    if (info.expireDate == null) return false;

    if (info.canRenew && info.renewalStartDate != null) {
      final renewalWindow = info.expireDate!.difference(info.renewalStartDate!);
      final threshold = renewalWindow ~/ 2;
      final timeLeft = info.expireDate!.difference(DateTime.now());
      return timeLeft <= threshold;
    }

    final daysLeft = info.expireDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 30;
  }
}

/// Provides the highest-priority home alert across all owned wallets.
final homeAlertProvider = NotifierProvider<HomeAlertNotifier, HomeAlertState>(HomeAlertNotifier.new);
