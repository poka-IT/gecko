import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/extensions.dart';

class CompactWalletHeader extends ConsumerWidget {
  const CompactWalletHeader({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(address));

    // Determine if wallet is empty (same logic as wallet_header.dart)
    final balance = balanceAsync.hasValue ? balanceAsync.value?.transferableBalance : null;
    final isEmptyWallet = balance == null || balance == BigInt.zero;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary),
      child: Row(
        children: [
          // Compact avatar
          DatapodAvatar(address: address, size: 32),
          const SizedBox(width: 12),
          // Essential information (left side)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Truncated address
                Flexible(
                  child: Text(
                    getShortPubkey(address),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Compact balance
                Flexible(child: Balance(address: address, size: 15)),
              ],
            ),
          ),
          // Identity and status (centered in remaining space)
          Expanded(
            flex: 2,
            child: Consumer(
              builder: (context, ref, child) {
                final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(address));
                final identityNameAsync = ref.watch(identityNameStreamProvider(address));

                if (idtyStatusAsync.hasValue && identityNameAsync.hasValue) {
                  final idtyStatus = idtyStatusAsync.value!;
                  final identityName = identityNameAsync.value;

                  if (idtyStatus != IdtyStatus.none &&
                      idtyStatus != IdtyStatus.unknown &&
                      identityName != null &&
                      identityName.isNotEmpty) {
                    return Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Identity name - larger and more prominent
                          Text(
                            identityName.length > 10 ? '${identityName.substring(0, 10)}...' : identityName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          // Status badge - more prominent
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: IdentityStatusHelper.getStatusColor(idtyStatus).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              IdentityStatusHelper.getStatusText(idtyStatus),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: IdentityStatusHelper.getStatusColor(idtyStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for identity status utilities
class IdentityStatusHelper {
  static Color getStatusColor(IdtyStatus idtyStatus) {
    switch (idtyStatus) {
      case IdtyStatus.validated:
        return Colors.green;
      case IdtyStatus.confirmed:
        return Colors.orange;
      case IdtyStatus.created:
        return Colors.blue;
      case IdtyStatus.expired:
        return Colors.red;
      case IdtyStatus.revoked:
        return Colors.grey;
      case IdtyStatus.none:
      case IdtyStatus.unknown:
        return Colors.grey;
    }
  }

  static String getStatusText(IdtyStatus idtyStatus) {
    switch (idtyStatus) {
      case IdtyStatus.validated:
        return 'identityStatusValidated'.tr();
      case IdtyStatus.confirmed:
        return 'identityStatusConfirmed'.tr();
      case IdtyStatus.created:
        return 'identityStatusCreated'.tr();
      case IdtyStatus.expired:
        return 'identityStatusExpired'.tr();
      case IdtyStatus.revoked:
        return 'identityStatusRevoked'.tr();
      case IdtyStatus.none:
      case IdtyStatus.unknown:
        return 'identityStatusUnknown'.tr();
    }
  }
}
