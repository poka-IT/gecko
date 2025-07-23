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
        ScaledSizedBox(
          height: 60,
          width: 300,
          child: ElevatedButton.icon(
            icon: Image.asset('assets/safes/config.png', height: scaleSize(40)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: context.colorScheme.surfaceTint,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: context.colorScheme.surfaceTint.withValues(alpha: 0.3),
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
              "   ${"manageSafe".tr()}",
              style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xff8a3c0f)),
            ),
          ),
        ),
        ScaledSizedBox(height: 20),
        InkWell(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'CS', height: scaleSize(40)),
              ScaledSizedBox(
                width: 155,
                height: 60,
                child: Center(
                  child: Text(
                    'importIdPasswordAccount'.tr(),
                    style: scaledTextStyle(fontSize: 16, color: Colors.blue[900], fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        ScaledSizedBox(height: 50),
      ],
    );
  }
}
