import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/nfc_providers.dart';
import 'package:gecko/services/nfc_service.dart';
import 'package:gecko/services/payment_uri_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

class QrCodeFullscreen extends ConsumerStatefulWidget {
  const QrCodeFullscreen(this.address, {this.color, super.key});

  final String address;
  final Color? color;

  @override
  ConsumerState<QrCodeFullscreen> createState() => _QrCodeFullscreenState();
}

class _QrCodeFullscreenState extends ConsumerState<QrCodeFullscreen> {
  bool _brightnessWasChanged = false;
  bool _isWritingNfc = false;

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

  Future<void> _writeToNfc() async {
    if (_isWritingNfc) return;
    setState(() => _isWritingNfc = true);

    try {
      final uri = PaymentUriService.encode(widget.address, withTimestamp: true);
      final success = await NfcService.writeTag(uri);

      if (!mounted) return;
      if (success) {
        SnackbarService.showSuccess(context, message: 'nfcWriteSuccess'.tr());
      } else {
        SnackbarService.showError(context, message: 'nfcWriteError'.tr());
      }
    } finally {
      if (mounted) setState(() => _isWritingNfc = false);
    }
  }

  Future<void> _toggleHceEmulation() async {
    final session = ref.read(nfcSessionProvider);
    final notifier = ref.read(nfcSessionProvider.notifier);

    if (session.state == NfcSessionState.emulating) {
      await notifier.stopEmulation();
    } else {
      final uri = PaymentUriService.encode(widget.address, withTimestamp: true);
      await notifier.startEmulation(uri);
    }
  }

  Widget _buildHceReceiveButton(BuildContext context) {
    final session = ref.watch(nfcSessionProvider);
    final isEmulating = session.state == NfcSessionState.emulating;

    return Padding(
      padding: EdgeInsets.only(bottom: scaleSize(16)),
      child: ScaledSizedBox(
        width: 240,
        height: 55,
        child: ElevatedButton.icon(
          key: keyNfcReceive,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEmulating ? context.geckoColors.success : context.colorScheme.secondary,
            foregroundColor: isEmulating ? Colors.white : context.colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _toggleHceEmulation,
          icon: isEmulating
              ? SizedBox(
                  width: scaleSize(20),
                  height: scaleSize(20),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(Icons.contactless_rounded, size: scaleSize(22)),
          label: Text(
            isEmulating ? 'nfcEmulating'.tr().replaceAll('\n', ' ') : 'nfcReceivePayment'.tr().replaceAll('\n', ' '),
            style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setBrightnessIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final nfcAvailable = ref.watch(nfcAvailabilityProvider);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        resetBrightness();
        // Stop HCE emulation when leaving the screen
        final session = ref.read(nfcSessionProvider);
        if (session.state == NfcSessionState.emulating) {
          ref.read(nfcSessionProvider.notifier).stopEmulation();
        }
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
                    // NFC buttons — only shown when NFC is available
                    nfcAvailable.when(
                      data: (available) => available
                          ? Column(
                              children: [
                                // HCE receive button (Android only — phone acts as NFC card)
                                if (!kIsWeb && Platform.isAndroid) _buildHceReceiveButton(context),
                                // Write to physical NFC tag
                                Padding(
                                  padding: EdgeInsets.only(bottom: scaleSize(16)),
                                  child: ScaledSizedBox(
                                    width: 240,
                                    height: 55,
                                    child: ElevatedButton.icon(
                                      key: keyNfcWrite,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.colorScheme.primary,
                                        foregroundColor: context.colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: _isWritingNfc ? null : _writeToNfc,
                                      icon: _isWritingNfc
                                          ? SizedBox(
                                              width: scaleSize(20),
                                              height: scaleSize(20),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: context.colorScheme.onPrimary,
                                              ),
                                            )
                                          : Icon(Icons.nfc_rounded, size: scaleSize(22)),
                                      label: Text(
                                        'nfcWrite'.tr(),
                                        style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
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
