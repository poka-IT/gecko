import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/services/qr_scanner_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Shows a compact desktop modal for QR code scanning.
///
/// Returns a [QrScanResult] or null if dismissed.
Future<QrScanResult?> showDesktopQrScannerModal(BuildContext context) {
  return showGeneralDialog<QrScanResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _QrScannerModalContent();
    },
  );
}

class _QrScannerModalContent extends StatefulWidget {
  const _QrScannerModalContent();

  @override
  State<_QrScannerModalContent> createState() => _QrScannerModalContentState();
}

class _QrScannerModalContentState extends State<_QrScannerModalContent> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _scannerUnavailable = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, formats: [BarcodeFormat.qrCode]);
    } on MissingPluginException {
      _scannerUnavailable = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final rawValue = barcodes.first.rawValue!;
    if (rawValue.isEmpty) return;

    _hasScanned = true;
    _controller?.stop();
    Navigator.of(context).pop(QrScanResult.success(rawValue));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    const modalWidth = 420.0;
    const cameraSize = 320.0;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: modalWidth),
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.97),
                      colorScheme.surfaceContainer.withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 20)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: colorScheme.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'scanQRCode'.tr().replaceAll('\n', ' '),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Camera viewfinder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: cameraSize,
                          height: cameraSize,
                          child: Stack(
                            children: [
                              // Camera feed
                              if (_scannerUnavailable || _controller == null)
                                Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                                        const SizedBox(height: 12),
                                        Text(
                                          'cameraError'.tr(),
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                MobileScanner(
                                  controller: _controller!,
                                  onDetect: _onDetect,
                                  errorBuilder: (context, error) {
                                    return Container(
                                      color: Colors.black,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                                            const SizedBox(height: 12),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              child: Text(
                                                error.errorDetails?.message ?? 'cameraError'.tr(),
                                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              // Viewfinder overlay
                              CustomPaint(
                                size: const Size(cameraSize, cameraSize),
                                painter: _ViewfinderPainter(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hint text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'pointCameraAtQrCode'.tr(),
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
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

/// Draws corner brackets as a QR viewfinder overlay.
class _ViewfinderPainter extends CustomPainter {
  final Color color;

  _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const inset = 40.0;
    const cornerLen = 30.0;
    const radius = 8.0;

    final rect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLen)
        ..lineTo(rect.left, rect.top + radius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
        ..lineTo(rect.left + cornerLen, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
        ..lineTo(rect.right, rect.top + cornerLen),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLen)
        ..lineTo(rect.left, rect.bottom - radius)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + radius, rect.bottom)
        ..lineTo(rect.left + cornerLen, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - radius)
        ..lineTo(rect.right, rect.bottom - cornerLen),
      paint,
    );

    // Semi-transparent dark overlay outside the scan area
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    final scanRect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(scanRect)
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => oldDelegate.color != color;
}
