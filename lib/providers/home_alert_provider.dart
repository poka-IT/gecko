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
  /// Identity has expired — membership impossible until re-created.
  identityExpired(100),

  /// Membership has expired — can be renewed.
  membershipExpired(90),

  /// A membership renewal is pending evaluation.
  membershipPendingEval(80),

  /// Membership expires soon (in the last half of the renewal window).
  membershipExpiringSoon(70),

  /// One or more received certifications have expired.
  certExpired(60),

  /// One or more received certifications expire within 30 days.
  certExpiringSoon(50),

  /// Everything is healthy — show default message.
  none(0);

  const HomeAlertPriority(this.value);
  final int value;
}

/// Immutable snapshot of the highest-priority home alert.
class HomeAlertState {
  /// The priority level of the alert.
  final HomeAlertPriority priority;

  /// The formatted, user-facing message (with emoji prefix).
  final String message;

  /// Address of the wallet that triggered the alert (for navigation).
  final String? walletAddress;

  const HomeAlertState({this.priority = HomeAlertPriority.none, this.message = '', this.walletAddress});

  bool get hasAlert => priority != HomeAlertPriority.none;
}

/// Aggregates alerts from all owned wallets and returns the single
/// highest-priority alert.
///
/// Watches only lightweight, already-loaded sources:
/// - [walletsListProvider] (cached in ObjectBox)
/// - [membershipStatusProvider] per wallet (throttled, ≤1 fetch/10 blocks)
/// - [smartIdtyStatusStreamProvider] per wallet (persistent stream)
/// - [certAlertStatusProvider] per wallet (derived from cert list)
///
/// Does NOT trigger new network fetches — all dependencies are either
/// already subscribed or throttled by their own providers.
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
      // Short-circuit: identity expired is max priority
      if (best.priority == HomeAlertPriority.identityExpired) break;
    }

    return best;
  }

  /// Checks all alert conditions for a single wallet and returns the
  /// highest-priority alert found.
  HomeAlertState _checkWallet(String address) {
    // 1. Check identity status (real-time stream, no extra cost)
    final idtyStatusAsync = ref.watch(smartIdtyStatusStreamProvider(address));
    final idtyStatus = idtyStatusAsync.asData?.value;

    if (idtyStatus == d.IdtyStatus.expired) {
      return HomeAlertState(
        priority: HomeAlertPriority.identityExpired,
        message: '⛔ ${'homeAlertIdentityExpired'.tr()}',
        walletAddress: address,
      );
    }

    // 2. Check membership status (throttled, safe to watch)
    final membershipAsync = ref.watch(membershipStatusProvider(address));
    final membership = membershipAsync.asData?.value;

    if (membership != null && idtyStatus != null && idtyStatus != d.IdtyStatus.none) {
      final info = MembershipRenewal.calculateRenewalInfo(membership);

      // 2a. Membership expired
      if (info.isExpired && idtyStatus == d.IdtyStatus.expired) {
        final autoRevocText = info.autoRevocationDate != null
            ? ' (${'homeAlertAutoRevocation'.tr(args: [DateFormat('dd/MM').format(info.autoRevocationDate!)])})'
            : '';
        return HomeAlertState(
          priority: HomeAlertPriority.membershipExpired,
          message: '🔴 ${'homeAlertMembershipExpired'.tr()}$autoRevocText',
          walletAddress: address,
        );
      }

      // 2b. Pending evaluation
      if (info.hasPendingRenewal) {
        return HomeAlertState(
          priority: HomeAlertPriority.membershipPendingEval,
          message: '⏳ ${'homeAlertMembershipPendingEval'.tr()}',
          walletAddress: address,
        );
      }

      // 2c. Membership expiring soon (last half of renewal window)
      if (_shouldShowMembershipAlert(info)) {
        final daysLeft = info.expireDate != null ? info.expireDate!.difference(DateTime.now()).inDays : 0;
        return HomeAlertState(
          priority: HomeAlertPriority.membershipExpiringSoon,
          message: '⚠️ ${'homeAlertMembershipExpiringSoon'.tr(args: ['$daysLeft'])}',
          walletAddress: address,
        );
      }
    }

    // 3. Check received cert alerts (derived from already-loaded cert list)
    final certStatus = ref.watch(certAlertStatusProvider((address: address, direction: CertDirection.received)));

    if (certStatus == CertAlertStatus.expired) {
      return HomeAlertState(
        priority: HomeAlertPriority.certExpired,
        message: '📋 ${'homeAlertCertExpired'.tr()}',
        walletAddress: address,
      );
    }

    if (certStatus == CertAlertStatus.expiringSoon) {
      return HomeAlertState(
        priority: HomeAlertPriority.certExpiringSoon,
        message: '📋 ${'homeAlertCertExpiringSoon'.tr()}',
        walletAddress: address,
      );
    }

    return const HomeAlertState();
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

    // Fallback: ≤30 days
    final daysLeft = info.expireDate!.difference(DateTime.now()).inDays;
    return daysLeft <= 30;
  }
}

/// Provides the highest-priority home alert across all owned wallets.
final homeAlertProvider = NotifierProvider<HomeAlertNotifier, HomeAlertState>(HomeAlertNotifier.new);
