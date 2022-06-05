import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:qr_flutter/qr_flutter.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class QrCodeFullscreen extends StatelessWidget {
  TextEditingController tplController = TextEditingController();

  QrCodeFullscreen(this.address, {this.color, Key? key}) : super(key: key);
  final String address;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: color ?? Colors.black,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: orangeC),
              onPressed: () {
                Navigator.pop(context);
              }),
          title: SizedBox(
            height: 22,
            child: Text(
              'QR Code de ${getShortPubkey(address)}',
              style: TextStyle(color: orangeC),
            ),
          )),
      body: SafeArea(
        child: SizedBox.expand(
          child: Container(
              color: color ?? backgroundColor,
              child: Column(
                children: [
                  const Spacer(),
                  QrImageWidget(
                    data: address,
                    version: QrVersions.auto,
                    size: 350,
                  ),
                  const Spacer(flex: 2),
                ],
              )),
        ),
      ),
    );
  }
}
