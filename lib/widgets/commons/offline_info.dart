import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class OfflineInfo extends StatelessWidget {
  const OfflineInfo({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(homeContext).size.width;
    return Consumer<SubstrateSdk>(builder: (context, sub, _) {
      return Visibility(
        visible: !sub.nodeConnected,
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
              )),
        ),
      );
    });
  }
}
