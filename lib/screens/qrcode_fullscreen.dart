// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

class QrCodeFullscreen extends StatefulWidget {
  const QrCodeFullscreen(this.address, {this.color, super.key});

  final String address;
  final Color? color;

  @override
  State<QrCodeFullscreen> createState() => _QrCodeFullscreenState();
}

class _QrCodeFullscreenState extends State<QrCodeFullscreen> {
  final tplController = TextEditingController();

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(brightness);
    } catch (e) {
      log.e(e.toString());
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
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
      onPopInvokedWithResult: (_, __) {
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
              style: scaledTextStyle(color: orangeC, fontSize: 17),
            )),
        body: SafeArea(
          child: SizedBox.expand(
            child: Container(
                color: widget.color ?? backgroundColor,
                child: Column(
                  children: [
                    const Spacer(),
                    QrImageView(
                      data: widget.address,
                      version: QrVersions.auto,
                      size: scaleSize(320),
                    ),
                    const Spacer(),
                    ScaledSizedBox(
                      width: 240,
                      height: 55,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orangeC,
                          side: const BorderSide(color: orangeC, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'close'.tr(),
                          style: scaledTextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: orangeC,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
