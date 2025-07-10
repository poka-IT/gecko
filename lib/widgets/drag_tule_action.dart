// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class DragTuleAction extends ConsumerWidget {
  const DragTuleAction({super.key, required this.wallet, required this.child});

  final WalletEntity wallet;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);
    return LongPressDraggable<String>(
      delay: const Duration(milliseconds: 200),
      data: wallet.address,
      dragAnchorStrategy: (Draggable<Object> _, BuildContext _, Offset _) => const Offset(55, 55),
      onDragStarted: () => myWalletProvider.dragAddress = wallet,
      onDragEnd: (_) {
        myWalletProvider.lastFlyBy = null;
        myWalletProvider.dragAddress = null;
        myWalletProvider.reload();
      },
      feedback: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          shape: const CircleBorder(),
          padding: EdgeInsets.all(scaleSize(14)),
        ),
        child: SizedBox(
          height: scaleSize(33),
          child: const Image(image: AssetImage('assets/vector_white.png')),
        ),
      ),
      child: DragTarget<String>(
        onAcceptWithDetails: (senderAddress) async {
          final walletData = myWalletProvider.getWalletDataByAddress(senderAddress.data);
          if (walletData != null) {
            await ref.read(walletServiceProvider).setDefaultAddress(walletData.address);
          }
          paymentPopup(
            ref: ref,
            toAddress: wallet.address,
            username: g1WalletsBox.get(wallet.address)?.username ?? wallet.name!,
          );
        },
        onMove: (details) {
          if (wallet.address != myWalletProvider.lastFlyBy?.address) {
            myWalletProvider.lastFlyBy = wallet;
            myWalletProvider.reload();
          }
        },
        onWillAcceptWithDetails: (senderAddress) => senderAddress.data != wallet.address,
        builder: (BuildContext context, List<dynamic> accepted, List<dynamic> rejected) {
          return IntrinsicHeight(child: child);
        },
      ),
    );
  }
}
