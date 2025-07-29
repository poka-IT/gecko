import 'package:durt2/durt2.dart' as d show WalletEntity, ConnectionStatus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/wallet_name.dart';
import 'package:truncate/truncate.dart';

class NameByAddress extends ConsumerWidget {
  const NameByAddress({
    super.key,
    required this.wallet,
    this.size = 20,
    this.color,
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
  });

  final d.WalletEntity wallet;
  final Color? color;
  final double size;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalColor = color ?? Theme.of(context).colorScheme.onSurface;

    // Check if we have network connection
    final connectionStatus = ref.watch(connectionStatusProvider);

    final isNetworkAvailable = connectionStatus == d.ConnectionStatus.connected;

    if (!isNetworkAvailable) {
      return WalletName(wallet: wallet, size: size, color: finalColor);
    }

    final identityNameAsync = ref.watch(identityNameProvider(wallet.address));

    return identityNameAsync.when(
      data: (name) {
        // Store in G1 wallets list for compatibility
        if (name != null) {
          g1WalletsBox.put(wallet.address, G1WalletsList(address: wallet.address, username: name));
        }

        // If no identity name found, show wallet name
        if (name == null) {
          if (wallet.name == null) {
            return SizedBox.shrink();
          }
          return WalletName(wallet: wallet, size: size, color: finalColor);
        }

        // Show identity name
        return Text(
          truncate(name, 22),
          style: scaledTextStyle(fontSize: size, color: finalColor, fontWeight: fontWeight, fontStyle: fontStyle),
        );
      },
      loading: () => const Loading(),
      error: (error, stackTrace) {
        // On error, fall back to wallet name
        return WalletName(wallet: wallet, size: size, color: finalColor);
      },
    );
  }
}
