import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
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

        // Use the smart balance provider that automatically chooses between persistent and auto-dispose
        final balanceStream = ref.watch(smartBalanceStreamProvider(address));

        return balanceStream.when(
          data: (walletBalance) {
            // Extract the transferable balance from WalletBalance
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
