import 'dart:io';
import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/nfc_providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/services/nfc_service.dart';
import 'package:gecko/services/payment_uri_service.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';
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

  /// Whether the wallet at this address has an identity (created, confirmed, or member).
  bool get _hasIdentity {
    final idtyAsync = ref.watch(hybridIdtyStatusProvider(widget.address));
    final status = idtyAsync.hasValue ? idtyAsync.value : IdtyStatus.none;
    return status != IdtyStatus.none && status != IdtyStatus.unknown;
  }

  void _showNfcInfoDialog(BuildContext context) {
    final infoKey = _hasIdentity ? 'nfcTagInfoIdentity' : 'nfcTagInfoAnonymous';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.nfc_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 10),
            Expanded(
              child: Text('nfcTagInfoTitle'.tr(), style: scaledTextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: TextMarkDown(
            infoKey.tr(),
            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            textAlign: WrapAlignment.start,
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('close'.tr()))],
      ),
    );
  }

  Widget _buildNfcButtonRow({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scaleSize(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaledSizedBox(
            width: 220,
            height: 50,
            child: ElevatedButton.icon(
              key: key,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: scaleSize(18),
                      height: scaleSize(18),
                      child: CircularProgressIndicator(strokeWidth: 2, color: foregroundColor),
                    )
                  : Icon(icon, size: scaleSize(20)),
              label: Text(
                label,
                style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ScaledSizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showNfcInfoDialog(context),
            child: Padding(
              padding: EdgeInsets.all(scaleSize(4)),
              child: Icon(Icons.info_outline_rounded, size: scaleSize(20), color: context.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHceReceiveButton(BuildContext context) {
    final session = ref.watch(nfcSessionProvider);
    final isEmulating = session.state == NfcSessionState.emulating;

    return _buildNfcButtonRow(
      key: keyNfcReceive,
      icon: Icons.contactless_rounded,
      label: isEmulating ? 'nfcEmulating'.tr().replaceAll('\n', ' ') : 'nfcReceivePayment'.tr().replaceAll('\n', ' '),
      onPressed: _toggleHceEmulation,
      isLoading: isEmulating,
      backgroundColor: isEmulating ? context.geckoColors.success : context.colorScheme.secondary,
      foregroundColor: isEmulating ? Colors.white : context.colorScheme.onSecondary,
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
            onPressed: () => Navigator.pop(context),
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
                    // NFC buttons — only shown when NFC hardware is available and enabled
                    nfcAvailable.when(
                      data: (availability) => availability == NFCAvailability.available
                          ? Column(
                              children: [
                                if (!kIsWeb && Platform.isAndroid) _buildHceReceiveButton(context),
                                _buildNfcButtonRow(
                                  key: keyNfcWrite,
                                  icon: Icons.nfc_rounded,
                                  label: 'nfcWrite'.tr(),
                                  onPressed: _isWritingNfc ? null : _writeToNfc,
                                  isLoading: _isWritingNfc,
                                  backgroundColor: context.colorScheme.primary,
                                  foregroundColor: context.colorScheme.onPrimary,
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
                        onPressed: () => Navigator.pop(context),
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
