import 'package:accordion/controllers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:accordion/accordion.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen({super.key, required this.address, required this.username});
  final String address;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('certificationsOf'.tr(args: [username])),
        body: SafeArea(
          child: Accordion(
              paddingListTop: 7,
              paddingListBottom: 10,
              maxOpenSections: 1,
              headerBackgroundColorOpened: context.colorScheme.primary,
              scaleWhenAnimating: true,
              openAndCloseAnimation: true,
              headerPadding: EdgeInsets.symmetric(vertical: scaleSize(6), horizontal: scaleSize(14)),
              sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
              sectionClosingHapticFeedback: SectionHapticFeedback.light,
              children: [
                AccordionSection(
                  isOpen: true,
                  leftIcon: Icon(
                    Icons.insights_rounded,
                    color: context.colorScheme.onSecondaryContainer,
                    size: scaleSize(20),
                  ),
                  headerBackgroundColor: context.colorScheme.secondary,
                  headerBackgroundColorOpened: context.colorScheme.primary,
                  contentBackgroundColor: context.colorScheme.surfaceContainer,
                  header: Row(children: [
                    Text(
                      'received'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    ScaledSizedBox(width: 5),
                    CertsCounter(address: address)
                  ]),
                  content: CertsList(address: address, direction: CertDirection.received),
                  contentHorizontalPadding: 0,
                  contentBorderWidth: 1,
                ),
                AccordionSection(
                  isOpen: false,
                  leftIcon: Icon(
                    Icons.insights_rounded,
                    color: context.colorScheme.onSecondaryContainer,
                    size: scaleSize(20),
                  ),
                  headerBackgroundColor: context.colorScheme.secondary,
                  headerBackgroundColorOpened: context.colorScheme.primary,
                  contentBackgroundColor: context.colorScheme.surfaceContainer,
                  header: Row(children: [
                    Text(
                      'sent'.tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    ScaledSizedBox(width: 5),
                    CertsCounter(address: address, isSent: true)
                  ]),
                  content: CertsList(
                    address: address,
                    direction: CertDirection.sent,
                  ),
                  contentHorizontalPadding: 0,
                  contentBorderWidth: 1,
                  // onOpenSection: () => print('onOpenSection ...'),
                  // onCloseSection: () => print('onCloseSection ...'),
                ),
              ]),
        ));
  }
}
