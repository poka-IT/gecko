// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
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
  bool _brightnessWasChanged = false;

  Future<void> setBrightnessIfNeeded() async {
    try {
      final currentBrightness = await ScreenBrightness().application;
      // Only increase brightness to 80% if current brightness is below 80%
      if (currentBrightness < 0.8) {
        await ScreenBrightness().setApplicationScreenBrightness(0.8);
        _brightnessWasChanged = true;
      }
    } catch (e) {
      log.e(e.toString());
      throw 'Failed to set brightness';
    }
  }

  Future<void> resetBrightness() async {
    try {
      // Only reset brightness if we changed it
      if (_brightnessWasChanged) {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (e) {
      log.e(e.toString());
      throw 'Failed to reset brightness';
    }
  }

  @override
  void initState() {
    super.initState();
    setBrightnessIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        resetBrightness();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: widget.color ?? Colors.black,
          toolbarHeight: scaleSize(57),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colorScheme.primary),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'QR Code de ${getShortPubkey(widget.address)}',
            style: scaledTextStyle(color: context.colorScheme.primary, fontSize: 17),
          ),
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: Container(
              color: widget.color ?? context.colorScheme.surface,
              child: Column(
                children: [
                  const Spacer(),
                  QrImageView(
                    data: widget.address,
                    version: QrVersions.auto,
                    size: scaleSize(320),
                    dataModuleStyle: QrDataModuleStyle(color: context.colorScheme.onSecondaryContainer),
                    eyeStyle: QrEyeStyle(color: context.colorScheme.onSecondaryContainer),
                  ),
                  const Spacer(),
                  ScaledSizedBox(
                    width: 240,
                    height: 55,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colorScheme.primary,
                        side: BorderSide(color: context.colorScheme.primary, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'close'.tr(),
                        style: scaledTextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
