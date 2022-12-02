import 'package:accordion/controllers.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/certs_received.dart';
import 'package:gecko/widgets/certs_sent.dart';
import 'package:accordion/accordion.dart';

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
        appBar: AppBar(
            elevation: 0,
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Certifications'),
            )),
        body: SafeArea(
          child: Accordion(
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
                  header: const Text('Reçus'),
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
                  header: const Text('Envoyés'),
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
