import 'package:durt2/durt2.dart' hide Provider;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/balance_display.dart';
import 'package:provider/provider.dart';

class Balance extends StatelessWidget {
  const Balance({super.key, required this.address, required this.size, this.color});
  final String address;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final finalColor = color ?? context.colorScheme.onSecondaryContainer;
    return Consumer<BlockHeightProvider>(
      builder: (context, _, _) {
        return FutureBuilder(
          future: Durt.i.storage.getBalance(address),
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
