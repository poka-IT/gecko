import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/extensions.dart';

class CompactWalletHeader extends ConsumerWidget {
  const CompactWalletHeader({super.key, required this.address, this.showBackButton = false});

  final String address;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(address));

    // Determine if wallet is empty (same logic as wallet_header.dart)
    final balance = balanceAsync.hasValue ? balanceAsync.value?.transferableBalance : null;
    final isEmptyWallet = balance == null || balance == BigInt.zero;

    return Hero(
      tag: 'wallet_header_$address', // Unique tag for this wallet
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, kToolbarHeight, 12, 8),
          decoration: BoxDecoration(color: isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button or avatar
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 24,
                )
              else
                DatapodAvatar(address: address, size: 32),

              const SizedBox(width: 12),
              // Essential information (left side) - takes 2/3 of available space
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Truncated address with smart truncation
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: address));
                        snackCopyKey(context);
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return buildSmartAddressText(
                            address: address,
                            maxWidth: constraints.maxWidth,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    // Compact balance
                    Balance(address: address, size: 15),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Identity and status (right side) - max 1/3 of available space
              Expanded(
                flex: 1,
                child: Consumer(
                  builder: (context, ref, child) {
                    final idtyStatusAsync = ref.watch(hybridIdtyStatusProvider(address));
                    final identityNameAsync = ref.watch(identityNameProvider(address));

                    if (idtyStatusAsync.hasValue && identityNameAsync.hasValue) {
                      final idtyStatus = idtyStatusAsync.value!;
                      final identityName = identityNameAsync.value;

                      if (idtyStatus != IdtyStatus.none &&
                          idtyStatus != IdtyStatus.unknown &&
                          identityName != null &&
                          identityName.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Identity name - larger and more prominent with proper truncation
                            Text(
                              identityName,
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
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
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
