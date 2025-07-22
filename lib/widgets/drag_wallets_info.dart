import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';

class DragWalletsInfo extends ConsumerWidget {
  const DragWalletsInfo({super.key, required this.dragAddress, required this.lastFlyBy});

  final WalletEntity dragAddress;
  final WalletEntity lastFlyBy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSameAddress = dragAddress == lastFlyBy;

    final screenWidth = MediaQuery.of(homeContext).size.width;

    final fromName = ref.read(squidServiceProvider).walletNameIndexer[dragAddress.address] ?? dragAddress.name;

    final toName = ref.read(squidServiceProvider).walletNameIndexer[lastFlyBy.address] ?? lastFlyBy.name;
    final mdStyle = MarkdownStyleSheet(
      p: scaledTextStyle(fontSize: 15, color: Colors.black, letterSpacing: 0.3),
      textAlign: WrapAlignment.spaceBetween,
    );

    return Container(
      color: context.colorScheme.secondary,
      width: screenWidth,
      height: scaleSize(85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MarkdownBody(data: '${'executeATransfer'.tr()}:', styleSheet: mdStyle),
            MarkdownBody(
              data: '${'from'.tr(args: [''])} **$fromName**',
              styleSheet: mdStyle,
            ),
            if (isSameAddress) MarkdownBody(data: 'chooseATargetWallet'.tr(), styleSheet: mdStyle),
            if (!isSameAddress)
              MarkdownBody(
                data: '${'to'.tr(args: [''])} **$toName**',
                styleSheet: mdStyle,
              ),
          ],
        ),
      ),
    );
  }
}
