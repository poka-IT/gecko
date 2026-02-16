import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
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

/// Formats a future date as a human-readable remaining time string.
/// Returns null if the date is in the past (unless [readyLabel] is provided).
String? formatRemainingTime(DateTime date, {String? readyLabel}) {
  final now = DateTime.now();
  final difference = date.difference(now);

  if (difference.isNegative) {
    return readyLabel;
  } else if (difference.inDays > 30) {
    return DateFormat.MMMd().format(date);
  } else if (difference.inDays > 0) {
    return 'days'.tr(args: [difference.inDays.toString()]);
  } else if (difference.inHours > 0) {
    return 'hours'.tr(args: [difference.inHours.toString(), '']);
  } else if (difference.inMinutes > 0) {
    return 'minutes'.tr(args: [difference.inMinutes.toString()]);
  } else {
    return null;
  }
}

/// Formats a timestamp into a human-readable date delimiter.
/// Returns "today", "yesterday", "X days ago", or a verbose date like "Mardi 23 Mars".
String calculateDateDelimiter(DateTime timestamp) {
  final now = DateTime.now();
  final nowDate = DateTime(now.year, now.month, now.day);
  final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final daysDifference = nowDate.difference(timestampDate).inDays;

  if (daysDifference == 0) {
    return "today".tr();
  } else if (daysDifference == 1) {
    return "yesterday".tr();
  } else if (daysDifference < 7) {
    return "daysAgo".tr(args: [daysDifference.toString()]);
  } else {
    final locale = Localizations.localeOf(homeContext).languageCode;
    final formatPattern = timestamp.year == now.year ? 'EEEE d MMMM' : 'EEEE d MMMM y';
    final formatted = DateFormat(formatPattern, locale).format(timestamp);
    return formatted
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }
}
