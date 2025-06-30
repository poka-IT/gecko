import 'package:durt2/durt2.dart' show Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:provider/provider.dart';

class OfflineInfo extends StatelessWidget {
  const OfflineInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(homeContext).size.width;
    return Consumer<BlockHeightProvider>(
      builder: (context, _, _) {
        return Visibility(
          visible: !Durt.i.isConnected,
          child: Positioned(
            top: 0,
            child: Container(
              height: 30,
              width: screenWidth,
              color: Colors.grey[800],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'youAreOffline'.tr(),
                    style: TextStyle(color: Colors.grey[50]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
