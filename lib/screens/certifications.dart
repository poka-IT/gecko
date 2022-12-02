import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/widgets/certs_received.dart';
import 'package:gecko/widgets/certs_sent.dart';
import 'package:gecko/widgets/header_profile.dart';

class CertificationsScreen extends StatelessWidget {
  const CertificationsScreen(
      {Key? key, required this.address, required this.username})
      : super(key: key);
  final String address;
  final String username;

  @override
  Widget build(BuildContext context) {
    // final _homeProvider = Provider.of<HomeProvider>(context);

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
          child: Column(children: <Widget>[
            HeaderProfile(address: address, username: username),
            CertsReceived(address: address),
            CertsSent(address: address),
            const SizedBox(height: 20),
          ]),
        ));
  }
}
