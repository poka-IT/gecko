import 'package:accordion/controllers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/certs_received.dart';
import 'package:gecko/widgets/certs_counter.dart';
import 'package:gecko/widgets/certs_sent.dart';
import 'package:accordion/accordion.dart';

class CertificationsScreen extends ConsumerWidget {
  const CertificationsScreen(
      {Key? key, required this.address, required this.username})
      : super(key: key);
  final String address;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            elevation: 0,
            toolbarHeight: 60 * ratio,
            title: SizedBox(
              height: 22,
              child: Text('Certifications de $username'),
            )),
        body: SafeArea(
          child: Accordion(
              paddingListTop: 10,
              paddingListBottom: 10,
              maxOpenSections: 1,
              headerBackgroundColorOpened: orangeC,
              scaleWhenAnimating: true,
              openAndCloseAnimation: true,
              headerPadding:
                  const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
              sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
              sectionClosingHapticFeedback: SectionHapticFeedback.light,
              children: [
                AccordionSection(
                  isOpen: true,
                  leftIcon:
                      const Icon(Icons.insights_rounded, color: Colors.black),
                  headerBackgroundColor: yellowC,
                  headerBackgroundColorOpened: orangeC,
                  header: Row(children: [
                    Text('received'.tr()),
                    const SizedBox(width: 5),
                    CertsCounter(address: address)
                  ]),
                  content: CertsReceived(address: address),
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
                    Text('sent'.tr()),
                    const SizedBox(width: 5),
                    CertsCounter(address: address, isSent: true)
                  ]),
                  content: CertsSent(address: address),
                  contentHorizontalPadding: 20,
                  contentBorderWidth: 1,
                  // onOpenSection: () => print('onOpenSection ...'),
                  // onCloseSection: () => print('onCloseSection ...'),
                ),
              ]),
        ));
  }
}
