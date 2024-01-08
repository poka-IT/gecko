import 'package:accordion/controllers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/certs_list.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:accordion/accordion.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen(
      {Key? key, required this.address, required this.username})
      : super(key: key);
  final String address;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('certificationsOf'.tr(args: [username])),
        body: SafeArea(
          child: Accordion(
              paddingListTop: 7,
              paddingListBottom: 10,
              maxOpenSections: 1,
              headerBackgroundColorOpened: orangeC,
              scaleWhenAnimating: true,
              openAndCloseAnimation: true,
              headerPadding: EdgeInsets.symmetric(
                  vertical: scaleSize(6), horizontal: scaleSize(14)),
              sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
              sectionClosingHapticFeedback: SectionHapticFeedback.light,
              children: [
                AccordionSection(
                  isOpen: true,
                  leftIcon: Icon(
                    Icons.insights_rounded,
                    color: Colors.black,
                    size: scaleSize(20),
                  ),
                  headerBackgroundColor: yellowC,
                  headerBackgroundColorOpened: orangeC,
                  header: Row(children: [
                    Text(
                      'received'.tr(),
                      style: scaledTextStyle(fontSize: 17),
                    ),
                    ScaledSizedBox(width: 5),
                    CertsCounter(address: address)
                  ]),
                  content: CertsList(
                      address: address, direction: CertDirection.received),
                  contentHorizontalPadding: 0,
                  contentBorderWidth: 1,
                ),
                AccordionSection(
                  isOpen: false,
                  leftIcon:
                      const Icon(Icons.insights_rounded, color: Colors.black),
                  headerBackgroundColor: yellowC,
                  headerBackgroundColorOpened: orangeC,
                  header: Row(children: [
                    Text(
                      'sent'.tr(),
                      style: scaledTextStyle(fontSize: 17),
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
