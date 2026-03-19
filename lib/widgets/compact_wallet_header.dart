import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/providers/gecko_colors.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/utils/identity_utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';

class CompactWalletHeader extends ConsumerWidget {
  const CompactWalletHeader({super.key, required this.address, this.showBackButton = false});

  final String address;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(smartBalanceStreamProvider(address));

    // Determine background color based on wallet state
    // Use tertiary (normal) color during loading to avoid flash
    final Color backgroundColor;
    if (balanceAsync.isLoading && !balanceAsync.hasValue) {
      // Still loading, use neutral color
      backgroundColor = context.colorScheme.tertiary;
    } else {
      final balance = balanceAsync.value?.transferableBalance;
      final isEmptyWallet = balance == null || balance == BigInt.zero;
      backgroundColor = isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary;
    }

    return Hero(
      tag: 'wallet_header_$address', // Unique tag for this wallet
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, kToolbarHeight, 12, 8),
          decoration: BoxDecoration(color: backgroundColor),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button stays left-aligned, outside the centered content
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 24,
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showBackButton) DatapodAvatar(address: address, size: 32),
                        if (!showBackButton) const SizedBox(width: 12),
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
                                  SnackbarService.showAddressCopied(context);
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
                              final identityNameAsync = ref.watch(hybridIdentityNameProvider(address));

                              if (idtyStatusAsync.hasValue && identityNameAsync.hasValue) {
                                final idtyStatus = idtyStatusAsync.value!;
                                final identityName = identityNameAsync.value;

                                if (idtyStatus != IdtyStatus.none &&
                                    idtyStatus != IdtyStatus.unknown &&
                                    identityName != null &&
                                    identityName.isNotEmpty) {
                                  final isCreated = IdentityUtils.isCreatedStatus(idtyStatus);
                                  final displayName =
                                      IdentityUtils.getDisplayName(identityName, idtyStatus) ?? identityName;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Identity name - larger and more prominent with proper truncation
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isCreated ? FontWeight.w500 : FontWeight.w600,
                                          fontStyle: isCreated ? FontStyle.italic : FontStyle.normal,
                                          color: isCreated
                                              ? Theme.of(context).colorScheme.onSurfaceVariant
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      // Status badge - more prominent
                                      Semantics(
                                        label: 'Identity status: ${IdentityStatusHelper.getStatusText(idtyStatus)}',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: IdentityStatusHelper.getStatusColor(
                                              idtyStatus,
                                              context.geckoColors,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            IdentityStatusHelper.getStatusText(idtyStatus),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: IdentityStatusHelper.getStatusColor(
                                                idtyStatus,
                                                context.geckoColors,
                                              ),
                                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for identity status utilities
class IdentityStatusHelper {
  static Color getStatusColor(IdtyStatus idtyStatus, GeckoColors colors) {
    switch (idtyStatus) {
      case IdtyStatus.validated:
        return colors.statusMember;
      case IdtyStatus.confirmed:
        return colors.statusConfirmed;
      case IdtyStatus.created:
        return colors.statusCreated;
      case IdtyStatus.expired:
        return colors.statusExpired;
      case IdtyStatus.revoked:
        return colors.statusRevoked;
      case IdtyStatus.none:
      case IdtyStatus.unknown:
        return colors.statusNone;
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
