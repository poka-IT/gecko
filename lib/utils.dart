import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:truncate/truncate.dart';

String getShortPubkey(String pubkey) {
  String pubkeyShort =
      truncate(pubkey, 7, omission: String.fromCharCode(0x2026), position: TruncatePosition.end) +
      truncate(pubkey, 6, omission: "", position: TruncatePosition.start);
  return pubkeyShort;
}

/// Build smart address widget with truncation from the beginning when needed
/// This function measures text width and intelligently truncates to show the end of the address
Widget buildSmartAddressText({required String address, required double maxWidth, required TextStyle style}) {
  // Try with getShortPubkey first (normal case)
  final shortAddress = getShortPubkey(address);
  final shortTextPainter = TextPainter(
    text: TextSpan(text: shortAddress, style: style),
    textDirection: ui.TextDirection.ltr,
  );
  shortTextPainter.layout();

  // Add safety margin for spacing
  final safeMaxWidth = maxWidth - 16.0;

  if (shortTextPainter.width <= safeMaxWidth) {
    // Short address fits perfectly
    return Text(shortAddress, style: style, maxLines: 1, overflow: TextOverflow.clip);
  }

  // Need even more aggressive truncation - show only the end
  final ellipsisPainter = TextPainter(
    text: TextSpan(text: '…', style: style),
    textDirection: ui.TextDirection.ltr,
  );
  ellipsisPainter.layout();
  final ellipsisWidth = ellipsisPainter.width;

  final availableForText = safeMaxWidth - ellipsisWidth;

  // Find how many chars from the END we can keep from the full address
  String bestText = '…';
  for (int i = 8; i <= address.length; i++) {
    // Start with at least 8 chars from the end
    final testSuffix = address.substring(address.length - i);
    final testPainter = TextPainter(
      text: TextSpan(text: testSuffix, style: style),
      textDirection: ui.TextDirection.ltr,
    );
    testPainter.layout();

    if (testPainter.width <= availableForText) {
      bestText = '…$testSuffix';
    } else {
      break;
    }
  }

  return Text(bestText, style: style, maxLines: 1, overflow: TextOverflow.clip);
}
