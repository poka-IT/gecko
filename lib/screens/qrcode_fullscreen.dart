import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
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
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final currentBrightness = await ScreenBrightness().application;
      if (currentBrightness < 0.8) {
        await ScreenBrightness().setApplicationScreenBrightness(0.8);
        _brightnessWasChanged = true;
      }
    } catch (e) {
      log.w('Failed to set brightness: $e');
    }
  }

  Future<void> resetBrightness() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      if (_brightnessWasChanged) {
        await ScreenBrightness().resetApplicationScreenBrightness();
      }
    } catch (e) {
      log.w('Failed to reset brightness: $e');
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
              child: ResponsiveCenter(
                maxWidth: 500,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    QrImageView(
                      data: widget.address,
                      version: QrVersions.auto,
                      size: scaleSize(280),
                      dataModuleStyle: QrDataModuleStyle(color: context.colorScheme.onSecondaryContainer),
                      eyeStyle: QrEyeStyle(color: context.colorScheme.onSecondaryContainer),
                    ),
                    ScaledSizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(24)),
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.address));
                          SnackbarService.showAddressCopied(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: scaleSize(14), vertical: scaleSize(10)),
                          decoration: BoxDecoration(
                            color: context.colorScheme.onSecondaryContainer.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(scaleSize(12)),
                            border: Border.all(color: context.colorScheme.onSecondaryContainer.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.address,
                                  style: scaledTextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                    color: context.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ScaledSizedBox(width: 8),
                              Icon(
                                Icons.copy_rounded,
                                size: scaleSize(18),
                                color: context.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
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
      ),
    );
  }
}
