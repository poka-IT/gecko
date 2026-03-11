import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:gecko/widgets/commons/shimmer_placeholder.dart';
import 'package:gecko/widgets/commons/storage_builder.dart';

class Balance extends ConsumerWidget {
  const Balance({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BalanceStorageBuilder(
      builder: (context, ref) {
        final finalColor = color ?? Theme.of(context).colorScheme.onSecondaryContainer;

        // Try to get balance from centralized safe data first (for owned wallets)
        final isOwnedWallet = ref.watch(isWalletInCurrentSafeProvider(address));

        if (isOwnedWallet) {
          // Use centralized batch-loaded data for owned wallets
          final safeBalance = ref.watch(safeWalletBalanceProvider(address));

          return ShimmerToContent(
            isLoading: safeBalance == null,
            shimmerWidth: scaleSize(60),
            shimmerHeight: scaleSize(size * 1.2),
            shimmerColor: finalColor,
            child: safeBalance != null
                ? BalanceDisplay(value: safeBalance.total, size: size, color: finalColor)
                : const SizedBox.shrink(),
          );
        }

        // Fallback to stream provider for external wallets
        final balanceStream = ref.watch(smartBalanceStreamProvider(address));

        return balanceStream.when(
          data: (walletBalance) {
            return BalanceDisplay(value: walletBalance.total, size: size, color: finalColor);
          },
          loading: () => ShimmerPlaceholder(width: scaleSize(60), height: scaleSize(size * 1.2), baseColor: finalColor),
          error: (error, stack) {
            log.e('❌ Balance widget error for $address: $error');
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
