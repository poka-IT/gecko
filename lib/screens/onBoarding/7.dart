// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/intro_info.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepSeven extends StatelessWidget {
  const OnboardingStepSeven({super.key, this.scanDerivation = false, this.fromRestore = false});
  final bool scanDerivation;
  final bool fromRestore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('myPassword'.tr()),
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 500,
          padding: EdgeInsets.zero,
          child: InfoIntro(
            text: 'geckoWillGenerateAPassword'.tr(),
            assetName: 'coffre-fort-code-secret-dans-telephone.png',
            buttonText: '>',
            nextScreen: RouteNames.onboardingStepEight,
            routeArguments: OnboardingStepsSevenToNineArguments(
              scanDerivation: scanDerivation,
              fromRestore: fromRestore,
            ),
            pagePosition: 6,
            boxHeight: 320,
          ),
        ),
      ),
    );
  }
}
