import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/membership_renewal.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/membership_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
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

    if (info.shouldAlertExpiringSoon) {
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
  /// Build a HomeAlertState from the shared certAlertDetailProvider.
  HomeAlertState? _findExpiringCert(String walletAddress, CertDirection direction) {
    final detail = ref.watch(certAlertDetailProvider((address: walletAddress, direction: direction)));

    if (detail.status == CertAlertStatus.none) return null;

    final contactName = detail.contactName ?? '?';
    final daysLeft = detail.daysLeft ?? 0;

    if (direction == CertDirection.sent) {
      if (detail.status == CertAlertStatus.expired) {
        return HomeAlertState(
          priority: HomeAlertPriority.sentCertExpired,
          message: '🔄 ${'homeAlertSentCertExpired'.tr(args: [contactName])}',
          walletAddress: walletAddress,
          targetAddress: detail.contactAddress,
          targetName: detail.contactName,
          action: HomeAlertAction.openProfile,
        );
      }
      return HomeAlertState(
        priority: HomeAlertPriority.sentCertExpiringSoon,
        message: '🔄 ${'homeAlertSentCertExpiringSoon'.tr(args: [contactName, '$daysLeft'])}',
        walletAddress: walletAddress,
        targetAddress: detail.contactAddress,
        targetName: detail.contactName,
        action: HomeAlertAction.openProfile,
      );
    } else {
      if (detail.status == CertAlertStatus.expired) {
        return HomeAlertState(
          priority: HomeAlertPriority.receivedCertExpired,
          message: '📋 ${'homeAlertReceivedCertExpired'.tr(args: [contactName])}',
          walletAddress: walletAddress,
          targetAddress: detail.contactAddress,
          targetName: detail.contactName,
          action: HomeAlertAction.openCertList,
        );
      }
      return HomeAlertState(
        priority: HomeAlertPriority.receivedCertExpiringSoon,
        message: '📋 ${'homeAlertReceivedCertExpiringSoon'.tr(args: [contactName, '$daysLeft'])}',
        walletAddress: walletAddress,
        targetAddress: detail.contactAddress,
        targetName: detail.contactName,
        action: HomeAlertAction.openCertList,
      );
    }
  }
}

/// Provides the highest-priority home alert across all owned wallets.
final homeAlertProvider = NotifierProvider<HomeAlertNotifier, HomeAlertState>(HomeAlertNotifier.new);
