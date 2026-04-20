import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/desktop/desktop_modal.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the QR code of an address in a desktop modal.
Future<void> showDesktopQrCodeModal(BuildContext context, {required String address, String? username}) {
  return showDesktopModal(
    context: context,
    size: DesktopModalSize.small,
    title: username ?? 'qrCode'.tr(),
    builder: (modalContext) => _QrCodeContent(address: address),
  );
}

class _QrCodeContent extends StatelessWidget {
  final String address;

  const _QrCodeContent({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: QrImageView(data: address, version: QrVersions.auto, size: 300, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Clipboard.setData(ClipboardData(text: address));
            SnackbarService.showAddressCopied(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SelectableText(
                    address,
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: context.colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
