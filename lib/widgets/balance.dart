import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:provider/provider.dart' as old_provider;

class Balance extends ConsumerWidget {
  const Balance({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We keep the old provider for now, we can migrate it later.
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    final finalColor = color ?? Theme.of(context).colorScheme.onSecondaryContainer;
    return old_provider.Consumer<BlockHeightProvider>(
      builder: (context, _, _) {
        final storageService = ref.watch(storageServiceProvider);
        return FutureBuilder<WalletBalance>(
          future: storageService.getBalance(address),
          builder: (BuildContext context, AsyncSnapshot<WalletBalance> globalBalance) {
            if (globalBalance.connectionState != ConnectionState.done ||
                globalBalance.hasError ||
                !globalBalance.hasData) {
              if (walletOptions.balanceCache[address] != null &&
                  walletOptions.balanceCache[address] != BigInt.from(-1)) {
                return BalanceDisplay(value: walletOptions.balanceCache[address]!, size: size, color: finalColor);
              } else {
                return const SizedBox.shrink();
              }
            }
            walletOptions.balanceCache[address] = globalBalance.data!.transferableBalance;
            if (walletOptions.balanceCache[address] != BigInt.from(-1)) {
              return BalanceDisplay(value: walletOptions.balanceCache[address]!, size: size, color: finalColor);
            } else {
              return const Text('');
            }
          },
        );
      },
    );
  }
}
