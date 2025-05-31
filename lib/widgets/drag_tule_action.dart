// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt, WalletData;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart';

class DragTuleAction extends StatelessWidget {
  const DragTuleAction({super.key, required this.wallet, required this.child});

  final WalletData wallet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    return LongPressDraggable<String>(
      delay: const Duration(milliseconds: 200),
      data: wallet.address,
      dragAnchorStrategy: (Draggable<Object> _, BuildContext __, Offset ___) =>
          const Offset(55, 55),
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
            final walletData =
                myWalletProvider.getWalletDataByAddress(senderAddress.data);
            await Durt.i.walletService.setDefaultWallet(walletData!.address);
            sub.reload();
            paymentPopup(context, wallet.address,
                g1WalletsBox.get(wallet.address)!.username ?? wallet.name!);
          },
          onMove: (details) {
            if (wallet.address != myWalletProvider.lastFlyBy?.address) {
              myWalletProvider.lastFlyBy = wallet;
              myWalletProvider.reload();
            }
          },
          onWillAcceptWithDetails: (senderAddress) =>
              senderAddress.data != wallet.address,
          builder: (
            BuildContext context,
            List<dynamic> accepted,
            List<dynamic> rejected,
          ) {
            return IntrinsicHeight(
              child: child,
            );
          }),
    );
  }
}
