import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/myWallets/safe_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';

class SafeOptionsButtons extends StatelessWidget {
  const SafeOptionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaledSizedBox(height: 50),
        // Make the button adaptive with flexible sizing
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Image.asset('assets/safes/config.png', height: scaleSize(40)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: context.colorScheme.surfaceTint,
                elevation: 2,
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                shadowColor: context.colorScheme.surfaceTint.withValues(alpha: 0.3),
                minimumSize: Size(0, scaleSize(60)), // Minimum height but flexible width
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return SafeOptions();
                  },
                ),
              ),
              label: Text(
                "manageSafe".tr(),
                style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xff8a3c0f)),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible, // Allow text to wrap if needed
              ),
            ),
          ),
        ),
        ScaledSizedBox(height: 20),
        // Make the import button adaptive as well
        Padding(
          padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
          child: InkWell(
            key: keyImportG1v1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ImportG1v1();
                  },
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'CS', height: scaleSize(40)),
                  ScaledSizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'importIdPasswordAccount'.tr(),
                      style: scaledTextStyle(fontSize: 16, color: Colors.blue[900], fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible, // Allow text to wrap if needed
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ScaledSizedBox(height: 50),
      ],
    );
  }
}
