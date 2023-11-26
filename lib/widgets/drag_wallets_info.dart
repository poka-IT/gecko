import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:provider/provider.dart';

class DragWalletsInfo extends StatelessWidget {
  const DragWalletsInfo(
      {Key? key, required this.dragAddress, required this.lastFlyBy})
      : super(key: key);

  final WalletData dragAddress;
  final WalletData lastFlyBy;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final bool isSameAddress = dragAddress == lastFlyBy;

    final screenWidth = MediaQuery.of(homeContext).size.width;

    final fromName = duniterIndexer.walletNameIndexer[dragAddress.address] ??
        dragAddress.name;

    final toName =
        duniterIndexer.walletNameIndexer[lastFlyBy.address] ?? lastFlyBy.name;

    return Container(
      color: yellowC,
      width: screenWidth,
      height: 80,
      child: Center(
          child: Column(
        children: [
          const SizedBox(height: 2),
          Text('${'executeATransfer'.tr()}:'),
          MarkdownBody(data: '${'from'.tr()} **$fromName**'),
          if (isSameAddress) Text('chooseATargetWallet'.tr()),
          if (!isSameAddress) MarkdownBody(data: 'Vers: **$toName**'),
        ],
      )),
    );
  }
}
