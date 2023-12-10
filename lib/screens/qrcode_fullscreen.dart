// ignore_for_file: must_be_immutable

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

class QrCodeFullscreen extends StatefulWidget {
  const QrCodeFullscreen(this.address, {this.color, Key? key})
      : super(key: key);

  final String address;
  final Color? color;

  @override
  State<QrCodeFullscreen> createState() => _QrCodeFullscreenState();
}

class _QrCodeFullscreenState extends State<QrCodeFullscreen> {
  final tplController = TextEditingController();

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      log.e(e.toString());
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      log.e(e.toString());
      throw 'Failed to reset brightness';
    }
  }

  @override
  void initState() {
    super.initState();
    setBrightness(1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) {
        resetBrightness();
      },
      child: Scaffold(
        appBar: AppBar(
            elevation: 0,
            backgroundColor: widget.color ?? Colors.black,
            toolbarHeight: scaleSize(57),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: orangeC),
                onPressed: () {
                  Navigator.pop(context);
                }),
            title: Text(
              'QR Code de ${getShortPubkey(widget.address)}',
              style: scaledTextStyle(color: orangeC, fontSize: 20),
            )),
        body: SafeArea(
          child: SizedBox.expand(
            child: Container(
                color: widget.color ?? backgroundColor,
                child: Column(
                  children: [
                    const Spacer(),
                    QrImageWidget(
                      data: widget.address,
                      version: QrVersions.auto,
                      size: scaleSize(320),
                    ),
                    const Spacer(flex: 2),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
