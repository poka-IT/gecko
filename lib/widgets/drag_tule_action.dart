// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart';

class DragTuleAction extends StatelessWidget {
  const DragTuleAction({Key? key, required this.wallet, required this.child})
      : super(key: key);

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
          const Offset(0, 0),
      // feedbackOffset: const Offset(-500, -500),
      // dragAnchorStrategy: childDragAnchorStrategy,
      onDragStarted: () => myWalletProvider.dragAddress = wallet,
      onDragEnd: (_) {
        myWalletProvider.lastFlyBy = null;
        myWalletProvider.dragAddress = null;
        myWalletProvider.reload();
      },
      feedback: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeC,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(15),
        ),
        child: const SizedBox(
          height: 35,
          child: Image(image: AssetImage('assets/vector_white.png')),
        ),
      ),
      child: DragTarget<String>(
          onAccept: (senderAddress) async {
            log.d(
                'INTERPAY: sender: $senderAddress --- receiver: ${wallet.address}');
            final walletData =
                myWalletProvider.getWalletDataByAddress(senderAddress);
            await sub.setCurrentWallet(walletData!);
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
          onWillAccept: (senderAddress) => senderAddress != wallet.address,
          builder: (
            BuildContext context,
            List<dynamic> accepted,
            List<dynamic> rejected,
          ) {
            return child;
          }),
    );
  }
}
