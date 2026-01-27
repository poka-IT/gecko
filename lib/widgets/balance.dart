import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/widgets/balance_display.dart';
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
          if (safeBalance != null) {
            return BalanceDisplay(value: safeBalance.transferableBalance, size: size, color: finalColor);
          }
          // Safe data is still loading, show empty while waiting
          return const SizedBox.shrink();
        }

        // Fallback to stream provider for external wallets
        final balanceStream = ref.watch(smartBalanceStreamProvider(address));

        return balanceStream.when(
          data: (walletBalance) {
            final transferableBalance = walletBalance.transferableBalance;
            return BalanceDisplay(value: transferableBalance, size: size, color: finalColor);
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) {
            log.e('❌ Balance widget error for $address: $error');
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
