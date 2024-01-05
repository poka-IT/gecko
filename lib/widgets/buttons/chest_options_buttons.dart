import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:provider/provider.dart';

class ChestOptionsButtons extends StatelessWidget {
  const ChestOptionsButtons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    return Column(children: [
      ScaledSizedBox(height: 50),
      ScaledSizedBox(
          height: 60,
          width: 300,
          child: ElevatedButton.icon(
            icon: Image.asset(
              'assets/chests/config.png',
              height: scaleSize(40),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              elevation: 2,
              backgroundColor: floattingYellow,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ChestOptions(walletProvider: myWalletProvider);
              }),
            ),
            label: Text(
              "   ${"manageChest".tr()}",
              style: scaledTextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xff8a3c0f),
              ),
            ),
          )),
      ScaledSizedBox(height: 20),
      InkWell(
        key: keyImportG1v1,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const ImportG1v1();
            }),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/cesium_bw2.svg',
              semanticsLabel: 'CS',
              height: scaleSize(40),
            ),
            ScaledSizedBox(
              width: 275,
              height: 60,
              child: Center(
                  child: Text('importG1v1'.tr(),
                      style: scaledTextStyle(
                          fontSize: 17,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500))),
            ),
          ],
        ),
      ),
      ScaledSizedBox(height: 20),
      // InkWell(
      //   key: keyChangeChest,
      //   onTap: () {
      //     // Navigator.push(
      //     //   context,
      //     //   MaterialPageRoute(builder: (context) {
      //     //     return const ChooseChest();
      //     //   }),
      //     // );
      //   },
      //   child: ScaledSizedBox(
      //     width: 270,
      //     height: 60,
      //     child: Center(
      //         child: Text('changeChest'.tr(),
      //             style: const scaledTextStyle(
      //                 fontSize: 20,
      //                 color: Colors.grey, //orangeC
      //                 fontWeight: FontWeight.w500))),
      //   ),
      // ),
      ScaledSizedBox(height: 30)
    ]);
  }
}
